# 🌿 EcoCommunity — AWS Cloud Infrastructure (IaC)

[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS_Provider-~%3E_5.0-FF9900?logo=amazon-aws&logoColor=white)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![Amazon ECS](https://img.shields.io/badge/AWS-ECS_Fargate-FF9900?logo=amazonecs&logoColor=white)](https://aws.amazon.com/ecs/)
[![Amazon RDS](https://img.shields.io/badge/AWS-RDS_PostgreSQL_16-527FFF?logo=postgresql&logoColor=white)](https://aws.amazon.com/rds/)
[![Amazon CloudFront](https://img.shields.io/badge/AWS-CloudFront_CDN-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/cloudfront/)
[![Architecture](https://img.shields.io/badge/Architecture-Multi--Tier_VPC-00C7B7)](https://aws.amazon.com/vpc/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A production-grade, highly available, and cost-optimized **Infrastructure as Code (IaC)** implementation powering the **EcoCommunity** platform. Built with modular **Terraform**, this repository provisions a secure, multi-tier AWS environment supporting containerized microservices (FastAPI backend and Telegram Bot), a single-page frontend application (SPA), managed relational persistence, distributed object storage, and secure content delivery.

---

## 📑 Table of Contents

- [Overview & Architecture](#-overview--architecture)
- [System Architecture Diagram](#-system-architecture-diagram)
- [Security & Network Isolation](#-security--network-isolation)
  - [3-Tier Subnet Segmentation](#3-tier-subnet-segmentation)
  - [Defense-in-Depth Security Groups](#defense-in-depth-security-groups)
  - [Least-Privilege IAM Model](#least-privilege-iam-model)
  - [Zero-Trust Secrets Management](#zero-trust-secrets-management)
- [Compute & Microservices Orchestration](#-compute--microservices-orchestration)
  - [ECS Fargate Serverless Containers](#ecs-fargate-serverless-containers)
  - [Service Connect & Cloud Map Discovery](#service-connect--cloud-map-discovery)
  - [Unified CloudFront Ingress (Single-Origin Pattern)](#unified-cloudfront-ingress-single-origin-pattern)
- [Storage & Media Pipeline](#-storage--media-pipeline)
- [Cost Optimization Engineering](#-cost-optimization-engineering)
- [Repository Structure](#-repository-structure)
- [Deployment & Operational Guide](#-deployment--operational-guide)
  - [Prerequisites](#prerequisites)
  - [Quickstart: Step-by-Step Deployment](#quickstart-step-by-step-deployment)
- [Outputs & Verification](#-outputs--verification)
- [Technology Stack](#-technology-stack)

---

## 🎯 Overview & Architecture

The **EcoCommunity** infrastructure is engineered around modern DevOps and cloud-native architectural patterns:

- **Serverless Containerization**: Application workloads run on **AWS ECS Fargate**, eliminating EC2 instance management and host-level patching overhead while providing automated horizontal scaling.
- **Service Discovery & Inter-Service Mesh**: Uses **ECS Service Connect** over a private AWS Cloud Map namespace (`eco.local`), enabling the Telegram Bot to communicate with the FastAPI backend without egressing to the public internet or traversing costly internal load balancers.
- **Unified Edge Routing**: Amazon CloudFront routes static frontend traffic directly to S3 and dynamic `/api/*` requests to an Application Load Balancer (ALB), effectively eliminating Cross-Origin Resource Sharing (CORS) friction and mixed-content issues under HTTPS.
- **Network Isolation & Zero Public IP Exposure**: Database instances and compute containers are completely isolated within private and database subnets with strict egress control.
- **Modular Terraform Codebase**: Clean separation into 7 purpose-built modules (`network`, `security`, `database`, `registry`, `compute`, `media`, `cdn`) for reusability, isolation, and maintainability.

---

## 🏛 System Architecture Diagram

```mermaid
flowchart TB
    subgraph Clients[" 🌐 End-User Clients "]
        Browser["🖥️ Web Browser (SPA)"]
        TgUser["📱 Telegram User"]
    end

    subgraph Edge[" 🛡️ Edge & Ingress Layer "]
        CF["☁️ Amazon CloudFront (CDN)<br/>HTTPS Edge Cache & Single Ingress"]
        S3Front["🪣 S3 Bucket<br/>(Frontend SPA Assets)"]
        OAC["Origin Access Control (OAC)"]
    end

    subgraph AWSCloud[" ☁️ AWS Cloud (Region: eu-north-1) "]
        subgraph VPC[" 🔒 Custom VPC (10.0.0.0/16) "]
            
            subgraph PublicSubnets[" 🌐 Public Subnets (AZ-a / AZ-b) "]
                IGW["🚪 Internet Gateway"]
                ALB["⚖️ Application Load Balancer (ALB)<br/>:80 (HTTP /api/*)"]
                NAT["🔄 Custom NAT Instance (t3.micro)<br/>Amazon Linux 2 + iptables"]
            end

            subgraph PrivateSubnets[" 🛡️ Private Subnets (AZ-a / AZ-b) "]
                subgraph ECSCluster[" 📦 ECS Fargate Cluster "]
                    direction TB
                    Backend1["⚙️ FastAPI Backend Task 1<br/>(:8000)"]
                    Backend2["⚙️ FastAPI Backend Task 2<br/>(:8000)"]
                    Bot["🤖 Telegram Bot Task<br/>(Polling / Webhook)"]
                end
                CloudMap["📡 AWS Cloud Map Service Connect<br/>(eco.local)"]
            end

            subgraph DBSubnets[" 🗄️ Isolated DB Subnets (AZ-a / AZ-b) "]
                RDS[("🐘 Amazon RDS PostgreSQL 16<br/>db.t3.micro | :5432")]
            end
        end

        subgraph StorageSecurity[" 🔐 AWS Managed Services "]
            SecretsMgr["🔑 AWS Secrets Manager<br/>(DB Password & App Secrets)"]
            ECR["📦 Amazon ECR<br/>(Backend & Bot Repositories)"]
            S3Media["🪣 S3 Media Bucket<br/>(Marker Photos /uploads/*)"]
            CW["📊 Amazon CloudWatch<br/>(Logs & Metrics)"]
        end
    end

    %% Edge Ingress Flows
    Browser -->|HTTPS /*| CF
    Browser -->|Direct GET /uploads/*| S3Media
    TgUser -->|Telegram API| Bot
    CF -->|Static Assets| OAC --> S3Front
    CF -->|Dynamic /api/*| ALB

    %% ALB Routing
    ALB -->|Port 8000| Backend1
    ALB -->|Port 8000| Backend2

    %% Internal Service Discovery
    Bot -.->|"http://backend.eco.local/api"| CloudMap -.-> Backend1
    Bot -.->|"http://backend.eco.local/api"| CloudMap -.-> Backend2

    %% Outbound Egress via NAT
    ECSCluster -->|Outbound HTTPS| NAT --> IGW

    %% Data Layer Connections
    Backend1 -->|Port 5432 (TLS)| RDS
    Backend2 -->|Port 5432 (TLS)| RDS

    %% Security & Storage Interactions
    ECSCluster -.->|IAM Task Role / S3 Put/Get| S3Media
    ECSCluster -.->|IAM Execution Role / Pull Image| ECR
    ECSCluster -.->|IAM Execution Role / Env Injection| SecretsMgr
    ECSCluster -.->|Logs| CW
```

---

## 🔒 Security & Network Isolation

### 3-Tier Subnet Segmentation

The VPC network topology is partitioned across two Availability Zones (`eu-north-1a`, `eu-north-1b`) into three distinct isolation zones:

| Subnet Tier | CIDR Blocks | Public IP | Purpose & Resources Hosted |
| :--- | :--- | :---: | :--- |
| **Public Subnets** | `10.0.0.0/24`, `10.0.1.0/24` | **Yes** | Internet Gateway entry, ALB, NAT Instance. Routes `0.0.0.0/0` via IGW. |
| **Private Subnets** | `10.0.2.0/24`, `10.0.3.0/24` | **No** | ECS Fargate containers (FastAPI, Bot). Outbound internet routed strictly through NAT Instance. |
| **Database Subnets** | `10.0.20.0/24`, `10.0.21.0/24`| **No** | Amazon RDS PostgreSQL. Completely isolated; no default route to IGW or NAT. |

### Defense-in-Depth Security Groups

Network access adheres strictly to the **Principle of Least Privilege**:

```
[ Internet (0.0.0.0/0) ]
        │  Port 80, 443
        ▼
┌───────────────────────┐
│     alb-sg (ALB)      │
└───────────────────────┘
        │  Port 8000 ONLY
        ▼
┌───────────────────────┐
│     ecs-sg (ECS)      │ ◄─── (Self-referential ingress on 8000)
└───────────────────────┘
        │  Port 5432 ONLY
        ▼
┌───────────────────────┐
│      db-sg (RDS)      │
└───────────────────────┘
```

- **`alb-sg`**: Accepts public HTTP (80) and HTTPS (443) ingress.
- **`ecs-sg`**: Refuses all external connections. Permits ingress on port `8000` **strictly from `alb-sg`** and intra-cluster communication.
- **`db-sg`**: Refuses all external and public subnet traffic. Ingress on port `5432` is granted **strictly to members of `ecs-sg`**.

### Least-Privilege IAM Model

Container security separates infrastructure lifecycle operations from runtime logic using two specialized IAM roles:

1. **ECS Task Execution Role (`ecs_task_execution_role`)**:
   - Used by the AWS ECS agent during container initialization.
   - Grants permissions to pull container images from Amazon ECR (`AmazonECSTaskExecutionRolePolicy`).
   - Grants rights to stream task logs to **CloudWatch Logs** (`/ecs/eco-project-*`).
   - Retrieves encrypted database credentials from **AWS Secrets Manager**.
2. **ECS Task Role (`ecs_task_role`)**:
   - Assumed by the container runtime code itself.
   - Grants tightly scoped permissions (`s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:ListBucket`) exclusively restricted to the marker photo storage bucket (`arn:aws:s3:::eco-project-media-*`).
   - Prevents the container process from accessing infrastructure configurations or arbitrary AWS APIs.

### Zero-Trust Secrets Management

- **Cryptographic Generation**: Master database password is generated dynamically during `terraform apply` using a 16-character high-entropy alphanumeric-special string (`random_password`) and committed directly to AWS Secrets Manager (`eco-project-db-secret`).
- **No Hardcoded Credentials**: Passwords and application secrets (`SECRET_KEY`, `BOT_SECRET_TOKEN`, `BOT_API_KEY`, `FRONTEND_URL`) are injected into the ECS task definitions as runtime environment variables directly from Secrets Manager (`valueFrom = ...`).
- **State Drift Protection**: The application secrets resource utilizes Terraform's `ignore_changes = [secret_string]` lifecycle rule, allowing administrators to update credentials in the AWS Console without being overwritten on subsequent Terraform runs.

---

## ⚡ Compute & Microservices Orchestration

### ECS Fargate Serverless Containers

- **FastAPI Backend Service**:
  - Launch type: `FARGATE` (Serverless compute, `512 CPU` / `1024 Memory`).
  - Replicas: `desired_count = 2` spread across multiple Availability Zones for high availability.
  - Health checks: Configured on ALB Target Group targeting `/health` (HTTP 200 required; interval: 30s, timeout: 5s, 2 healthy / 3 unhealthy thresholds).
- **Telegram Bot Service**:
  - Launch type: `FARGATE` (`256 CPU` / `512 Memory`).
  - Replicas: `desired_count = 1`.
  - Operates asynchronously, interacting with users and communicating with the backend API.

### Service Connect & Cloud Map Discovery

Rather than routing inter-service microservice requests across the public internet or through costly private ALBs, this architecture deploys **AWS Cloud Map HTTP Namespace** (`eco.local`):

- **Backend Discovery**: Registered under `eco.local` with client alias `backend.eco.local:80`.
- **Bot Integration**: The Telegram Bot targets `http://backend.eco.local/api` directly via internal DNS resolution managed by the local Service Connect sidecar proxy, minimizing latency and eliminating data transfer costs.

### Unified CloudFront Ingress (Single-Origin Pattern)

Amazon CloudFront acts as a centralized reverse proxy and CDN:

```
                  ┌───────────────► /api/*    ──► ALB ──► FastAPI Backend (ECS)
User ──► CloudFront ──────────────► /health  ──► ALB ──► Health Endpoint
                  └───────────────► /* (Default) ──► S3 (Frontend SPA)
```

- **Cache Behavior `/api/*`**: Forwards all headers (`Authorization`, `Content-Type`, `Origin`, etc.), query parameters, and cookies to the ALB. Configured with `TTL = 0` to prevent caching of dynamic REST responses while terminating HTTPS and avoiding browser CORS issues.
- **Default Cache Behavior (`/*`)**: Delivers cached static assets directly from private S3 via **Origin Access Control (OAC)** with gzip/brotli compression enabled.
- **SPA Client Routing**: Configured with custom error responses translating HTTP `403` and `404` status codes into HTTP `200` responses pointing to `/index.html`, ensuring clean client-side routing for modern single-page applications.

---

## 📦 Storage & Media Pipeline

1. **Frontend Bucket (`eco-project-bucket-*`)**:
   - Protected with `aws_s3_bucket_public_access_block` (all public ACLs and policies blocked).
   - Read access restricted exclusively to the CloudFront distribution via SigV4 Origin Access Control (OAC).
2. **Media Bucket (`eco-project-media-*`)**:
   - Stores user-uploaded ecological marker photographs.
   - Public read permissions restricted to `/uploads/*` for browser client rendering.
   - Direct write permissions restricted to the backend ECS Task Role.
   - **Automated Lifecycle Policy**: Cleans up temporary or aborted upload files under the `temp/` prefix after **1 day**, preventing storage bloat.
3. **Container Registry (Amazon ECR)**:
   - Dedicated private repositories for `eco-project-ecr-backend` and `eco-project-ecr-bot`.
   - **Scan on Push**: Automated vulnerability scanning activated on every Docker image push.
   - **Lifecycle Management**: Automatically prunes untagged and legacy builds, keeping only the **last 5 images** to minimize storage overhead.

---

## 💰 Cost Optimization Engineering

Designed with real-world budget constraints in mind, this architecture includes strategic cost optimizations:

| Architectural Component | Standard Enterprise Approach | EcoCommunity Optimized Design | Savings Impact |
| :--- | :--- | :--- | :--- |
| **NAT Gateway** | Managed AWS NAT Gateway (~$32.40/mo + $0.045/GB) | **Custom NAT Instance (`t3.micro`)** with automated IP forwarding & `iptables` masquerade | **~$27.00/mo saved** |
| **Inter-Service Mesh** | Internal Application Load Balancer (~$22.00/mo) | **ECS Service Connect** over Cloud Map | **~$22.00/mo saved** |
| **ECR Image Retention** | Unlimited image retention | **ECR Lifecycle Rule** (retains only latest 5 images) | **Storage cost reduced by ~80%** |
| **CloudFront CDN** | `PriceClass_All` (worldwide edge locations) | **`PriceClass_100`** (US, Canada, Europe) | **Bandwidth & request savings** |
| **Database** | Multi-AZ Deployment | **Single-AZ (`db.t3.micro`)** with automated snapshot skip for dev/demo | **~$30.00/mo saved** |
| **Object Cleanup** | Manual cleanup scripts | **S3 Lifecycle Expiration** (`temp/` pruned after 24h) | **Zero orphaned storage waste** |

> 💡 **Total Estimated Savings**: **~$80+ / month**, providing a full-featured microservices cloud environment at a fraction of typical production infrastructure costs.

---

## 📁 Repository Structure

```text
eco-community-infra/
├── main.tf                    # Root composition: wires modules together
├── variables.tf               # Root input variable definitions & defaults
├── outputs.tf                 # Essential infrastructure endpoints & credentials
├── terraform.tfvars           # Environment configuration values
├── .terraform.lock.hcl        # Provider dependency lockfile
├── modules/
│   ├── network/               # VPC, Subnets, IGW, NAT Instance, ALB, Security Groups
│   │   ├── vpc.tf             # Multi-AZ subnets (public, private, DB) & VPC definition
│   │   ├── nat_iustance.tf    # Lightweight Amazon Linux 2 NAT instance with iptables
│   │   ├── alb.tf             # Application Load Balancer, Listener & Target Group
│   │   ├── routetables.tf     # Routing tables & associations
│   │   ├── security_groups.tf # Least-privilege firewall rules (ALB, ECS, DB)
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/               # ECS Fargate, Task Definitions, Service Connect
│   │   ├── ecs.tf             # ECS Cluster, Services, and Service Connect namespace
│   │   ├── task_defenitions.tf# Task definitions (FastAPI backend + Telegram bot)
│   │   ├── cloudwatch.tf      # CloudWatch log groups for backend & bot
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/              # RDS PostgreSQL & Secrets Manager
│   │   ├── rds.tf             # PostgreSQL 16 engine instance (db.t3.micro)
│   │   ├── secrets.tf         # Dynamic password generation & App secrets store
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── registry/              # Amazon ECR Repositories
│   │   ├── ecr.tf             # Backend & Bot repositories with lifecycle policies
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── media/                 # S3 Media Storage
│   │   ├── s3.tf              # Bucket policies, CORS & temporary lifecycle rules
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── cdn/                   # CloudFront CDN & S3 Frontend
│   │   ├── cloudfront.tf      # Distribution with path routing (/api/* -> ALB) & OAC
│   │   ├── s3.tf              # Private frontend S3 bucket
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── security/              # IAM Roles & Policies
│       ├── iam.tf             # ECS Task Execution Role & Runtime Task Role
│       ├── variables.tf
│       └── outputs.tf
```

---

## 🚀 Deployment & Operational Guide

### Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/install) (v1.5.0 or newer)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with administrative credentials:
  ```bash
  aws configure
  ```
- [Docker Engine](https://docs.docker.com/get-docker/) for container image compilation

### Quickstart: Step-by-Step Deployment

#### 1. Initialize and Provision Infrastructure

```bash
# Clone repository
git clone https://github.com/RomanMartynyshyn/eco-community-infra.git
cd eco-community-infra

# Initialize Terraform providers & modules
terraform init

# Review execution plan
terraform plan

# Apply infrastructure deployment
terraform apply -auto-approve
```

#### 2. Populate Application Secrets in AWS Secrets Manager

Terraform automatically generates the database password. Secure application runtime secrets can be populated in the AWS Secrets Manager Console under `eco-project-app-secrets`:

```json
{
  "SECRET_KEY": "<generated_hex_secret_key>",
  "BOT_SECRET_TOKEN": "<internal_bot_api_token>",
  "BOT_API_KEY": "<telegram_bot_token_from_botfather>",
  "FRONTEND_URL": "https://<your-cloudfront-domain>.cloudfront.net"
}
```

#### 3. Build & Push Docker Images to Amazon ECR

Retrieve ECR repository endpoints from Terraform outputs:

```bash
# Authenticate Docker to AWS ECR
aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin $(terraform output -raw backend_ecr_url | cut -d'/' -f1)

# Build & Push Backend
docker build -t $(terraform output -raw backend_ecr_url):latest ./eco-community-backend
docker push $(terraform output -raw backend_ecr_url):latest

# Build & Push Telegram Bot
docker build -t $(terraform output -raw bot_ecr_url):latest ./eco-community-bot
docker push $(terraform output -raw bot_ecr_url):latest

# Trigger zero-downtime deployment on ECS
aws ecs update-service --cluster eco-project-ecs-cluster --service backend-service --force-new-deployment --region eu-north-1
aws ecs update-service --cluster eco-project-ecs-cluster --service bot-service --force-new-deployment --region eu-north-1
```

#### 4. Deploy Frontend SPA to S3 & Invalidate CDN Cache

```bash
# Build frontend SPA
cd ./eco-community-frontend && npm run build

# Synchronize distribution assets to S3
aws s3 sync ./dist s3://$(terraform output -raw s3_bucket_name) --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id $(terraform output -raw cloudfront_id) --paths "/*"
```

---

## 📊 Outputs & Verification

Upon successful deployment, Terraform exports key operational endpoints:

| Output Variable | Description |
| :--- | :--- |
| `cloudfront_domain` | **Primary Application URL** (Access frontend SPA and `/api/*` endpoints) |
| `alb_dns_name` | Direct DNS name of Application Load Balancer |
| `s3_bucket_name` | Frontend target bucket for deployment synchronization |
| `backend_ecr_url` | Amazon ECR URI for Backend container images |
| `bot_ecr_url` | Amazon ECR URI for Telegram Bot container images |
| `db_secret_arn` | AWS Secrets Manager ARN storing PostgreSQL credentials |

### Quick Health Check Verification

```bash
# Verify API routing through CloudFront CDN
curl -i https://$(terraform output -raw cloudfront_domain)/health
# Expected Response: HTTP/2 200 OK {"status": "healthy"}
```

---

## 🛠 Technology Stack

- **Cloud Provider**: Amazon Web Services (AWS)
- **Infrastructure as Code**: HashiCorp Terraform (~> 5.0 AWS Provider)
- **Container Compute**: AWS ECS on AWS Fargate
- **Database Engine**: Amazon RDS for PostgreSQL 16
- **Content Delivery**: Amazon CloudFront (OAC, Path-based routing)
- **Object Storage**: Amazon S3 (Frontend assets & media storage)
- **Service Discovery**: AWS Cloud Map (ECS Service Connect)
- **Networking**: Amazon VPC, Custom Linux NAT Instance, Application Load Balancer
- **Secrets & IAM**: AWS Secrets Manager, IAM Roles & Policies
- **Monitoring & Logging**: Amazon CloudWatch Logs

---

## 👤 Author & Project Context

Developed by **Roman Martynyshyn** as the Cloud & Infrastructure backbone for the **EcoCommunity** diploma platform. Designed to demonstrate enterprise cloud architecture, Infrastructure as Code best practices, cost-conscious engineering, and containerized microservice operations on AWS.

---

<div align="center">
  <sub>Built with ❤️ for a cleaner, greener community.</sub>
</div>
