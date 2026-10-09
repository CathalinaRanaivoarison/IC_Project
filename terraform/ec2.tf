data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "jenkins" {
  ami = data.aws_ami.ubuntu.id
  #instance_type = "t2.medium"
  instance_type = "t3.small"

  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = aws_key_pair.main.key_name

  tags = {
    Name = "ic-project-jenkins"
  }
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  #instance_type = "t2.micro"
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.main.key_name

  tags = {
    Name = "ic-project-web"
  }
}

resource "aws_instance" "odoo" {
  ami = data.aws_ami.ubuntu.id
  #instance_type = "t2.micro"
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.odoo.id]
  key_name               = aws_key_pair.main.key_name

  tags = {
    Name = "ic-project-odoo"
  }
}