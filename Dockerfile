FROM node:alpine

WORKDIR /app

COPY index.js package.json start.sh upload.sh /app/

ARG PORT=${PORT:-'3000'}
ENV PORT=${PORT:-'3000'}
EXPOSE $PORT

ENV PM2_HOME=/tmp

RUN apk update &&\
    apk add --no-cache bash wget curl procps &&\
    wget -nv -O core.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip &&\
    unzip -qod ./ core.zip && rm -f core.zip && rm -rf geoip.dat geosite.dat LICENSE README.md && mv xray data &&\
    wget -O agent https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent &&\
    wget -q -O argo https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
    chmod -v 755 data agent argo start.sh upload.sh &&\
    npm install -r package.json &&\
    npm install -g pm2

# Health check
HEALTHCHECK --interval=2m --timeout=30s \
  CMD wget --no-verbose --tries=1 --spider http://localhost/healthcheck || exit 1

ENTRYPOINT [ "node", "index.js" ]
