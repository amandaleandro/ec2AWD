provider "aws" {
  region = "us-east-1"
}

# Gerar um sufixo aleatório para garantir unicidade no nome de recursos
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
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

# Criar a política para acessar o bucket S3
resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3_access_policy_${random_string.policy_suffix.result}"  # Nome único para a política
  description = "S3 access policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}/*"
      },
    ]
  })
}

# Anexar a política ao role da EC2
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Criar o perfil IAM (IAM Instance Profile)
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile_${random_string.suffix.result}"
  role = aws_iam_role.ec2_role.name
}

# Criar o bucket S3 com nome único
resource "aws_s3_bucket" "my_bucket" {
  bucket = "meu-bucket-terraform-unique-${random_string.suffix.result}"
  acl    = "private"
}

# Subir os arquivos para o bucket S3
resource "aws_s3_bucket_object" "requirements_txt" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "requirements.txt"
  source = "../src/requirements.txt"  # Caminho correto para o arquivo
  acl    = "private"
}

resource "aws_s3_bucket_object" "app_py" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "app.py"
  source = "../src/app.py"  # Caminho correto para o arquivo
  acl    = "private"
}

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

# Salvar a chave privada localmente
resource "local_file" "ssh_private_key" {
  filename      = "${path.module}/deployer-key-${random_string.suffix.result}.pem"
  content       = tls_private_key.example.private_key_pem
  file_permission = "0600"  # Permissões adequadas para a chave privada
}

# Criar o par de chaves na AWS
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${random_string.suffix.result}"
  public_key = tls_private_key.example.public_key_openssh
}

# Criar o Security Group para permitir acesso SSH
resource "aws_security_group" "allow_ssh" {
  name_prefix = "allow_ssh_"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Qualquer IP pode acessar
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
  ami                    = "ami-0ac80df6eff0e70b5" # Substitua com a AMI correta
  instance_type          = "t2.nano"
  key_name               = aws_key_pair.deployer.key_name
  security_groups        = [aws_security_group.allow_ssh.name]
  associate_public_ip_address = true
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  # Provisionamento remoto com curl
  provisioner "remote-exec" {
    inline = [
      "set -e",   
      "set -x",   
      "echo 'Atualizando pacotes...'",
      "sudo apt-get update -y",

      "echo 'Instalando curl...'",
      "sudo apt-get install -y curl",
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "echo 'Criando diretório /home/ubuntu/app...'",
      "mkdir -p /home/ubuntu/app",

      "echo 'Baixando arquivos do S3...'",
      "curl -o /home/ubuntu/app/requirements.txt https://s3.us-east-1.amazonaws.com/${aws_s3_bucket.my_bucket.bucket}/requirements.txt",
      "curl -o /home/ubuntu/app/app.py https://s3.us-east-1.amazonaws.com/${aws_s3_bucket.my_bucket.bucket}/app.py",
      "curl -o /home/ubuntu/app/Dockerfile https://s3.us-east-1.amazonaws.com/${aws_s3_bucket.my_bucket.bucket}/Dockerfile"
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

# Output para obter o IP público da instância EC2
output "instance_ip" {
  value = aws_instance.ec2_instance.public_ip
}
