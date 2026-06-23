resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
}

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

  depends_on = [var.alb_listener_arn]
}

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
}