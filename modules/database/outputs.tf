output "db_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_address" {
  description = "RDS hostname only (без порту)"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_secret_arn" {
  description = "Secrets Manager ARN — DB password"
  value       = aws_secretsmanager_secret.db.arn
}

output "app_secret_arn" {
  description = "Secrets Manager ARN — app secrets (SECRET_KEY, BOT_SECRET_TOKEN тощо)"
  value       = aws_secretsmanager_secret.app.arn
}
