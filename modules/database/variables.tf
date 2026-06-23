variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "db_subnet_ids" {
  description = "List of subnet IDs for the RDS subnet group."
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Security group ID for the RDS instance."
  type        = string
}