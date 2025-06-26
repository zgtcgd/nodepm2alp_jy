FROM node:alpine

WORKDIR /app

COPY app.js package.json start.sh /app/

EXPOSE 3000

ENV PM2_HOME=/tmp

RUN apk update && \
    apk add --no-cache bash wget curl procps && \
    chmod -v 755 start.sh && \
    npm install && \
    npm install -g pm2

ENTRYPOINT [ "node", "/app/app.js" ]
