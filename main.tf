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
# Розкоментуй коли підключиш власний домен
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

# ─── SECURITY (IAM Roles) ─────────────────────────────────────────────────────
module "security" {
  source = "./modules/security"

  project_name      = var.project_name
  media_bucket_name = var.media_bucket_name
}

# ─── DATABASE (RDS PostgreSQL + Secrets Manager) ──────────────────────────────
module "database" {
  source = "./modules/database"

  project_name         = var.project_name
  db_subnet_ids        = module.network.db_subnet_ids
  db_security_group_id = module.network.db_security_group_id
}

# ─── REGISTRY (ECR Docker Репозиторії) ─────────────────────────────────────────
module "registry" {
  source = "./modules/registry"

  project_name = var.project_name
}

# ─── COMPUTE (ECR + ECS Fargate: backend + bot) ───────────────────────────────
module "compute" {
  source = "./modules/compute"

  project_name                = var.project_name
  private_subnet_ids          = module.network.private_subnet_ids
  ecs_security_group_id       = module.network.ecs_security_group_id
  alb_listener_arn            = module.network.alb_listener_arn
  alb_target_group_arn        = module.network.alb_target_group_arn
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.security.ecs_task_role_arn

  # Secrets Manager ARNs (значення заповнені вручну в AWS Console)
  db_secret_arn  = module.database.db_secret_arn
  app_secret_arn = module.database.app_secret_arn

  # DB connection info (без пароля — він в Secrets Manager)
  db_address  = module.database.db_address
  db_name     = module.database.db_name
  db_username = module.database.db_username

  # Media S3
  media_bucket_name = var.media_bucket_name
  media_bucket_url  = module.media.media_bucket_url

  # ECR Repositories URLs
  backend_repository_url = module.registry.backend_repository_url
  bot_repository_url     = module.registry.bot_repository_url
}

# ─── MEDIA (S3 для фото маркерів) ─────────────────────────────────────────────
module "media" {
  source = "./modules/media"

  project_name      = var.project_name
  media_bucket_name = var.media_bucket_name
  environment       = var.environment
}

# ─── CDN (S3 + CloudFront) ────────────────────────────────────────────────────
module "cdn" {
  source = "./modules/cdn"

  project_name = var.project_name
  bucket_name  = var.bucket_name
  environment  = var.environment
  price_class  = "PriceClass_100"
  alb_dns_name = module.network.alb_dns_name
  # domain_name не потрібен — використовуємо *.cloudfront.net
  # Розкоментуй поле нижче коли буде власний домен:
  # domain_name = var.domain_name
}
