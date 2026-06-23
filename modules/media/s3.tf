# ─────────────────────────────────────────────────────────────────────────────
# S3 Bucket для медіа файлів (фото маркерів)
#
# Доступ: публічний для читання (GET) — щоб браузер міг показувати фото
#         запис — тільки через ECS backend (IAM роль)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "media" {
  bucket = var.media_bucket_name

  tags = {
    Name        = var.media_bucket_name
    Environment = var.environment
    Purpose     = "marker-photos"
  }
}

# CORS — дозволяємо браузеру отримувати фото напряму з S3
resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3600
  }
}

# Публічний доступ на читання (фото мають бути доступні всім)
resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = false # дозволяємо публічну bucket policy
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# Bucket policy — публічний GET для всіх (тільки читання фото)
resource "aws_s3_bucket_policy" "media_public_read" {
  bucket     = aws_s3_bucket.media.id
  depends_on = [aws_s3_bucket_public_access_block.media]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.media.arn}/uploads/*"
      }
    ]
  })
}

# Lifecycle rule — автоматичне видалення temp файлів через 1 день
resource "aws_s3_bucket_lifecycle_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    id     = "cleanup-temp-files"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = 1
    }
  }
}
