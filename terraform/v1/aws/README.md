# 댕동여지도 V1 AWS Terraform

댕동여지도 V1 서비스 인프라를 AWS에 프로비저닝하기 위한 Terraform 코드입니다.

VPC, Subnet, EC2, EIP, Security Group, S3 등을 코드로 관리합니다.

## 1. 사전 준비

아래 도구들이 로컬에 설치되어 있어야 하며 Mac 버전에 대한 설명입니다.

### 1.1. Homebrew 설치
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 1.2. Terraform 설치

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform -v
```

Terraform 버전은 >= 1.2이어야 합니다.

### 1.3. AWS CLI 설치

```bash
brew install awscli
aws --version
```

### 1.4. AWS 계정 인증 설정

Terraform은 AWS CLI에 설정된 인증 정보를 사용합니다.

```bash
aws configure
````

입력 항목:

| 항목 | 설명 |
| --- | --- |
| AWS Access Key ID | IAM 사용자 또는 SSO 키 |
| AWS Secret Access Key | 위 키에 대응하는 Secret |
| Default region name | ap-northeast-2 (서울 리전) |
| Default output format | json |

설정 확인:

```bash
aws sts get-caller-identity
````

<br>
<br>

## 2. 프로젝트 클론

```bash
git clone https://github.com/100-hours-a-week/20-team-daeng-ddang-cloud.git
cd 20-team-daeng-ddang-cloud/terraform/v1/aws
```

<br>
<br>

## 3. 환경 변수 파일 설정

Terraform 코드는 공통이며 환경별 설정 값은 tfvars 파일로 분리합니다.

### 3.1. 예시 파일 복사

```bash
cp environments/example.tfvars environments/dev.tfvars
```

또는

```bash
cp environments/example.tfvars environments/prod.tfvars
```

> 💡 이하 내용은 dev를 기준으로 작성합니다.

### 3.2. 변수 파일 수정

```bash
vi environments/dev.tfvars
```

<br>
<br>

## 4. Terraform 실행 방법

### 4.1. 초기화

```bash
terraform init
```

### 4.2. 실행 계획 확인

```bash
terraform plan  -var-file=environments/dev.tfvars
```

### 4.3. 인프라 프로비저닝

```bash
terraform apply -var-file=environments/dev.tfvars
```

<br>
<br>

## 5. 생성 결과 확인

```bash
terraform output
```

주요 출력값:

| 항목 | 설명 |
| --- | --- |
| server_public_ip | EC2에 연결된 Elastic IP |
| vpc_id | 생성된 VPC ID |
| instance_hostname | EC2 내부 DNS |

<br>
<br>

## 6. 기존 리소스 Terraform에 편입 (Import)

이미 AWS에 존재하는 리소스를 Terraform이 관리하도록 만들 수 있습니다.

예:

```bash
terraform import -var-file=environments/prod.tfvars aws_s3_bucket.example example
```

필요한 리소스에 대해 terraform import 하세요.

> ⚠️ import 시에도 변수 파일이 필요합니다.

<br>
<br>

## 7. 인프라 삭제

```bash
terraform destroy -var-file=environments/dev.tfvars
```

<br>
<br>

## 8. 주의사항

- Drift 발생
  - 콘솔 수동 변경을 금지합니다.
  - 모든 변경은 Terraform 코드로 반영해야 합니다.
- S3 Public 정책 주의
  - 현재 S3 버킷은 Public Read 정책이 적용돼 있습니다.
  - 보안 검토 후 사용해야 합니다.
- SSH 보안
  - 운영에서는 0.0.0.0/0 대신 관리자 IP나 VPN IP 등으로 제한해 허용하세요.