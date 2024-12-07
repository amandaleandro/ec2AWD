provider "aws" {
  region = "us-east-1"
}

# Criar o role IAM com a política de confiança adequada
resource "aws_iam_role" "ec2_role" {
  name               = "ec2_role_${random_string.suffix.result}"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

# Gerar um sufixo aleatório para garantir unicidade no nome de recursos
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Criar o bucket S3 com nome único
resource "aws_s3_bucket" "my_bucket" {
  bucket = "meu-bucket-terraform-unique-${random_string.suffix.result}"
  acl    = "private"
}

# Subir o arquivo requirements.txt para o bucket S3
resource "aws_s3_bucket_object" "requirements_txt" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "requirements.txt"
  source = "../src/requirements.txt"  # Caminho correto para o arquivo
  acl    = "private"
}

# Subir o arquivo app.py para o bucket S3
resource "aws_s3_bucket_object" "app_py" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "app.py"
  source = "../src/app.py"  # Caminho correto para o arquivo
  acl    = "private"
}

# Subir o Dockerfile para o bucket S3
resource "aws_s3_bucket_object" "dockerfile" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "Dockerfile"
  source = "../src/Dockerfile"  # Caminho correto para o arquivo
  acl    = "private"
}

# Gerar a chave privada e pública para SSH com Terraform
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Criar o par de chaves na AWS
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key${random_string.suffix.result}"
  public_key = tls_private_key.example.public_key_openssh
}

# Criar o Security Group para permitir acesso SSH
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
  ami                    = "ami-0ac80df6eff0e70b5"
  instance_type          = "t2.nano"
  key_name               = aws_key_pair.deployer.key_name
  security_groups        = [aws_security_group.allow_ssh.name]
  associate_public_ip_address = true

  # Instalar dependências e copiar arquivos do S3
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y awscli python3-pip
              mkdir -p /home/ubuntu/app
              aws s3 cp s3://${aws_s3_bucket.my_bucket.bucket}/requirements.txt /home/ubuntu/app/requirements.txt
              aws s3 cp s3://${aws_s3_bucket.my_bucket.bucket}/app.py /home/ubuntu/app/app.py
              aws s3 cp s3://${aws_s3_bucket.my_bucket.bucket}/Dockerfile /home/ubuntu/app/Dockerfile
              EOF

  # Provisionamento remoto para copiar os arquivos após a instância ser criada
  provisioner "remote-exec" {
    inline = [
      "aws s3 cp s3://${aws_s3_bucket.my_bucket.bucket}/requirements.txt /home/ubuntu/app/requirements.txt",
      "aws s3 cp s3://${aws_s3_bucket.my_bucket.bucket}/app.py /home/ubuntu/app/app.py",
      "aws s3 cp s3://${aws_s3_bucket.my_bucket.bucket}/Dockerfile /home/ubuntu/app/Dockerfile"
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
