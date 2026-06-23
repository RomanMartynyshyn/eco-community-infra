# ─────────────────────────────────────────────────────────────────────────────
# ACM Certificate for CloudFront
#
# IMPORTANT: CloudFront requires ACM certificates to live in us-east-1.
# This uses the `aws.us_east_1` provider alias defined in main.tf.
#
# Prerequisites:
#   - var.domain_name must have a public hosted zone in Route53 in this account.
#   - The terraform caller must have permissions to create Route53 records.
# ─────────────────────────────────────────────────────────────────────────────

# Look up the existing Route53 hosted zone for the domain
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Request a certificate in us-east-1 covering both apex and www
resource "aws_acm_certificate" "cdn" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  # Ensures zero-downtime cert renewal
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-cdn-cert"
    Environment = var.environment
  }
}

# Add the DNS validation CNAME records to Route53
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cdn.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Wait for ACM to validate and issue the certificate
resource "aws_acm_certificate_validation" "cdn" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cdn.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Alias record — points your domain at the CloudFront distribution
resource "aws_route53_record" "cdn_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cdn_alias_www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
