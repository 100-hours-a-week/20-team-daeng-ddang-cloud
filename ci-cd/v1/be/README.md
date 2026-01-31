# 댕동여지도 V1 CI/CD BE

## SLO

### 웹 소켓 내구성 검증: 100명 동시 접속

`ws_walk_slo.js` 파일을 실행해 부하테스트를 진행합니다.

본 테스트를 성공적으로 진행하기 위해서는 PostgreSQL과 백엔드(스프링) 서버가 정상적으로 실행되고 있어야 합니다.

#### 실행 방법

```bash
CONCURRENCY=100 RUN_FOR_MS=180000 \
node ws_walk_slo.js
```

100명의 동시 접속을 3분 동안 유지합니다.

> Prometheus 연동 관련 환경 변수는
>
> PUSHGATEWAY_URL, PUSH_JOB, PUSH_INSTANCE
>
> 입니다.
