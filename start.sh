#!/usr/bin/env bash

UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
VMESS_WSPATH=${VMESS_WSPATH:-'/startvm'}
VLESS_WSPATH=${VLESS_WSPATH:-'/startvl'}

# 哪吒2个参数
NEZHA_SERVER="$NEZHA_SERVER"
NEZHA_KEY="$NEZHA_KEY"

#隧道token
ARGO_AUTH="$ARGO_AUTH"

generate_pm2_file() {
  # 伪装 X 执行文件
  RELEASE_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
  cp data /tmp/${RELEASE_RANDOMNESS}

  base64 -d /home/choreouser/log > /tmp/index.json
  sed -i "s#UUID#$UUID#g;s#VMESS_WSPATH#$VMESS_WSPATH#g;s#VLESS_WSPATH#$VLESS_WSPATH#g" /tmp/index.json
  cat > /tmp/ecosystem.config.js << EOF
module.exports = {
  "apps":[
      {
          "name":"data",
          "script":"/tmp/${RELEASE_RANDOMNESS} run -c /tmp/index.json"
EOF
  [[ -n "${ARGO_AUTH}" ]] && cat >> /tmp/ecosystem.config.js << EOF
      },
      {
          "name":"argo",
          "script":"/home/choreouser/argo tunnel --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH}"
EOF
  [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" ]] && cat >> /tmp/ecosystem.config.js << EOF
      },
      {
          "name":"agent",
          "script":"/home/choreouser/agent",
          "args":"-s ${NEZHA_SERVER}:443 -p ${NEZHA_KEY} --tls"
EOF
  cat >> /tmp/ecosystem.config.js << EOF
      }
  ]
}
EOF
}

generate_pm2_file

[ -e /tmp/ecosystem.config.js ] && pm2 start /tmp/ecosystem.config.js
