# Imagem oficial do Node.js (versão LTS); a base Alpine deixa a imagem menor
FROM node:22-alpine

# Pasta de trabalho dentro do container
WORKDIR /app

# Copia primeiro só a lista de dependências, para aproveitar o cache de camadas:
# se só o código mudar, o npm install não roda de novo no próximo build
COPY package*.json ./

# Instala apenas as dependências de produção (express, pg, dotenv)
RUN npm install --omit=dev

# Copia o restante do código; o .dockerignore filtra o que não deve entrar
COPY . .

ENV NODE_ENV=production

# Roda a aplicação com o usuário "node" da imagem, e não como root
USER node

# Porta interna em que a API atende
EXPOSE 3000

# Comando que inicia a aplicação (definido no package.json)
CMD ["npm", "start"]
