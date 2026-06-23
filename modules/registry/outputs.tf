output "backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "bot_repository_url" {
  description = "URL of the bot ECR repository"
  value       = aws_ecr_repository.bot.repository_url
}
