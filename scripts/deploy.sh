#!/bin/bash

# Captura o IP da instância EC2 utilizando o output do Terraform
EC2_PUBLIC_IP=$(terraform output -raw instance_ip)

# Verifica se o IP foi obtido corretamente
if [ -z "$EC2_PUBLIC_IP" ]; then
  echo "Erro: Não foi possível obter o IP público da instância EC2"
  exit 1
fi

# Exibe o IP público obtido
echo "Deploying to EC2 instance with IP: $EC2_PUBLIC_IP"

# Exec