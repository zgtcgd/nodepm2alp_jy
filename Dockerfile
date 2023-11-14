FROM node:alpine

WORKDIR /app

COPY index.js package.json start.sh upload.sh /app/

EXPOSE 3000

ARG FLIE_PATH=${FLIE_PATH:-'/tmp/'}
ENV FLIE_PATH=${FLIE_PATH:-'/tmp/'}
ENV PM2_HOME=/tmp

RUN apk update &&\
    apk add --no-cache bash wget curl procps &&\
    wget -q -O ${FLIE_PATH}web https://raw.githubusercontent.com/kahunama/myfile/main/my/xray &&\
    wget -q -O ${FLIE_PATH}nezha-agent https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent && \
    wget -q -O ${FLIE_PATH}argo https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
    chmod -v 755 ${FLIE_PATH}web ${FLIE_PATH}nezha-agent ${FLIE_PATH}argo start.sh upload.sh &&\
    npm install -r package.json &&\
    npm install -g pm2

# Health check
HEALTHCHECK --interval=2m --timeout=30s \
  CMD wget --no-verbose --tries=1 --spider http://localhost/healthcheck || exit 1

ENTRYPOINT [ "node", "index.js" ]
