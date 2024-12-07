provider "aws" {
  region = "us-east-1"
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
  ami              = "ami-0ac80df6eff0e70b5" # Certifique-se de que a AMI seja válida
  instance_type    = "t2.nano"
  key_name         = aws_key_pair.deployer.key_name
  security_groups  = [aws_security_group.allow_ssh.name]
  associate_public_ip_address = true

  # Provisionamento para instalar Docker, copiar código, e rodar a aplicação
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",  # Instalar Docker
      "sudo usermod -aG docker ubuntu",  # Adicionar o usuário ao grupo Docker
      "sudo systemctl start docker",  # Iniciar o serviço Docker
      "sudo systemctl enable docker",  # Habilitar Docker no boot
      "mkdir -p /home/ubuntu/app",  # Criar o diretório para o código da aplicação
      # Copiar o código da aplicação para a instância
      "echo '${file("src/requirements.txt")}' > /home/ubuntu/app/requirements.txt",  # Copiar requirements.txt
      "echo '${file("src/app.py")}' > /home/ubuntu/app/app.py",  # Copiar app.py
      "echo '${file("src/Dockerfile")}' > /home/ubuntu/app/Dockerfile",  # Copiar Dockerfile
      # Construir a imagem Docker e rodar a aplicação
      "cd /home/ubuntu/app",
      "sudo docker build -t my-python-app .",  # Construir a imagem Docker
      "sudo docker run -d -p 5000:5000 my-python-app"  # Rodar o container
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

# Output para exibir o IP público da instância
output "instance_ip" {
  value = aws_instance.ec2_instance.public_ip
}