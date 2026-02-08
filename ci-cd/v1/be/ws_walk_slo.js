import WebSocket from "ws";
import { Client } from "@stomp/stompjs";
import fs from "node:fs";
import path from "node:path";

/**
 * 목적 (SLO 검증)
 * - WebSocket(STOMP) 동시 연결 100개를 안정적으로 유지 가능한지 검증
 * - 3분(디폴트) 동안 연결을 유지하며 주기적 메시지 송수신이 정상 동작하는지 확인
 *
 * SLO 기준
 * - 동시 연결 수: 100
 * - 유지 시간: 3분
 * - 비정상 종료율 < 1%
 * - 메시지 송·수신 실패율 < 1%
 *
 * 시나리오 흐름 (사용자 1명 = 1 WebSocket 세션)
 * 1. 개발용 사용자 seed 생성
 * 2. 사용자별 JWT 발급
 * 3. 산책 시작 API 호출 → walkId 발급
 * 4. WebSocket 연결 + STOMP CONNECT (Authorization 포함)
 * 5. /topic/walks/{walkId} 구독
 * 6. 5초마다 위치 메시지 전송 (/app/walks/{walkId}/location)
 * 7. 3분 후 산책 종료 API 호출 → WebSocket 종료
 *
 * 결과
 * - 콘솔 요약 출력
 * - JSON 결과 파일 저장
 * - Prometheus Pushgateway로 메트릭 전송
 * - SLO 미충족 시 프로세스 종료 코드로 실패 처리
 */

// --------------------
// ENV
// --------------------
const BASE_URL = process.env.BASE_URL || "http://localhost:8080"; // HTTP API 기본 주소
const WS_URL = process.env.WS_URL || "ws://localhost:8080/ws/walks"; // WebSocket(STOMP) 엔드포인트

// 동시에 실행할 사용자 수 (동시 WebSocket 연결 수)
const CONCURRENCY = Number(process.env.CONCURRENCY || "100");

// 개발용 사용자 seed 관련 설정
const SEED_COUNT = Number(process.env.SEED_COUNT || String(CONCURRENCY));
const SEED_PREFIX = process.env.SEED_PREFIX || "loadtest";

// 시나리오
const SEND_EVERY_MS = Number(process.env.SEND_EVERY_MS || "5000"); // - 위치 전송 주기 (기본 5초)
const RUN_FOR_MS = Number(process.env.RUN_FOR_MS || "180000"); // - 전체 실행 시간 (기본 3분)

// 테스트 시작 위치 좌표
const START_LAT = Number(process.env.START_LAT || "37.3941");
const START_LNG = Number(process.env.START_LNG || "127.1113");

const OUT_DIR = process.env.OUT_DIR || ".";
const RUN_ID =
  process.env.RUN_ID || new Date().toISOString().replace(/[:.]/g, "-");

// Prometheus Pushgateway
const PUSHGATEWAY_URL = process.env.PUSHGATEWAY_URL || ""; // 예: http://localhost:9091
const PUSH_JOB = process.env.PUSH_JOB || "ws_walk_slo";
const PUSH_INSTANCE = process.env.PUSH_INSTANCE || "local";

// SLO
const SLO_ABNORMAL_CLOSE_LT = Number(
  process.env.SLO_ABNORMAL_CLOSE_LT || "0.01",
);
const SLO_MSG_FAIL_LT = Number(process.env.SLO_MSG_FAIL_LT || "0.01");
const SLO_CONNECTED_GTE = Number(process.env.SLO_CONNECTED_GTE || "0.99");

// 로그 출력 제어
// VERBOSE=1 이면 WebSocket 수신 메시지 및 STOMP 디버그 로그 출력
// LOG_TOP_N 만큼의 사용자만 로그를 출력하여 콘솔 폭주 방지
const VERBOSE = Number(process.env.VERBOSE || "0"); // 1이면 로깅
const LOG_TOP_N = Number(process.env.LOG_TOP_N || "3");

// --------------------
// Helpers
// --------------------
function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function httpJson(method, path, body, token) {
  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {}

  if (!res.ok) {
    throw new Error(`${method} ${path} failed: ${res.status}\n${text || ""}`);
  }
  return json;
}

// --------------------
// 단계별 함수
// --------------------
async function seedUsers() {
  const json = await httpJson("POST", "/api/v3/auth/dev/seed", {
    count: SEED_COUNT,
    prefix: SEED_PREFIX,
  });

  const userIds = json?.data?.userIds || [];
  if (!userIds.length) throw new Error("Seed returned no userIds");
  if (userIds.length !== SEED_COUNT) {
    throw new Error(`Seed returned ${userIds.length}, expected ${SEED_COUNT}`);
  }

  console.log("[seed]", { created: json.data.created, count: userIds.length });
  return userIds;
}

async function getDevToken(userId) {
  const json = await httpJson("POST", `/api/v3/auth/dev/token/${userId}`);
  const token = json?.data?.accessToken || null;

  if (!token) {
    throw new Error(`Token not found for userId=${userId}`);
  }
  return token;
}

async function startWalk(token) {
  const json = await httpJson(
    "POST",
    "/api/v3/walks",
    { startLat: START_LAT, startLng: START_LNG },
    token,
  );

  const walkId = json?.data?.walkId ?? json?.data?.id ?? null;
  if (!walkId) throw new Error("walkId not found in /api/v3/walks response");
  return walkId;
}

async function endWalk(token, walkId, durationSeconds) {
  const body = {
    endLat: START_LAT,
    endLng: START_LNG,
    totalDistanceKm: 5,
    durationSeconds,
    status: "FINISHED",
  };

  const res = await fetch(`${BASE_URL}/api/v3/walks/${walkId}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });

  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {}

  if (!res.ok) {
    throw new Error(`walk end failed: ${res.status} ${text || ""}`);
  }

  return json;
}

/**
 * 전체 실행에 대한 메트릭을 집계하기 위한 aggregator
 *
 * total: 전체 사용자 수 (동시 연결 수)
 *
 * wsConnectedOk / wsConnectedFail
 * - WebSocket + STOMP CONNECT 성공/실패 횟수
 *
 * wsClosed / wsClosedAbnormal
 * - WebSocket 종료 횟수
 * - 비정상 종료: 테스트가 의도한 종료 이전에 끊긴 경우
 *
 * sendOk / sendFail
 * - 위치 메시지 SEND 성공/실패 횟수
 *
 * recvOk / recvFail
 * - 서버 메시지 수신 성공/실패 횟수
 * - 앱 레벨 ERROR 메시지는 recvFail로 간주
 *
 * endWalkOk / endWalkFail
 * - 산책 종료 API 성공/실패
 *
 * connectLatencyMs
 * - STOMP CONNECT까지 걸린 시간(ms)
 */
function newAgg(total) {
  return {
    runId: RUN_ID,
    total,

    // outcomes
    wsConnectedOk: 0,
    wsConnectedFail: 0,

    // close
    wsClosed: 0,
    wsClosedAbnormal: 0,

    // message
    sendOk: 0,
    sendFail: 0,
    recvOk: 0,
    recvFail: 0,

    // endwalk
    endWalkOk: 0,
    endWalkFail: 0,

    // timing
    connectLatencyMs: [],

    // details
    results: [], // per-user
    startedAtIso: new Date().toISOString(),
    endedAtIso: null,
  };
}

function pct(n, d) {
  return d <= 0 ? 0 : n / d;
}

/**
 * 사용자 1명에 대한 WebSocket + STOMP 시나리오 실행
 *
 * idx: 사용자 인덱스 (1부터 시작)
 * userId / token / walkId: 사전 준비된 사용자 정보
 *
 * 각 사용자는 독립적인 WebSocket 세션을 가진다.
 */
async function runWebSocketFlow({ idx, userId, token, walkId }, agg) {
  const SHOULD_LOG = VERBOSE === 1 && idx <= LOG_TOP_N;

  return new Promise((resolve) => {
    const startedAt = Date.now();
    let ended = false;

    let sendTimer = null;
    let endTimer = null;

    // per-user stats
    const stat = {
      idx,
      userId,
      walkId,
      wsConnected: false,
      wsConnectLatencyMs: null,
      abnormalClose: false,
      sendOk: 0,
      sendFail: 0,
      recvOk: 0,
      recvFail: 0,
      endWalkOk: false,
      endWalkFail: false,
      stompError: null,
      wsClosedCode: null,
      wsClosedReason: null,
    };

    const client = new Client({
      brokerURL: WS_URL,
      webSocketFactory: () => new WebSocket(WS_URL),
      reconnectDelay: 0,

      connectHeaders: {
        Authorization: `Bearer ${token}`,
      },

      debug: (s) => {
        if (SHOULD_LOG) console.log(`[stomp ${idx}]`, s);
      },

      // STOMP CONNECT 성공 시 호출
      // - 연결 성공으로 집계
      // - 연결 지연 시간 측정
      // - walkId 토픽 구독 시작
      onConnect: () => {
        stat.wsConnected = true;
        const latency = Date.now() - startedAt;
        stat.wsConnectLatencyMs = latency;

        agg.wsConnectedOk += 1;
        agg.connectLatencyMs.push(latency);

        // 서버 → 클라이언트 메시지 수신 처리
        // - 메시지를 하나라도 받으면 recvOk 증가
        // - VERBOSE 모드일 경우 메시지 body 출력
        // - type === "ERROR" 메시지는 앱 레벨 실패로 간주
        client.subscribe(`/topic/walks/${walkId}`, (msg) => {
          stat.recvOk += 1;
          agg.recvOk += 1;

          if (SHOULD_LOG) {
            console.log(`[recv ${idx}] walkId=${walkId} body=`, msg.body);
          }

          // 앱 레벨 ERROR를 수신하면 fail로 잡음
          try {
            const j = JSON.parse(msg.body);
            if (j?.type === "ERROR") {
              stat.recvFail += 1;
              agg.recvFail += 1;
              stat.abnormalClose = true;
              safeEnd("app_error_received");
            }
          } catch {
            // json이 아니면 그냥 수신 성공으로만 카운트
          }
        });

        // 5초마다 위치 업데이트 메시지 전송
        // - SEND 성공 시 sendOk 증가
        // - 예외 발생 시 sendFail 증가
        sendTimer = setInterval(() => {
          if (ended) return;

          const payload = {
            type: "LOCATION_UPDATE",
            data: {
              lat: START_LAT + (Math.random() - 0.5) * 0.0001,
              lng: START_LNG + (Math.random() - 0.5) * 0.0001,
              timestamp: new Date().toISOString(),
            },
          };

          try {
            client.publish({
              destination: `/app/walks/${walkId}/location`,
              headers: { "content-type": "application/json" },
              body: JSON.stringify(payload),
            });
            stat.sendOk += 1;
            agg.sendOk += 1;
          } catch (e) {
            stat.sendFail += 1;
            agg.sendFail += 1;
          }
        }, SEND_EVERY_MS);

        // RUN_FOR_MS 이후 실행
        // - 산책 종료 API 호출
        // - 정상 종료로 판단
        // - 잠시 대기 후 WebSocket 종료
        endTimer = setTimeout(async () => {
          if (ended) return;
          ended = true;

          const durationSeconds = Math.max(
            1,
            Math.round((Date.now() - startedAt) / 1000),
          );

          try {
            await endWalk(token, walkId, durationSeconds);
            stat.endWalkOk = true;
            agg.endWalkOk += 1;
          } catch (e) {
            stat.endWalkFail = true;
            agg.endWalkFail += 1;
            stat.abnormalClose = true;
          }

          await sleep(1500); // WALK_ENDED 관측 여유
          cleanup();
          resolve(stat);
        }, RUN_FOR_MS);
      },

      onStompError: (frame) => {
        // CONNECTED 전 or 중간에 터질 수 있음
        stat.stompError = frame?.headers?.message || "stomp_error";
        stat.abnormalClose = true;

        agg.wsConnectedFail += stat.wsConnected ? 0 : 1;
        agg.recvFail += 1;

        safeEnd("stomp_error");
      },

      onWebSocketClose: (evt) => {
        // stompjs 환경에 따라 evt가 없거나 {code,reason} 형태로 올 수 있음
        // 여기서 abnormal 여부를 결정
        // - ended=true(테스트가 정상 종료 시퀀스 수행)면 정상
        // - ended=false면 비정상
        if (!ended) stat.abnormalClose = true;

        // 기록
        try {
          stat.wsClosedCode = evt?.code ?? null;
          stat.wsClosedReason = evt?.reason ?? null;
        } catch {}

        agg.wsClosed += 1;
        if (stat.abnormalClose) agg.wsClosedAbnormal += 1;
      },
    });

    function cleanup() {
      if (sendTimer) clearInterval(sendTimer);
      if (endTimer) clearTimeout(endTimer);
      try {
        client.deactivate();
      } catch {}
    }

    function safeEnd(reason) {
      if (ended) return;
      ended = true;
      cleanup();
      resolve(stat);
    }

    // connect attempt
    try {
      client.activate();
    } catch (e) {
      agg.wsConnectedFail += 1;
      stat.abnormalClose = true;
      resolve(stat);
    }

    // safety timeout (onConnect가 영원히 안 올 경우)
    setTimeout(() => {
      if (stat.wsConnected) return;
      stat.abnormalClose = true;
      agg.wsConnectedFail += 1;
      cleanup();
      resolve(stat);
    }, 15000);
  });
}

// ---- reporting ----
function buildSummary(agg) {
  const total = agg.total;

  const connectedRate = pct(agg.wsConnectedOk, total);
  const abnormalCloseRate = pct(
    agg.wsClosedAbnormal,
    Math.max(agg.wsClosed, 1),
  );
  const sendFailRate = pct(
    agg.sendFail,
    Math.max(agg.sendOk + agg.sendFail, 1),
  );
  const recvFailRate = pct(
    agg.recvFail,
    Math.max(agg.recvOk + agg.recvFail, 1),
  );

  const lat = agg.connectLatencyMs.slice().sort((a, b) => a - b);
  const p = (q) => {
    if (!lat.length) return null;
    const idx = Math.min(lat.length - 1, Math.floor(q * lat.length));
    return lat[idx];
  };

  const summary = {
    runId: agg.runId,
    total,

    connected: {
      ok: agg.wsConnectedOk,
      fail: agg.wsConnectedFail,
      rate: connectedRate,
    },
    close: {
      total: agg.wsClosed,
      abnormal: agg.wsClosedAbnormal,
      abnormalRate: abnormalCloseRate,
    },

    send: { ok: agg.sendOk, fail: agg.sendFail, failRate: sendFailRate },
    recv: { ok: agg.recvOk, fail: agg.recvFail, failRate: recvFailRate },

    endWalk: { ok: agg.endWalkOk, fail: agg.endWalkFail },

    connectLatencyMs: {
      count: lat.length,
      min: lat[0] ?? null,
      p50: p(0.5),
      p90: p(0.9),
      p95: p(0.95),
      max: lat[lat.length - 1] ?? null,
    },

    slo: {
      connectedRateGte: SLO_CONNECTED_GTE,
      abnormalCloseRateLt: SLO_ABNORMAL_CLOSE_LT,
      msgFailRateLt: SLO_MSG_FAIL_LT,
      pass:
        connectedRate >= SLO_CONNECTED_GTE &&
        abnormalCloseRate < SLO_ABNORMAL_CLOSE_LT &&
        sendFailRate < SLO_MSG_FAIL_LT &&
        recvFailRate < SLO_MSG_FAIL_LT,
    },
  };

  return summary;
}

function printSummary(summary) {
  console.log("\n=== SLO SUMMARY ===");
  console.log("runId:", summary.runId);
  console.log("total:", summary.total);

  console.log(
    `connectedRate: ${(summary.connected.rate * 100).toFixed(2)}% (${summary.connected.ok}/${summary.total})`,
  );
  console.log(
    `abnormalCloseRate: ${(summary.close.abnormalRate * 100).toFixed(2)}% (${summary.close.abnormal}/${summary.close.total})`,
  );
  console.log(
    `sendFailRate: ${(summary.send.failRate * 100).toFixed(2)}% (fail=${summary.send.fail}, total=${summary.send.ok + summary.send.fail})`,
  );
  console.log(
    `recvFailRate: ${(summary.recv.failRate * 100).toFixed(2)}% (fail=${summary.recv.fail}, total=${summary.recv.ok + summary.recv.fail})`,
  );

  console.log("endWalk:", summary.endWalk);

  console.log("connectLatencyMs:", summary.connectLatencyMs);

  console.log("SLO PASS:", summary.slo.pass ? "✅ PASS" : "❌ FAIL");
  console.log("===================\n");
}

// ---- Prometheus pushgateway ----
function promEscapeLabelValue(v) {
  return String(v)
    .replace(/\\/g, "\\\\")
    .replace(/\n/g, "\\n")
    .replace(/"/g, '\\"');
}

function metricLine(name, value, labels = {}) {
  const keys = Object.keys(labels);
  const labelStr =
    keys.length === 0
      ? ""
      : "{" +
        keys
          .sort()
          .map((k) => `${k}="${promEscapeLabelValue(labels[k])}"`)
          .join(",") +
        "}";
  return `${name}${labelStr} ${value}\n`;
}

/**
 * Pushgateway로 전송되는 메트릭
 *
 * - ws_connected_rate
 * - ws_abnormal_close_rate
 * - ws_send_fail_rate
 * - ws_recv_fail_rate
 * - ws_connect_latency_p95_ms
 * - ws_slo_pass (1 = PASS, 0 = FAIL)
 *
 * run_id / instance 라벨을 사용해 실행 단위로 구분
 */
function buildPromText(summary) {
  const labels = {
    run_id: summary.runId,
    instance: PUSH_INSTANCE,
  };

  let text = "";
  text += "# TYPE ws_connected_rate gauge\n";
  text += metricLine("ws_connected_rate", summary.connected.rate, labels);

  text += "# TYPE ws_abnormal_close_rate gauge\n";
  text += metricLine(
    "ws_abnormal_close_rate",
    summary.close.abnormalRate,
    labels,
  );

  text += "# TYPE ws_send_fail_rate gauge\n";
  text += metricLine("ws_send_fail_rate", summary.send.failRate, labels);

  text += "# TYPE ws_recv_fail_rate gauge\n";
  text += metricLine("ws_recv_fail_rate", summary.recv.failRate, labels);

  text += "# TYPE ws_endwalk_fail_total gauge\n";
  text += metricLine("ws_endwalk_fail_total", summary.endWalk.fail, labels);

  text += "# TYPE ws_connect_latency_p95_ms gauge\n";
  text += metricLine(
    "ws_connect_latency_p95_ms",
    summary.connectLatencyMs.p95 ?? 0,
    labels,
  );

  text += "# TYPE ws_slo_pass gauge\n";
  text += metricLine("ws_slo_pass", summary.slo.pass ? 1 : 0, labels);

  // 디버깅 편의를 위해 원시 카운트도 같이 push
  text += "# TYPE ws_connected_ok_total gauge\n";
  text += metricLine("ws_connected_ok_total", summary.connected.ok, labels);

  text += "# TYPE ws_closed_abnormal_total gauge\n";
  text += metricLine(
    "ws_closed_abnormal_total",
    summary.close.abnormal,
    labels,
  );

  text += "# TYPE ws_send_fail_total gauge\n";
  text += metricLine("ws_send_fail_total", summary.send.fail, labels);

  text += "# TYPE ws_recv_fail_total gauge\n";
  text += metricLine("ws_recv_fail_total", summary.recv.fail, labels);

  return text;
}

async function pushToGateway(summary) {
  if (!PUSHGATEWAY_URL) return;

  const body = buildPromText(summary);

  // Pushgateway: PUT/POST 모두 가능. 보통 PUT 권장.
  // job/instance로 grouping key 구성.
  const url = `${PUSHGATEWAY_URL.replace(/\/$/, "")}/metrics/job/${encodeURIComponent(
    PUSH_JOB,
  )}/instance/${encodeURIComponent(PUSH_INSTANCE)}/run_id/${encodeURIComponent(summary.runId)}`;

  const res = await fetch(url, {
    method: "PUT",
    headers: { "Content-Type": "text/plain; version=0.0.4; charset=utf-8" },
    body,
  });

  if (!res.ok) {
    const t = await res.text().catch(() => "");
    throw new Error(`pushgateway failed: ${res.status} ${t}`);
  }

  console.log("[pushgateway] pushed:", url);
}

// --------------------
// main
// --------------------
async function main() {
  const agg = newAgg(CONCURRENCY);

  const userIds = await seedUsers();

  // 2) 토큰 발급 및 산책 시작 API (안정성 위해 시간이 걸리더라도 순차 처리)
  const users = [];
  for (let i = 0; i < CONCURRENCY; i++) {
    const userId = userIds[i];
    const token = await getDevToken(userId);
    const walkId = await startWalk(token);
    users.push({ idx: i + 1, userId, token, walkId });
  }

  console.log(`[prep] ready users=${users.length} -> start WS flows`);

  // 웹 소켓 통신
  const settled = await Promise.allSettled(
    users.map((u) => runWebSocketFlow(u, agg)),
  );

  for (const s of settled) {
    if (s.status === "fulfilled") {
      agg.results.push(s.value);
    } else {
      agg.results.push({ abnormalClose: true, error: String(s.reason) });
      agg.wsClosedAbnormal += 1;
    }
  }

  agg.endedAtIso = new Date().toISOString();

  // summary
  const summary = buildSummary(agg);
  printSummary(summary);

  // 1) console done (already)
  // 2) JSON write
  const outPath = path.join(OUT_DIR, `result-${RUN_ID}.json`);
  fs.writeFileSync(
    outPath,
    JSON.stringify({ summary, details: agg }, null, 2),
    "utf-8",
  );
  console.log("[json] saved:", outPath);

  // 3) pushgateway
  try {
    await pushToGateway(summary);
  } catch (e) {
    console.error("[pushgateway] failed:", e.message || e);
  }

  // SLO fail이면 exit code로 실패 표시
  if (!summary.slo.pass) process.exit(2);
}

main().catch((e) => {
  console.error("[fatal]", e.message || e);
  process.exit(1);
});
