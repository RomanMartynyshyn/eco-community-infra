# ─── DB Password (auto-generated) ────────────────────────────────────────────
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project_name}-db-secret"
  recovery_window_in_days = 0
}

resource "random_password" "db_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    "DB_PASSWORD" = random_password.db_master_password.result
  })
}

# ─── App Secrets (заповнюються вручну після terraform apply) ──────────────────
# Terraform створює порожній секрет.
# Після apply відкрий AWS Console → Secrets Manager → eco-project-app-secrets
# → "Retrieve secret value" → "Edit" і додай:
# {
#   "SECRET_KEY":        "<згенеруй: python -c 'import secrets; print(secrets.token_hex(32))'>",
#   "BOT_SECRET_TOKEN":  "<твій токен між ботом і бекендом>",
#   "FRONTEND_URL":      "https://ecoproject.com"
# }
resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project_name}-app-secrets"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-app-secrets"
  }
}

# Placeholder — реальні значення заповнюються вручну в AWS Console
resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    "SECRET_KEY"       = "CHANGE_ME"
    "BOT_SECRET_TOKEN" = "CHANGE_ME"
    "FRONTEND_URL"     = "http://localhost"
  })

  # Terraform не буде перезаписувати якщо ти змінив значення вручну в Console
  lifecycle {
    ignore_changes = [secret_string]
  }
}
