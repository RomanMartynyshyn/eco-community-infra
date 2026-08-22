data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ─── Execution Role (використовується ECS агентом) ────────────────────────────
# Права: pull образу з ECR, запис логів у CloudWatch, читання Secrets Manager
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

# ─── Task Role (використовується самим контейнером під час runtime) ───────────
# Права: лише S3 для завантаження/читання медіафайлів
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# Базові права ECS: тягнути образ з ECR, писати логи в CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Читання секретів з Secrets Manager (для secrets[] блоку в task definition)
resource "aws_iam_role_policy_attachment" "ecs_secrets" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# S3 доступ для бекенду: запис фото маркерів у media bucket
resource "aws_iam_policy" "ecs_s3_media" {
  name        = "${var.project_name}-ecs-s3-media-policy"
  description = "Allow ECS backend to read/write media files in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MediaBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",    # завантаження фото
          "s3:GetObject",    # читання фото (для перевірки)
          "s3:DeleteObject", # видалення старих фото
          "s3:ListBucket"    # перевірка існування файлів
        ]
        Resource = [
          "arn:aws:s3:::${var.media_bucket_name}",
          "arn:aws:s3:::${var.media_bucket_name}/*"
        ]
      }
    ]
  })
}

# S3 policy прикріплюємо до task role (не до execution role)
# Контейнер backend отримує лише S3-доступ під час runtime
resource "aws_iam_role_policy_attachment" "ecs_s3_media" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_s3_media.arn
}
