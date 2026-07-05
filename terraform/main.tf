provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "icgroup_sg" {
  name        = "icgroup-sg"
  description = "Autoriser les flux pour IC Group"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins (Interface Web)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # pgAdmin
  ingress {
    from_port   = 5050
    to_port     = 5050
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Odoo ERP
  ingress {
    from_port   = 8069
    to_port     = 8069
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

resource "aws_instance" "jenkins" {
  ami                    = var.instance_ami
  instance_type          = "t2.medium"
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.icgroup_sg.id]

  tags = { Name = "Serveur-1-Jenkins" }
}

resource "aws_instance" "webapp" {
  ami                    = var.instance_ami
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.icgroup_sg.id]

  tags = { Name = "Serveur-2-Webapp" }
}

resource "aws_instance" "odoo" {
  ami                    = var.instance_ami
  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.icgroup_sg.id]

  tags = { Name = "Serveur-3-Odoo" }
}