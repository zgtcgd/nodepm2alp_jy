FROM node:alpine

WORKDIR /app

COPY index.js package.json start.sh /app/

ARG FILE_PATH=${FILE_PATH:-'/tmp'}
ARG PORT=${PORT:-'3000'}
EXPOSE $PORT

RUN apk update &&\
    apk add --no-cache bash wget curl procps zsh &&\
    wget -nv -O core.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip &&\
    unzip -qod ./ core.zip && rm -f core.zip && rm -rf geoip.dat geosite.dat LICENSE README.md && mv xray ${FILE_PATH}/data &&\
    wget -q -O ${FILE_PATH}/agent https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent &&\
    wget -q -O ${FILE_PATH}/server https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
    wget -q -O ${FILE_PATH}/up.sh https://raw.githubusercontent.com/mytcgd/myfiles/main/my/x/up_s.sh &&\
    chmod -v 755 ${FILE_PATH}/data ${FILE_PATH}/agent ${FILE_PATH}/server ${FILE_PATH}/up.sh start.sh &&\
    npm install -r package.json &&\
    npm install -g pm2

# Health check
HEALTHCHECK --interval=2m --timeout=30s CMD wget --no-verbose --tries=1 --spider http://localhost/healthcheck || exit 1

ENTRYPOINT [ "node", "/app/index.js" ]
