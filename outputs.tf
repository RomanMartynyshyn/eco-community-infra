# ─── Network ──────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name (use this for backend API URL)"
  value       = module.network.alb_dns_name
}

# ─── Frontend (CDN) — розкоментуй коли підключиш cdn модуль ─────────────────
# output "cloudfront_domain" {
#   description = "CloudFront distribution domain name"
#   value       = module.cdn.cloudfront_domain
# }

# output "cloudfront_id" {
#   description = "CloudFront distribution ID (for cache invalidation in CI/CD)"
#   value       = module.cdn.cloudfront_id
# }

# output "s3_bucket_name" {
#   description = "S3 bucket name — run: aws s3 sync ./dist s3://<bucket>"
#   value       = module.cdn.s3_bucket_name
# }

# ─── Registry (ECR) ──────────────────────────────────────────────────────────
output "backend_ecr_url" {
  description = "Push backend image here: docker push <url>:latest"
  value       = module.registry.backend_repository_url
}

output "bot_ecr_url" {
  description = "Push bot image here: docker push <url>:latest"
  value       = module.registry.bot_repository_url
}

# output "ecs_cluster_name" {
#   description = "ECS cluster name"
#   value       = module.compute.ecs_cluster_name
# }

# ─── Database ─────────────────────────────────────────────────────────────────
output "db_secret_arn" {
  description = "Secrets Manager ARN — use in ECS task environment"
  value       = module.database.db_secret_arn
}
