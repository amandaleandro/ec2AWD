# Usando uma imagem oficial do Node.js
FROM node:14

# Definir o diretório de trabalho
WORKDIR /usr/src/app

# Copiar o package.json e instalar as dependências
COPY package*.json ./
RUN npm install

# Copiar o restante do código
COPY . .

# Expor a porta onde a aplicação vai rodar
EXPOSE 3000

# Comando para iniciar a aplicação
CMD ["npm", "start"]
