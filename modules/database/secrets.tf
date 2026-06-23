resource "aws_secretsmanager_secret" "main" {
  name                    = "${var.project_name}-db-secret"
  recovery_window_in_days = 0 # Дозволяє видалити без затримки (зручно для dev)
}

resource "random_password" "db_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id
  secret_string = jsonencode({
    "DB_PASSWORD" = random_password.db_master_password.result
  })
}
