variable "aws_region" {
  description = "A região onde a instância EC2 será criada"
  default     = "us-east-1"  # Defina a região AWS padrão
}

variable "instance_type" {
  description = "O tipo da instância EC2"
  default     = "t2.nano"  # Estancia mais barata para testes
}

variable "ami" {
  description = "ID da AMI para instância EC2"
  default     = "ami-0c55b159cbfafe1f0"  # AMI padrão
}