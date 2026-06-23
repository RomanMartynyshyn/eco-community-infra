resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "ecodb"
  username          = "postgres"

  # Password sourced from Secrets Manager — generated in secrets.tf
  password = jsondecode(aws_secretsmanager_secret_version.main.secret_string)["DB_PASSWORD"]

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  multi_az               = false # true = ~$50/mo extra — вмикай тільки для prod
  publicly_accessible    = false

  # Prevents apply from failing on destroy if no final snapshot is configured
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-db"
  }
}
