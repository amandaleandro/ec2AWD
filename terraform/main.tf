provider "aws" {
  region = "us-east-1"
}
resource "aws_iam_role" "ec2_role" {
  name               = "ec2_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

# Gerar a chave privada e pública com Terraform
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Criar o par de chaves na AWS
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key${random_string.suffix.result}"
  public_key = tls_private_key.example.public_key_openssh
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Criar Security Group para permitir acesso SSH
resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh_"
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

# Criar Instância EC2
resource "aws_instance" "ec2_instance" {
  ami              = "ami-0ac80df6eff0e70b5"
  instance_type    = "t2.nano"
  key_name         = aws_key_pair.deployer.key_name
  security_groups  = [aws_security_group.allow_ssh.name]
  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [
      "echo '${file("src/requirements.txt")}' > /home/ubuntu/app/requirements.txt",
      "echo '${file("src/app.py")}' > /home/ubuntu/app/app.py",
      "echo '${file("src/Dockerfile")}' > /home/ubuntu/app/Dockerfile",
      "sudo docker build -t my-python-app .",
      "sudo docker run -d -p 5000:5000 my-python-app"
    ]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }

  tags = {
    Name = "terraform-deployer"
  }
}

# Adicionar templates
data "template_file" "requirements_txt" {
  template = file("${path.module}/src/requirements.txt")
}

data "template_file" "app_py" {
  template = file("${path.module}/src/app.py")
}

data "template_file" "dockerfile" {
  template = file("${path.module}/src/Dockerfile")
}
