resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ─────────────────────────────────────────
# CloudFront Distribution
# ─────────────────────────────────────────
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "CloudFront for ${var.bucket_name}"
  price_class         = var.price_class
  # aliases прибрані — використовуємо безкоштовний *.cloudfront.net домен
  # aliases = [var.domain_name]  # Розкоментуй коли буде власний домен

  # ── Origin 1: S3 (статичні файли фронтенду) ──────────────────────────────
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # ── Origin 2: ALB (FastAPI бекенд) ───────────────────────────────────────
  # CloudFront звертається до ALB по HTTP (внутрішньо),
  # але браузер отримує HTTPS від CloudFront — mixed-content не виникає
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # ALB слухає тільки HTTP (порт 80)
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ── Cache behavior для /api/* → ALB ──────────────────────────────────────
  # Виконується ПЕРЕД default_cache_behavior (більш специфічний шлях)
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "ALB-backend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false

    # Передаємо всі заголовки, cookies і query strings до бекенду
    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type", "Accept", "Origin", "X-Bot-User-Id"]
      cookies {
        forward = "all"
      }
    }

    # API відповіді НЕ кешуємо
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # ── Cache behavior для /health ────────────────────────────────────────────
  ordered_cache_behavior {
    path_pattern           = "/health"
    target_origin_id       = "ALB-backend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # ── Default behavior: S3 (всі інші шляхи — статика) ──────────────────────
  default_cache_behavior {
    target_origin_id       = "S3-${var.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Return index.html for SPA routing
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Використовуємо дефолтний CloudFront сертифікат (для *.cloudfront.net)
    # Коли буде власний домен — замінити на acm_certificate_arn
    cloudfront_default_certificate = true
  }

  tags = {
    Environment = var.environment
  }
}

