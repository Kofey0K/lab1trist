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
  public_key = "ssh-rsa MIIEowIBAAKCAQEA0ENH84TwJPq/g9Y2CxUfMJecO4vIU9g0m4a98MkANpovwt+z/OoR+NwI4IRt3s1rMZXgUHueiLc9SMnwsEZoaHkCVsoWEtqULjHqEpklhYdepxIl5Wv/+KT2F8/R0XjAqKc2ei+K0xyTg2su7uQtoFLgck3IU1NbomljZWk0tD6OALjbRMzp3Im+20Q4p9bDGDB14xEuGNS6qAo0D/IYSo0XD/Yx5HMR8JtatE2hktcGrdTVwzRYqwvavNgFrB8TZjXzmfzpqajVTYDOU0qwZzPSBW3G/0qjBvA35Eg1uRbuDYDwaQpp4+hJ7NfdsIS5n4RuuEscljZs+ucd2uSfwQIDAQABAoIBAAHXBlS1cPWyrWx5wQJ6Dkt8m2m/Q2bSOyzAlP8Cl5jj5dYf6dQrMTt0njN1mA7m27KVc2TiorTsgYMaHaFBDf0WTJn9sRI7kiGSWVIOvlEesAxj0afkO1+z/WSadm0WVwVmbMnJj71rvDXmBYUgyPJoqQj5fPKXgvC9Y55qvod1HfEfVVbi+oOU2+KK41yIM5BR5wDomIyPOLbBs88A956GIIQhFOI2axr89jCLaGCC2f9vI9B7NDcTU9df43RWqkmoXOTaVg5UyaR6k0q+wArjwI1mqyG6oPdmLjW9u6EBqPKoUi/euxhzvBJrv8NiOPLTydYHhO3t5H7DPgroGf0CgYEA7eSIxTCn21d3VXFgGYhGtRlRrIkKeG8HOXgDuOfkz2cdWlaP2U+s8HTNDY1m5O1eyrS7yiKRYyqD5FJ5PvCGUtm5dOoadEjsiV3xVrznB6oBOCPxm3Ba5jJiSpnyRRwiX4O96sg2VZKXpdlbU2jMCHN0tLod7N9SmFUqWRgChRMCgYEA4B1kfzYMj9HW9WUgvMg2QfAS0POgX2CCOD5uk5qqaWPFDYXY2uID49igPXQDEZLMdVM73V6/1RooDfsR61SGWPHkJ31g84kKIAvC216pK1SAOPvqeFCzTIOT2PyLRoD4/5YF2qfwZEOvBwwMmM/oS+ZRwSXP6ahgxOH8FLkXplsCgYAk7juFUT5dwMBX1Vfz3sILTzjsrgGgHKxkcYsyY12UDQ/zfEislb/lPFyw4+i7VVZH5bLZeHBVkr4S7fLAoJpZtk8iJU2iC8gcsybKLl03RV8XFg1l8hVKczvrFOcVb36ukUckcZxtwGomZw3UbwptrW7Kt7H5mdm6qE4AsseBXQKBgCTDzZuswyzIsKm6+D7f3T694mhSvwlGbLZLT5p5MeFuE4JfZa6qixbSj57lLCey3EWW7OgoxfFwhAefG1ZunEd1DweHYuMwpO+S3llcUwYfq5Uthk5Mds1jfFqJO1PKjo5nDvjKuf3IuKrASES9Po9M7jZwPIZJL+68X70KjB2nAoGBAMMLzGMLQtto9eR8GQc0ygbXNac/43/MnVF0tHqeGsH4tJ64POn9s1wMdPGXz+EtKGeNMhRvrXlfPKIBfAQSXnbPXmkjG+C7nF2LyKRakYdL44FO0gX2cKub0vMUS/E5JeCf/n5dhhvb54E27Vj4Rk00JzMVqN9qElTg85ai3Cux" 
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