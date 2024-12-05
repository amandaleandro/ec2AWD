output "instance_ip" {
  description = "O IP público da instância EC2"  #Descrição do output
  value       = aws_instance.ec2_instance.public_ip # Acesse o IP público da instância EC2
}
