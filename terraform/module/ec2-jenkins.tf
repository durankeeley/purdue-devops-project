locals {
  jenkins_server = {
    name = "ec2-jenkins-server"
    # instance_type = "t3.micro"
    instance_type = "t4g.small" # ARM-based instance for cost efficiency
    # ami = "ami-0c462b53550d4fca8" # t3.micro
    ami = "ami-0e257f30995bbaa53" # Amazon Linux 2 ARM64 (for t4g.small)
  }
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "project-deployer-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_security_group" "jenkins_sg" {
  name   = "project-jenkins-sg-secure"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ip}"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.allowed_ip}"]
  }
}

resource "random_password" "jenkins_admin_password" {
  count = var.jenkins_admin_password == null ? 1 : 0

  length           = 16
  special          = true
  override_special = "!@#$%&*"
}

resource "aws_ssm_parameter" "jenkins_admin_password" {
  name  = "/jenkins/admin_password"
  type  = "SecureString"
  value = var.jenkins_admin_password != null ? var.jenkins_admin_password : random_password.jenkins_admin_password[0].result
}

resource "aws_instance" "jenkins_server" {
  instance_type = local.jenkins_server.instance_type
  ami           = local.jenkins_server.ami

  key_name               = aws_key_pair.deployer_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.public_a.id

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = local.jenkins_server.name
  }
}
