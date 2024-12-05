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
  key_name   = "deployer-key"
  public_key = tls_private_key.example.public_key_openssh
}

# Criar a instância EC2
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0f2ad13ff5f6b6f7c" # AMI padrão
  instance_type = "t2.nano"
  key_name      = aws_key_pair.deployer.key_name  # Chave pública para acesso SSH

  tags = {
    Name = "terraform-example"
  }

  # Provisionamento remoto via SSH para instalar Docker
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo usermod -aG docker ubuntu",  # Adicionar o usuário ubuntu ao grupo docker
      "sudo systemctl start docker",
      "sudo systemctl enable docker"
    ]

    # Conexão SSH para a instância EC2
    connection {
      type        = "ssh"
      user        = "ubuntu"  # Usuário padrão do Ubuntu
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }
}

output "instance_ip" {
  value = aws_instance.ec2_instance.public_ip
}
