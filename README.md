```markdown
# Terraform EC2 Deployment with CI/CD Pipeline

Este repositório contém uma infraestrutura criada com **Terraform** para provisionar uma instância EC2 na **AWS**, juntamente com um **pipeline GitHub Actions** para automatizar o processo de criação e deploy da aplicação nessa instância.

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
└── scripts/
    └── deploy.sh                   # Script de deploy rodado via SSH no EC2
```

### Descrição dos Arquivos:

- **`.github/workflows/terraform-deploy.yml`**: Pipeline automatizado usando GitHub Actions para rodar o Terraform e fazer deploy na instância EC2 via SSH.
- **`terraform/main.tf`**: Arquivo principal do Terraform que define os recursos AWS, incluindo a instância EC2.
- **`terraform/variables.tf`**: Declaração das variáveis de entrada para o Terraform.
- **`terraform/outputs.tf`**: Outputs definidos no Terraform, como o IP público da instância EC2.
- **`terraform/provider.tf`**: Configuração do provedor AWS.
- **`scripts/deploy.sh`**: Script que será executado via SSH na instância EC2 após o provisionamento.

## Como Usar Este Repositório

### Pré-requisitos:

1. **Conta AWS**: Você deve ter uma conta AWS com as permissões necessárias para criar instâncias EC2 e outros recursos.
2. **GitHub Actions**: O pipeline é configurado para rodar automaticamente quando houver um push para a branch `main`.
3. **Terraform**: Você pode rodar o Terraform localmente ou deixar o GitHub Actions automatizar tudo para você.

### Configuração no GitHub Actions:

1. **Credenciais AWS**:
   - No seu repositório GitHub, vá em **Settings > Secrets** e adicione os seguintes secrets:
     - `AWS_ACCESS_KEY_ID`: Chave de acesso da AWS.
     - `AWS_SECRET_ACCESS_KEY`: Chave secreta de acesso da AWS.
     - `AWS_SSH_PRIVATE_KEY`: Chave privada SSH para acessar a instância EC2.
  
2. **Pipeline de GitHub Actions**:
   - O pipeline `terraform-deploy.yml` automatiza a criação da instância EC2 e o deploy da sua aplicação via SSH. Ele é disparado automaticamente com qualquer push para a branch `main`.

### Rodando Localmente

Caso queira rodar o Terraform localmente, siga os passos abaixo:

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

### Pipeline de Deploy

O pipeline do **GitHub Actions** (`terraform-deploy.yml`) executa os seguintes passos:

1. **Configuração do ambiente**:
   - Faz o checkout do código e configura o AWS CLI.
   - Inicializa o Terraform e cria a instância EC2 na AWS.

2. **Captura do IP da instância EC2**:
   - Após criar a instância, o pipeline captura o **IP público** da instância EC2 usando o output do Terraform.

3. **Deploy na instância EC2**:
   - Conecta-se à instância via SSH usando o IP capturado e executa o script `deploy.sh` para fazer o deploy da aplicação.

### Personalização

Se você deseja personalizar o projeto:

- Modifique o **script `deploy.sh`** para atender às necessidades específicas da sua aplicação.
- Altere os arquivos Terraform (`main.tf`, `variables.tf`) para ajustar o tipo de instância, a VPC, regras de segurança, entre outros recursos.

### Contribuindo

Contribuições são bem-vindas! Se você encontrar algum problema ou tiver sugestões para melhorias, fique à vontade para abrir uma issue ou enviar um pull request.

### Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para mais detalhes.
```

### Explicação

- **Introdução**: Descreve o objetivo do repositório (deploy automatizado de instância EC2 e aplicação via Terraform e GitHub Actions).
- **Estrutura do Repositório**: Mostra a organização dos arquivos e pastas.
- **Pré-requisitos**: Lista as credenciais e ferramentas necessárias.
- **Instruções de Uso**: Explica como rodar o Terraform tanto localmente quanto via pipeline do GitHub Actions.
- **Pipeline de Deploy**: Detalha o que o pipeline faz em cada etapa.
- **Personalização**: Mostra como modificar o código e o script de deploy.
- **Contribuições e Licença**: Fala sobre como contribuir e a licença do projeto.

Esse README fornece instruções claras e organizadas, facilitando o uso e entendimento do projeto.