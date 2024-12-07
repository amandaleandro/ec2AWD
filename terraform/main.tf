provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "ec2_role" {
  name               = "ec2_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iam:CreateRole",
      "Resource": "*"
    }
  ]
}
)
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "meu-bucket-terraform-unique"
  acl    = "private"
}

resource "aws_s3_bucket_object" "requirements_txt" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "requirements.txt"
  source = "path_to_local_file/requirements.txt"  # Caminho para o arquivo local
  acl    = "private"
}

resource "aws_s3_bucket_object" "app_py" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "app.py"
  source = "path_to_local_file/app.py"  # Caminho para o arquivo local
  acl    = "private"
}

resource "aws_s3_bucket_object" "dockerfile" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "Dockerfile"
  source = "path_to_local_file/Dockerfile"  # Caminho para o arquivo local
  acl    = "private"
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
