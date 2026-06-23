variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "media_bucket_name" {
  description = "S3 media bucket name (for IAM policy)."
  type        = string
}