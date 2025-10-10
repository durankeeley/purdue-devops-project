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
}

resource "aws_instance" "jenkins_server" {
  instance_type = "t3.micro"
  ami = "ami-0c462b53550d4fca8"

  key_name               = aws_key_pair.deployer_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.public_a.id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install docker ansible -y
              EOF
  tags = {
    Name = "Project-Jenkins-Server"
  }

  provisioner "local-exec" {
    command = "echo [${aws_instance.jenkins_server.tags.Name}] ${aws_instance.jenkins_server.public_ip} > ../ansible/inventory"
  }
}
