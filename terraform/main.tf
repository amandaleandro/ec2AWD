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

resource "aws_instance" "ec2_instance" {
  ami           = "ami-0ac80df6eff0e70b5" 
  instance_type = "t2.nano"
  key_name      = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.allow_ssh.name] # Associa o Security Group

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io",
      "sudo usermod -aG docker ubuntu",
      "sudo systemctl start docker",
      "sudo systemctl enable docker"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }

  tags = {
    Name = "terraform-example"
  }
}

# Output para exibir o IP público da instância
output "instance_ip" {
  value = aws_instance.ec2_instance.public_ip
}
