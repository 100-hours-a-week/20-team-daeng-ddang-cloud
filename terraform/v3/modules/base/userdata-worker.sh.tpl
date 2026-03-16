#!/bin/bash
set -euxo pipefail

echo "ROLE=worker" >/etc/node-role

# 1. hostname 설정: worker-{instance_id}
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -sS -H "X-aws-ec2-metadata-token: $${TOKEN}" \
  http://169.254.169.254/latest/meta-data/instance-id)

HOSTNAME="worker-$${INSTANCE_ID}"
hostnamectl set-hostname "$${HOSTNAME}"
echo "$${HOSTNAME}" > /etc/hostname

# 2. kubeadm join
AWS_REGION="${aws_region}"
JOIN_PARAM_NAME="${worker_join_ssm_parameter_name}"

while true; do
  JOIN_CMD="$(aws ssm get-parameter \
    --region "$${AWS_REGION}" \
    --name "$${JOIN_PARAM_NAME}" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text 2>/dev/null || true)"

  if [ -n "$${JOIN_CMD}" ] && [ "$${JOIN_CMD}" != "None" ] && [ "$${JOIN_CMD}" != "null" ]; then
    break
  fi

  echo "worker join command is not ready yet. retrying in 15 seconds..."
  sleep 15
done

# 이미 join 된 경우 재실행 방지
if [ ! -f /etc/kubernetes/kubelet.conf ]; then
  eval "$${JOIN_CMD} --node-name $${HOSTNAME}"
fi