output "media_bucket_name" {
  description = "S3 bucket name for media files"
  value       = aws_s3_bucket.media.bucket
}

output "media_bucket_arn" {
  description = "S3 bucket ARN (needed for IAM policy)"
  value       = aws_s3_bucket.media.arn
}

output "media_bucket_url" {
  description = "Base URL for accessing media files publicly"
  value       = "https://${aws_s3_bucket.media.bucket}.s3.eu-north-1.amazonaws.com"
}
