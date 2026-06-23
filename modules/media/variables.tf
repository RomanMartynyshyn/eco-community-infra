variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "media_bucket_name" {
  description = "Unique name for the media S3 bucket (photos from markers)."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}
