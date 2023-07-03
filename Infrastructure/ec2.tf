data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}


resource "aws_instance" "k8s" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.medium"

  root_block_device {
    volume_size = 16
  }

  user_data = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo yum install docker -y
    sudo systemctl start docker
    sudo usermod -a -G docker ec2-user
    curl -sLo kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-amd64
    sudo install -o root -g root -m 0755 kind /usr/local/bin/kind
    rm -f ./kind
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f ./kubectl
    kind create cluster --config kind.yaml​
  EOF

  vpc_security_group_ids = [
    module.ec2_sg.security_group_id,
    module.dev_ssh_sg.security_group_id,
    aws_security_group.ec2_sg_K8.id
  ]
  iam_instance_profile = "LabInstanceProfile"

  tags = {
    Name = "Klaus-EC2-Assigment2"  
    project = "clo835"
  }

  key_name                = "Assignment2"
  monitoring              = true
  disable_api_termination = false
  ebs_optimized           = true
}

resource "aws_security_group" "ec2_sg_K8" {
  name        = "ec2_sg_K8"
  description = "Security group for EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 30001
    to_port     = 30001
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



resource "aws_key_pair" "k8s" {
  key_name   = "Assignment2"
  public_key = file("${path.module}/Assignment2.pub")
}

resource "aws_ecr_repository" "websrv_images" {
  name = "websrv-images"
}

resource "aws_ecr_repository" "mysql_images" {
  name = "mysql-images"
}