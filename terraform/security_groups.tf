variable "sg_name_prefix" {
  description = "Prefix for the dynamic security group name"
  type        = string
  default     = "dynamic-sg"
}

resource "aws_security_group" "dynamic_sg" {
  name        = "${var.sg_name_prefix}-${timestamp()}"
  description = "Dynamic Security Group based on allowed ports"
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
