# ─── Service Discovery Namespace (Cloud Map) ──────────────────────────────────
# Створює приватний простір імен для внутрішньої комунікації між контейнерами.
resource "aws_service_discovery_http_namespace" "main" {
  name        = "eco.local"
  description = "Private namespace for EcoCommunity internal services"
}

# ─── ECS Cluster ──────────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
}

# ─── ECS Service: Backend ─────────────────────────────────────────────────────
resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "${var.project_name}-backend"
    container_port   = 8000
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  # Service Connect: дозволяє іншим сервісам у кластері звертатися до бекенду
  # за внутрішнім іменем http://backend.eco.local/
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
    
    service {
      port_name      = "backend-port"
      discovery_name = "backend"
      
      client_alias {
        port     = 80 # клієнти можуть підключатися на стандартний 80-й порт
        dns_name = "backend.eco.local"
      }
    }
  }

  depends_on = [var.alb_listener_arn]
}

# ─── ECS Service: Bot ─────────────────────────────────────────────────────────
resource "aws_ecs_service" "bot" {
  name            = "bot-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.bot.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.private_subnet_ids[0]]
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  # Service Connect: дозволяє боту розпізнавати внутрішні адреси (backend.eco.local)
  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn
  }
}