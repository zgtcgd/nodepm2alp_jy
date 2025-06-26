FROM node:alpine

WORKDIR /app

RUN apk add --no-cache --update bash curl procps

COPY package.json ./
RUN npm install && \
    npm install -g pm2 && \
    npm cache clean --force

COPY app.js start.sh ./
RUN chmod +x start.sh

EXPOSE 3000
ENV PM2_HOME=/tmp

CMD [ "node", "app.js" ]
