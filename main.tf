terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# CloudFront ACM certificates MUST be created in us-east-1
# Розкоментуй коли підключиш cdn модуль
# provider "aws" {
#   alias  = "us_east_1"
#   region = "us-east-1"
# }

# ─── NETWORK (VPC, Subnets, IGW, NAT, ALB, Security Groups) ───────────────────
module "network" {
  source = "./modules/network"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

# ─── SECURITY (IAM Roles) — розкоментуй разом з COMPUTE ─────────────────────
# module "security" {
#   source = "./modules/security"
#
#   project_name = var.project_name
# }

# ─── DATABASE (RDS PostgreSQL + Secrets Manager) ──────────────────────────────
module "database" {
  source = "./modules/database"

  project_name         = var.project_name
  db_subnet_ids        = module.network.db_subnet_ids
  db_security_group_id = module.network.db_security_group_id
}

# ─── COMPUTE (ECR + ECS Fargate: backend + bot) ───────────────────────────────
# Розкоментуй після: 1) terraform apply (network+db) 2) docker push в ECR
# module "compute" {
#   source = "./modules/compute"
#
#   project_name                = var.project_name
#   private_subnet_ids          = module.network.private_subnet_ids
#   ecs_security_group_id       = module.network.ecs_security_group_id
#   alb_listener_arn            = module.network.alb_listener_arn
#   alb_target_group_arn        = module.network.alb_target_group_arn
#   ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
# }

# ─── CDN (S3 + CloudFront + ACM + Route53) ────────────────────────────────────
# module "cdn" {
#   source = "./modules/cdn"

#   providers = {
#     aws           = aws
#     aws.us_east_1 = aws.us_east_1
#   }

#   project_name = var.project_name
#   domain_name  = var.domain_name
#   bucket_name  = var.bucket_name
#   environment  = var.environment
#   price_class  = var.price_class
# }
