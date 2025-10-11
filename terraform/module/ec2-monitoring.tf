locals {
  monitoring_server = {
    name = "ec2-monitoring-server"
    instance_type = "t4g.small"
    ami = "ami-0e257f30995bbaa53"
  }
}

resource "aws_security_group" "monitoring_sg" {
  name        = "project-monitoring-sg"
  description = "Allow inbound traffic for SSH, Grafana and Prometheus"
  vpc_id      = aws_vpc.main.id

  # Grafana access from trusted
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ip}"]
  }

  # Prometheus access from trusted
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ip}"]
  }

  # SSH access from trusted
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "monitoring_server" {
  instance_type = local.monitoring_server.instance_type

  ami                    = local.monitoring_server.ami
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  subnet_id              = aws_subnet.public_a.id
  key_name               = aws_key_pair.deployer_key.key_name

  iam_instance_profile = aws_iam_instance_profile.monitoring_profile.name

  metadata_options {
    http_tokens = "required"
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = local.monitoring_server.name
  }
}

