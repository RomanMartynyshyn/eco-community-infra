variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks."
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB listener ARN for ECS service dependency."
  type        = string
}

variable "alb_target_group_arn" {
  description = "ALB target group ARN for ECS backend service."
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution."
  type        = string
}

# ─── ECR Repositories ───────────────────────────────────────────────
variable "backend_repository_url" {
  description = "URL of the ECR repository for the backend image."
  type        = string
}

variable "bot_repository_url" {
  description = "URL of the ECR repository for the bot image."
  type        = string
}

# ─── Secrets ────────────────────────────────────────────────────────
variable "db_secret_arn" {
  description = "Secrets Manager ARN for DB password secret."
  type        = string
}

variable "app_secret_arn" {
  description = "Secrets Manager ARN for app secrets (SECRET_KEY, BOT_SECRET_TOKEN)."
  type        = string
}

variable "db_address" {
  description = "RDS hostname (without port)."
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  sensitive   = true
}

# ─── Media S3 ─────────────────────────────────────────────────────
variable "media_bucket_name" {
  description = "S3 media bucket name."
  type        = string
}

variable "media_bucket_url" {
  description = "Public base URL for media files."
  type        = string
}
