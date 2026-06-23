# CloudWatch Log Groups для ECS контейнерів
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-backend-logs"
  }
}

resource "aws_cloudwatch_log_group" "bot" {
  name              = "/ecs/${var.project_name}-bot"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-bot-logs"
  }
}
