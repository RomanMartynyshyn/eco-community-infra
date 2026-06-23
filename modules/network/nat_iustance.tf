# ─────────────────────────────────────────────────────────────────────────────
# NAT Instance (replaces NAT Gateway to save ~$27/mo)
# source_dest_check MUST be false so the instance forwards packets it didn't
# originate — this is what makes it work as a NAT device.
#
# NOTE: Old "amzn-ami-vpc-nat-*" AMIs are NOT available in eu-north-1.
# Instead we use Amazon Linux 2 + user_data to enable NAT manually.
# ─────────────────────────────────────────────────────────────────────────────

# Latest Amazon Linux 2 AMI for the current region
data "aws_ami" "nat" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Security group: allow all traffic from the VPC in, all traffic out
resource "aws_security_group" "nat" {
  name   = "${var.project_name}-nat-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow all inbound from VPC (private subnets will route through here)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-nat-sg"
  }
}

resource "aws_instance" "nat" {
  ami                    = data.aws_ami.nat.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  source_dest_check      = false # MUST be false for NAT to work
  vpc_security_group_ids = [aws_security_group.nat.id]

  # Enable IP forwarding + iptables masquerade (NAT logic)
  user_data = <<-EOF
    #!/bin/bash
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    service iptables save
  EOF

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.project_name}-nat-instance"
  }
}
