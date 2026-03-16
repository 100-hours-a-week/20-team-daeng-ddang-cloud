# 댕동여지도 V3

## 개요

- kubeadm 기반 Kubernetes 클러스터 인프라를 구성하기 위한 Terraform 코드
- 인프라 프로비저닝까지만 담당하며 다음 항목은 수동으로 진행한다.
  - kubeadm init
  - Calico 설치
  - kube-proxy ipvs 적용
  - control plane join

### 실행 흐름

1단계

terraform apply

- cp 3대 생성
- worker ASG 생성되지만 desired=0
- internal NLB 생성
- SG/IAM 생성

2단계

bootstrap 수행

- cp1 kubeadm init
- kubeconfig 설정
- Calico 설치
- kube-proxy ipvs 적용
- cp join command 생성
- worker join command 생성
- 둘 다 Parameter Store 저장
- cp2, cp3 join

3단계

worker ASG desired를 3으로 증가

- 새 worker 인스턴스 부팅
- user-data에서 hostname 설정
- SSM에서 join command 읽어서 join

## 실행 순서

### 사전 준비

기존 네트워크 리소스를 재사용한다.

- VPC
- Private Subnet 3개 이상
- Public Subnet 3개 이상
- NAT 또는 외부 패키지 다운로드가 가능한 outbound 경로
- Control Plane용 AMI (ubuntu ami)
- Worker Node용 AMI (userdata-common.sh.tpl이 적용된 ami)
- Key Pair

### 초기 Terraform

1. Terraform 초기화

```bash
terraform init -reconfigure -backend-config=backend.hcl
```

> 로컬에서 tfstate를 관리하시려면 `terraform init -backend=false`를 입력하세요.

2.  초기에는 worker를 띄우지 않고 control plane 및 기반 리소스만 먼저 생성하는 것을 권장합니다.

terraform.tfvars에서 아래처럼 설정:

```hcl
worker_asg_min_size         = 0
worker_asg_desired_capacity = 0
```

실행:

```bash
terraform plan
terraform apply
```

이 단계에서 생성되는 것:

- control plane EC2 3대
- internal NLB
- security groups
- IAM roles / instance profiles
- worker launch template
- worker ASG (단, worker instance는 0대)

### 수동 작업 구간

Terraform apply 후, 수동으로 작업합니다.

1. CP1 kubeadm init
2. kubeconfig 설정
3. Calico 설정
4. kube-proxy 설정
5. CP2, CP3 kubeadm join
6. Parameter Store에 Worker join command 저장

```bash
WORKER_JOIN_CMD="$(sudo kubeadm token create --print-join-command)"

aws ssm put-parameter \
  --name "/daeng-map/prod/k8s/worker_join_command" \
  --type "SecureString" \
  --value "${WORKER_JOIN_CMD}" \
  --overwrite \
  --region ap-northeast-2
```

### 최종 Terraform

수동 작업이 완료되면 terraform.tfvars에서 값들을 수정하고, 새로 terraform apply 합니다.

terraform.tfvars 수정:

```hcl
# 원하는 숫자로 설정
worker_asg_min_size         = 3
worker_asg_desired_capacity = 3
```

그 다음 실행:

```bash
terraform plan
terraform apply
```

이 단계에서 worker 3대가 생성되며,
각 worker는 user-data에서 다음 순서로 동작한다.

1. 공통 패키지 설치
2. hostname 설정 (worker-{instance-id})
3. Parameter Store에서 worker join command 조회
4. kubeadm join 실행
5. 클러스터에 worker로 등록
