variable "bucket_name" {
  description = "Unique name for the S3 bucket."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "domain_name" {
  description = "Custom domain name for CloudFront (must have a Route53 public hosted zone, e.g. example.com)"
  type        = string
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