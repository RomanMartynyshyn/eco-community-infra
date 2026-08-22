terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # configuration_aliases = [aws.us_east_1]
      # Розкоментуй коли підключиш власний домен (ACM потребує us-east-1)
    }
  }
}
