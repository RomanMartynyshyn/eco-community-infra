output "backend_ecr_url" {
  description = "ECR repository URL for backend image"
  value       = aws_ecr_repository.backend.repository_url
}

output "bot_ecr_url" {
  description = "ECR repository URL for bot image"
  value       = aws_ecr_repository.bot.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}
