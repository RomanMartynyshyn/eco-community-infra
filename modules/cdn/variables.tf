variable "bucket_name" {
  description = "Unique name for the S3 bucket."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "domain_name" {
  description = "Custom domain name for CloudFront (optional). Leave null to use *.cloudfront.net"
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe only
}

variable "project_name" {
  description = "The name of the project (used for tagging)."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name — used as second CloudFront origin for /api/* requests"
  type        = string
}