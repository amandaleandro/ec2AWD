Aqui está o **README** atualizado, agora incluindo a parte relacionada à aplicação Python:

```markdown
# Terraform EC2 Deployment with CI/CD Pipeline

Este repositório contém uma infraestrutura criada com **Terraform** para provisionar uma instância EC2 na **AWS**, juntamente com um **pipeline GitHub Actions** para automatizar o processo de criação e deploy da aplicação Python nessa instância.

## Estrutura do Repositório

```bash
my-terraform-project/
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml    # Pipeline de deploy usando GitHub Actions
├── terraform/
│   ├── main.tf                     # Definição dos recursos Terraform (EC2, VPC, etc.)
│   ├── variables.tf                # Variáveis usadas no Terraform
│   ├── outputs.tf                  # Outputs, como o IP da instância EC2
│   └── provider.tf                 # Configuração do provider AWS
├── src/
│   ├── app.py                      # Arquivo principal da aplicação Python
│   ├── Dockerfile                  # Dockerfile para containerizar a aplicação
│   └── requirements.txt            # Dependências da aplicação Python
└── scripts/
    └── deploy.sh                   # Script de deploy rodado via SSH no EC2
```

### Descrição dos Arquivos:

- **`.github/workflows/terraform-deploy.yml`**: Pipeline automatizado usando GitHub Actions para rodar o Terraform e fazer deploy na instância EC2 via SSH.
- **`terraform/main.tf`**: Arquivo principal do Terraform que define os recursos AWS, incluindo a instância EC2.
- **`terraform/variables.tf`**: Declaração das variáveis de entrada para o Terraform.
- **`terraform/outputs.tf`**: Outputs definidos no Terraform, como o IP público da instância EC2.
- **`terraform/provider.tf`**: Configuração do provedor AWS.
- **`src/app.py`**: Arquivo principal da aplicação Python que será executado no container.
- **`src/Dockerfile`**: Dockerfile para criar a imagem Docker da aplicação.
- **`src/requirements.txt`**: Arquivo que lista as dependências Python da aplicação.
- **`scripts/deploy.sh`**: Script que será executado via SSH na instância EC2 após o provisionamento, para configurar o ambiente e rodar a aplicação.

## Como Usar Este Repositório

### Pré-requisitos:

1. **Conta AWS**: Você deve ter uma conta AWS com as permissões necessárias para criar instâncias EC2 e outros recursos.
2. **GitHub Actions**: O pipeline é configurado para rodar automaticamente quando houver um push para a branch `main`.
3. **Terraform**: Você pode rodar o Terraform localmente ou deixar o GitHub Actions automatizar tudo para você.
4. **Docker**: A aplicação será empacotada em um container Docker, por isso, certifique-se de ter o Docker configurado.

### Configuração no GitHub Actions:

1. **Credenciais AWS**:
   - No seu repositório GitHub, vá em **Settings > Secrets** e adicione os seguintes secrets:
     - `AWS_ACCESS_KEY_ID`: Chave de acesso da AWS.
     - `AWS_SECRET_ACCESS_KEY`: Chave secreta de acesso da AWS.
     - `AWS_SSH_PRIVATE_KEY`: Chave privada SSH para acessar a instância EC2.
  
2. **Pipeline de GitHub Actions**:
   - O pipeline `terraform-deploy.yml` automatiza a criação da instância EC2 e o deploy da sua aplicação via SSH. Ele é disparado automaticamente com qualquer push para a branch `main`.

### Estrutura da Aplicação Python

A aplicação Python no diretório `src/` tem a seguinte estrutura:

- **`app.py`**: Arquivo Python principal da aplicação. Este arquivo contém a lógica de execução da aplicação, que será executada dentro de um container Docker.
  
- **`Dockerfile`**: Arquivo utilizado para criar a imagem Docker da aplicação. Ele usa a imagem base do Python, instala as dependências listadas no `requirements.txt` e define o comando para rodar a aplicação.

```dockerfile
# Usar uma imagem base do Python
FROM python:3.9-slim

# Definir o diretório de trabalho no container
WORKDIR /app

# Copiar os arquivos do diretório local para o container
COPY requirements.txt .

# Instalar as dependências do Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar o restante do código Python
COPY . .

# Rodar o script Python
CMD ["python", "app.py"]
```

- **`requirements.txt`**: Lista de dependências do Python necessárias para rodar a aplicação.

### Rodando Localmente

Caso queira rodar o Terraform e a aplicação localmente, siga os passos abaixo:

1. **Instalar o Terraform**:
   - Baixe e instale o Terraform em sua máquina: [Download Terraform](https://www.terraform.io/downloads.html).

2. **Configurar as credenciais da AWS**:
   - Você deve ter as variáveis de ambiente `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` configuradas em sua máquina.
   
   Exemplo de configuração (em sistemas UNIX):
   ```bash
   export AWS_ACCESS_KEY_ID=your-access-key-id
   export AWS_SECRET_ACCESS_KEY=your-secret-access-key
   ```

3. **Inicializar o Terraform**:
   No diretório `terraform/`, execute o comando para inicializar o Terraform e baixar os plugins necessários.

   ```bash
   terraform init
   ```

4. **Criar o plano de execução** (opcional):
   Para verificar o que será criado antes de aplicar as alterações, execute:

   ```bash
   terraform plan
   ```

5. **Aplicar o plano**:
   Para provisionar os recursos (instância EC2) na AWS, execute:

   ```bash
   terraform apply -auto-approve
   ```

   Ao final, o Terraform mostrará o **IP público** da instância EC2, que você pode usar para acessá-la.

6. **Acessar a instância EC2 via SSH**:
   Use o IP público retornado pelo Terraform para acessar a instância via SSH.

   ```bash
   ssh -i your-private-key.pem ec2-user@<public-ip>
   ```

7. **Construir e rodar a aplicação localmente**:
   Para rodar a aplicação Python localmente com Docker, execute os seguintes comandos na pasta `src`:

   ```bash
   docker build -t python-app .
   docker run -d -p 5000:5000 python-app
   ```

### Pipeline de Deploy

O pipeline do **GitHub Actions** (`terraform-deploy.yml`) executa os seguintes passos:

1. **Configuração do ambiente**:
   - Faz o checkout do código e configura o AWS CLI.
   - Inicializa o Terraform e cria a instância EC2 na AWS.

2. **Obtenção do IP da Instância EC2**:
   - A partir do Terraform, o IP público da instância EC2 é extraído e salvo em uma variável para ser usado na conexão SSH.

3. **Deploy via SSH**:
   - Conecta-se à instância EC2 e executa o script de deploy para configurar o Docker, construir a imagem Docker da aplicação e rodá-la dentro do container.

### Personalização

Se você deseja personalizar o projeto:

- Modifique o **script `deploy.sh`** para atender às necessidades específicas da sua aplicação.
- Altere os arquivos Terraform (`main.tf`, `variables.tf`) para ajustar o tipo de instância, a VPC, regras de segurança, entre outros recursos.
- Atualize o **Dockerfile** e o código Python em `src/app.py` conforme necessário.

### Contribuindo

Contribuições são bem-vindas! Se você encontrar algum problema ou tiver sugestões para melhorias, fique à vontade para abrir uma issue ou enviar um pull request.

### Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para mais detalhes.
```

### Alterações feitas:
1. **Estrutura da aplicação**: A seção agora inclui informações detalhadas sobre os arquivos da aplicação Python (`app.py`, `Dockerfile`, `requirements.txt`).
2. **Rodando a aplicação localmente**: Explicação sobre como construir e rodar a aplicação Python localmente com Docker.
3. **Pipeline de Deploy**: Detalhes sobre como o GitHub Actions agora cuida do deploy da aplicação Python na instância EC2, incluindo a execução do script de deploy para configurar e rodar o Docker com a aplicação.

Essa versão do README agora reflete o processo completo, incluindo o código da aplicação Python e os passos para o deploy automatizado na instância EC2.