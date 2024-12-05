resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh8"
  description = "Allow SSH inbound traffic"
  vpc_id      = "vpc-0859a6c0d7f723e53" # vpc id da sua conta

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

  tags = {
    Name = "allow_ssh"
  }
}
