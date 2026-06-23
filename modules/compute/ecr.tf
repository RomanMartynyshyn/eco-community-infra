resource "aws_ecr_repository" "backend" {
  name = "${var.project_name}-ecr-backend"
}

resource "aws_ecr_repository" "bot" {
  name = "${var.project_name}-ecr-bot"
}
