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
