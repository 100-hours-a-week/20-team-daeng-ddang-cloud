#!/bin/bash
set -euxo pipefail

echo "ROLE=control-plane" >/etc/node-role

# hostname 설정
hostnamectl set-hostname ${node_name}