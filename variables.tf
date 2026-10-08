variable "region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "eco-project"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "Unique name for the frontend S3 bucket (CloudFront origin)"
  type        = string
  default     = "eco-project-bucket-unique-12345"
}

variable "media_bucket_name" {
  description = "Unique name for the media S3 bucket (marker photos)"
  type        = string
  default     = "eco-project-media-unique-12345"
}

variable "domain_name" {
  description = "Custom domain name for CloudFront (must have a Route53 public hosted zone, e.g. example.com)"
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe only
  # Options: PriceClass_All, PriceClass_200, PriceClass_100
}
