# 댕동여지도 V1 AWS Terraform

댕동여지도 V1 서비스의 AWS 인프라를 Terraform으로 관리하기 위한 코드입니다.

본 Terraform 구성은 **환경별 스택 분리**를 핵심 원칙으로 하며,

- `prod` & `dev` : 항상 유지되는 **고정 인프라**
- `staging-ephemeral` : CI/CD에서만 잠깐 생성되었다가 삭제되는 **일회성 인프라**

를 명확히 구분합니다.

<br>
<br>

## 1. 핵심 설계 개요

### 1.1. 환경 분리 전략

| 환경      | 스택 위치                  | 특징                               |
| --------- | -------------------------- | ---------------------------------- |
| prod, dev | `stacks/base`              | 항상 유지되는 운영 인프라          |
| staging   | `stacks/staging-ephemeral` | CI에서만 생성 → 테스트 → 즉시 삭제 |

- 어떤 환경을 만드는지는 tfvars가 아니라 `apply를 실행하는 디렉터리`로 결정됩니다.
- **prod / dev 환경 구축을 위해선 `stacks/base` 위치에서 terraform 명령어를 실행해야 합니다.**
- **staging 환경 구축을 위해선 `stacks/staging-ephemeral` 위치에서 terraform 명령어를 실행해야 합니다.**

### 1.2. 왜 staging-ephemeral인가?

staging 환경은 다음 목적만을 가집니다.

- WebSocket 동시 연결 수
- 부하 테스트(SLO)
- E2E 테스트

따라서:

- S3 ❌
- Route53 ❌
- Caddy ❌
- 고정 도메인 ❌
- 고정 IP ❌

**EC2 + 네트워크만 잠깐 생성 후 바로 삭제**하는 구조를 사용합니다.

<br>
<br>

## 2. 사전 준비

Mac 기준 설명입니다.

### 2.1. Homebrew 설치

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2.2. Terraform 설치

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform -v
```

Terraform 버전은 >= 1.14이어야 합니다.

### 2.3. AWS CLI 설치

```bash
brew install awscli
aws --version
```

### 2.4. AWS 계정 인증 설정

Terraform은 AWS CLI에 설정된 인증 정보를 사용합니다.

```bash
aws configure
```

입력 항목:

| 항목                  | 설명                       |
| --------------------- | -------------------------- |
| AWS Access Key ID     | IAM 사용자 또는 SSO 키     |
| AWS Secret Access Key | 위 키에 대응하는 Secret    |
| Default region name   | ap-northeast-2 (서울 리전) |
| Default output format | json                       |

설정 확인:

```bash
aws sts get-caller-identity
```

<br>
<br>

## 3. 프로젝트 클론

```bash
git clone https://github.com/100-hours-a-week/20-team-daeng-ddang-cloud.git
cd 20-team-daeng-ddang-cloud/terraform/v1/aws
```

<br>
<br>

## 4. 환경 변수 파일 설정

Terraform 코드는 공통이며 환경별 설정 값은 tfvars 파일로 분리합니다.

### 4.1. 예시 파일 복사

```bash
cp environments/example.tfvars environments/dev.tfvars
```

또는

```bash
cp environments/example.tfvars environments/prod.tfvars
```

> 💡 이하 내용은 dev를 기준으로 작성합니다.

### 4.2. 변수 파일 수정

```bash
vi environments/dev.tfvars
```

<br>
<br>

## 5. Terraform 실행 방법

dev 환경 세팅을 기준으로, 명령어를 실행하는 위치는 `terraform/v1/aws/stacks/base`입니다.

**staging 환경 구축을 위해선 `terraform/v1/aws/stacks/staging-ephemeral`에서 작업하세요**

### 5.1. 초기화

```bash
terraform init
```

### 5.2. 실행 계획 확인

```bash
terraform plan  -var-file=../../environments/dev.tfvars
```

### 5.3. 인프라 프로비저닝

```bash
terraform apply -var-file=../../environments/dev.tfvars
```

<br>
<br>

## 6. 생성 결과 확인

```bash
terraform output
```

주요 출력값:

| 항목              | 설명                    |
| ----------------- | ----------------------- |
| server_public_ip  | EC2에 연결된 Elastic IP |
| vpc_id            | 생성된 VPC ID           |
| instance_hostname | EC2 내부 DNS            |

<br>
<br>

## 7. 기존 리소스 Terraform에 편입 (Import)

이미 AWS에 존재하는 리소스를 Terraform이 관리하도록 만들 수 있습니다.

예:

```bash
terraform import -var-file=../../environments/dev.tfvars module.base_network.aws_vpc.main vpc-xxxxxxxxxxxxxxxxx
```

필요한 리소스에 대해 terraform import 하세요.

> ⚠️ import 시에도 변수 파일이 필요합니다.

<br>
<br>

## 8. 인프라 삭제

```bash
terraform destroy -var-file=../../environments/dev.tfvars
```

<br>
<br>

## 9. 디렉터리 구조

```
terraform/v1/aws/
  modules/
    base_network/
      main.tf
      variables.tf
      outputs.tf
    ec2_single/
      main.tf
      variables.tf
      outputs.tf
    s3_public_bucket/
      main.tf
      variables.tf
      outputs.tf

  stacks/
    base/
      provider.tf
      terraform.tf
      main.tf
      variables.tf
      outputs.tf

    staging-ephemeral/
      provider.tf
      terraform.tf
      main.tf
      variables.tf
      outputs.tf

  environments/
    prod.tfvars
    dev.tfvars
    staging-ephemeral.tfvars
```

<br>
<br>

## 10. 주의사항

- prod / staging 혼용 금지
  - prod.tfvars를 staging-ephemeral에서 사용하면 안 됩니다.
  - staging.tfvars를 base에서 사용하면 안 됩니다.
- Drift 발생
  - 콘솔 수동 변경을 금지합니다.
  - 모든 변경은 Terraform 코드로 반영해야 합니다.
- S3 Public 정책 주의
  - 현재 S3 버킷은 Public Read 정책이 적용돼 있습니다.
  - 보안 검토 후 사용해야 합니다.
- SSH 보안
  - 운영에서는 0.0.0.0/0 대신 관리자 IP나 VPN IP 등으로 제한해 허용하세요.
