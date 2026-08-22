resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-backend"
      image = "${var.backend_repository_url}:latest"

      portMappings = [
        {
          name          = "backend-port"
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      # Змінні середовища БЕЗ секретів (не чутливі)
      environment = [
        {
          name  = "DB_HOST"
          value = var.db_address
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "CREATE_DUMMY_USERS"
          value = "true"
        },
        {
          name  = "AWS_REGION"
          value = "eu-north-1"
        },
        {
          name  = "S3_MEDIA_BUCKET"
          value = var.media_bucket_name
        },
        {
          name  = "MEDIA_BASE_URL"
          value = var.media_bucket_url
        }
      ]

      # Секрети — ECS тягне з Secrets Manager і вставляє як env vars
      # Значення в AWS Console: Secrets Manager → eco-project-db-secret / eco-project-app-secrets
      secrets = [
        {
          # DB_PASSWORD береться з db-secret (автогенерований Terraform)
          name      = "DB_PASSWORD"
          valueFrom = "${var.db_secret_arn}:DB_PASSWORD::"
        },
        {
          # SECRET_KEY заповнюється вручну в AWS Console
          name      = "SECRET_KEY"
          valueFrom = "${var.app_secret_arn}:SECRET_KEY::"
        },
        {
          # BOT_SECRET_TOKEN заповнюється вручну в AWS Console
          name      = "BOT_SECRET_TOKEN"
          valueFrom = "${var.app_secret_arn}:BOT_SECRET_TOKEN::"
        },
        {
          name      = "FRONTEND_URL"
          valueFrom = "${var.app_secret_arn}:FRONTEND_URL::"
        }
      ]

      # DATABASE_URL збирається з окремих env vars у run-backend.sh
      # (або можна задати як окремий секрет якщо потрібно)

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-backend"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "bot" {
  family                   = "${var.project_name}-bot"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-bot"
      image = "${var.bot_repository_url}:latest"

      environment = [
        {
          name  = "BACKEND_URL"
          value = "http://backend.eco.local/api"
        }
      ]

      # Telegram Bot API key зберігається окремо в Secrets Manager
      # Додай у AWS Console → Secrets Manager → eco-project-app-secrets
      # { "BOT_API_KEY": "<твій telegram bot token>" }
      secrets = [
        {
          name      = "BOT_API_KEY"
          valueFrom = "${var.app_secret_arn}:BOT_API_KEY::"
        },
        {
          name      = "BOT_SECRET_TOKEN"
          valueFrom = "${var.app_secret_arn}:BOT_SECRET_TOKEN::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-bot"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
