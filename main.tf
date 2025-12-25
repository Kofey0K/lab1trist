terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"

}

provider "aws" {
  region = "eu-north-1"
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "web_server_sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH key 
resource "aws_key_pair" "deployer" {
  key_name   = "my-lab-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCd9t2hS05YWClI157W0MqYBD87jpiv5ncV9GKSGaGAuSP9bSLF8h4OZHKXZYwF7B+Bq8jyHkM8nS2+xE/kfyrwr4nHPoBU/VFsyn7FnZfut2KEp0D89jRuWlfJlVdAK0cdJhCgY+vNPv/WKo/eKo6qHW1HWPq6yZCaQ05CZpMmk1S2pTyV7ljzNakUIvrfzkA52tjN6pSfD/mQv5G+jfIzBjihw7wkmljDNfb0xNbWzfuDUKvQG0V8yERVYVc+Fv8Gq8/wHMQIA4uqJF09z2MBJ4+5u4DnJ9/rfF3s3Es65K+lIxg32uFd8715pelPpYZlqCfDEIvSgwNOX56DMAjoPM8DqgWu1+eIAPF3VQVNedAAbIn1OOHclerEdD4U7mHdp9kyNPYwzGGcRlmVw4wFwc+qBuvhp57XAGGX7VfTLQ1HsPewo5rIc1/9+Aborayx4H+PCIc929XQmm8pLY2yRcnQZCrczMN1y3lWkib2uCvgkoMlhMvUoCwtBV1ZnoGLe0FLiUpWiLdmUschXijHoEKqvU/G92C7WRLWdktMTDZaMBYAkBsi+hQ+xvnB34JY5EmLpGPrnPfaf3JiEbJtlKNCUjPo4eEqA43EIG6X5/g7rVxoyP0rXuJgZX1+apW3SAPjZdzgk3KG3qz4a6I7MhXB1jyq0T7yDzmraPkBYQ== minin@DESKTOP-90SB263" 
}

# EC2 instance
resource "aws_instance" "app_server" {
  ami           = "ami-0fa91bc90632c73c9" 
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # User Data
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              docker run -d --name my-website -p 80:80 --restart unless-stopped hexpertkofeyok/lab1:latest

              # Watchtower
              docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock --interval 30 containrrr/watchtower
              EOF

  tags = {
    Name = "TerraformLabServer"
  }
}

# IP
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}