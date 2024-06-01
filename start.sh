#!/usr/bin/env bash

# variable
export UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
export VMESS_WSPATH=${VMESS_WSPATH:-'startvm'}
export VLESS_WSPATH=${VLESS_WSPATH:-'startvl'}
export CF_IP=${CF_IP:-'icook.tw'}
export SUB_NAME="$SUB_NAME"
export FILE_PATH=${FILE_PATH:-'/tmp'}

export openserver=${openserver:-'1'}

export SUB_URL="$SUB_URL"

NEZHA_SERVER="$NEZHA_SERVER"
NEZHA_KEY="$NEZHA_KEY"
NEZHA_PORT=${NEZHA_PORT:-'443'}

export ARGO_DOMAIN="$ARGO_DOMAIN"
export ARGO_AUTH="$ARGO_AUTH"

if [ ! -d "$FILE_PATH" ]; then
  mkdir -p "$FILE_PATH"
fi

cleanup_files() {
  rm -rf ${FILE_PATH}/*
}
cleanup_files

# Download required files
set_download_url() {
  local program_name="$1"
  local default_url="$2"
  local x64_url="$3"

  if [ "$(uname -m)" = "x86_64" ] || [ "$(uname -m)" = "amd64" ] || [ "$(uname -m)" = "x64" ]; then
    download_url="$x64_url"
  else
    download_url="$default_url"
  fi
}

download_program() {
  local program_name="$1"
  local default_url="$2"
  local x64_url="$3"

  set_download_url "$program_name" "$default_url" "$x64_url"

  if [ ! -f "$program_name" ]; then
    if [ -n "$download_url" ]; then
      echo "Downloading $program_name..." > /dev/null
      wget -qO "$program_name" "$download_url"
      # curl -sSL "$download_url" -o "$program_name"
      echo "Downloaded $program_name" > /dev/null
    else
      echo "Skipping download for $program_name" > /dev/null
    fi
  else
    echo "$program_name already exists, skipping download" > /dev/null
  fi
}

if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_KEY}" ]; then
  download_program "${FILE_PATH}/agent" "https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent(arm)" "https://raw.githubusercontent.com/kahunama/myfile/main/nezha/nezha-agent"
  chmod +x ${FILE_PATH}/agent
  sleep 3
fi

download_program "${FILE_PATH}/data" "https://github.com/mytcgd/myfiles/releases/download/main/xray_arm" "https://github.com/mytcgd/myfiles/releases/download/main/xray"
chmod +x ${FILE_PATH}/data
sleep 3

if [ ${openserver} -eq 1 ]; then
  download_program "${FILE_PATH}/server" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
  chmod +x ${FILE_PATH}/server
  sleep 3
fi

if [ -n "${SUB_URL}" ]; then
  download_program "${FILE_PATH}/up.sh" "https://raw.githubusercontent.com/mytcgd/myfiles/main/my/x/up_s.sh" "https://raw.githubusercontent.com/mytcgd/myfiles/main/my/x/up_s.sh"
  chmod +x ${FILE_PATH}/up.sh
  sleep 3
fi

# Generate configuration file
generate_config() {
  cat > ${FILE_PATH}/out.json << EOF
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":8080,
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-vision"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":3001
                    },
                    {
                        "path":"/${VLESS_WSPATH}",
                        "dest":3002
                    },
                    {
                        "path":"/${VMESS_WSPATH}",
                        "dest":3003
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":3001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":3002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/${VLESS_WSPATH}"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/${VMESS_WSPATH}"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ],
                "metadataOnly":false
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        },
        {
            "tag":"WARP",
            "protocol":"wireguard",
            "settings":{
                "secretKey":"YFYOAdbw1bKTHlNNi+aEjBM3BO7unuFC5rOkMRAz9XY=",
                "address":[
                    "172.16.0.2/32",
                    "2606:4700:110:8a36:df92:102a:9602:fa18/128"
                ],
                "peers":[
                    {
                        "publicKey":"bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                        "allowedIPs":[
                            "0.0.0.0/0",
                            "::/0"
                        ],
                        "endpoint":"162.159.193.10:2408"
                    }
                ],
                "reserved":[78, 135, 76],
                "mtu":1280
            }
        }
    ],
    "routing":{
        "domainStrategy":"AsIs",
        "rules":[
            {
                "type":"field",
                "domain":[
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag":"WARP"
            }
        ]
    }
}
EOF
}

argo_type() {
  if [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
    echo "ARGO_AUTH or ARGO_DOMAIN is empty, use Quick Tunnels" > /dev/null
    return
  fi

  if [ -n "$(echo "$ARGO_AUTH" | grep TunnelSecret)" ]; then
    echo $ARGO_AUTH > tunnel.json
    cat > tunnel.yml << EOF
tunnel=$(echo "$ARGO_AUTH" | cut -d\" -f12)
credentials-file: ./tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost: 8080
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
  else
    echo "ARGO_AUTH Mismatch TunnelSecret" > /dev/null
  fi
}

args() {
if [ -e ${FILE_PATH}/server ] && [ ${openserver} -eq 1 ]; then
  if [ -n "$(echo "$ARGO_AUTH" | grep '^[A-Z0-9a-z=]\{120,250\}$')" ]; then
    args="tunnel --edge-ip-version auto --protocol http2 --logfile ${FILE_PATH}/boot.log run --url http://localhost:8080 --token ${ARGO_AUTH}"
  elif [ -n "$(echo "$ARGO_AUTH" | grep TunnelSecret)" ]; then
    args="tunnel --edge-ip-version auto --config tunnel.yml run"
  else
    args="tunnel --edge-ip-version auto --protocol http2 --no-autoupdate --logfile ${FILE_PATH}/boot.log --url http://localhost:8080"
  fi
fi
}

generate_config
argo_type
args

# run
generate_pm2_file() {
  server_randomness=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 4)
  data_randomness=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 5)
  nez_randomness=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)

  if [ -e ${FILE_PATH}/server ] && [ ${openserver} -eq 1 ]; then
    mv ${FILE_PATH}/server ${FILE_PATH}/${server_randomness}
  fi

  mv ${FILE_PATH}/data ${FILE_PATH}/${data_randomness}

  if [ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_KEY}" ]; then
    mv ${FILE_PATH}/agent ${FILE_PATH}/${nez_randomness}
    tlsPorts=("443" "8443" "2096" "2087" "2083" "2053")
    if [[ " ${tlsPorts[@]} " =~ " ${NEZHA_PORT} " ]]; then
      NEZHA_TLS="--tls"
    else
      NEZHA_TLS=""
    fi
  fi

  cat > ${FILE_PATH}/ecosystem.config.js << ABC
module.exports = {
  "apps":[
      {
          "name":"data",
          "script":"${FILE_PATH}/${data_randomness} run -c ${FILE_PATH}/out.json"
ABC
  [ ${openserver} -eq 1 ] && cat >> ${FILE_PATH}/ecosystem.config.js << DEF
      },
      {
          "name":"server",
          "script":"${FILE_PATH}/${server_randomness} ${args}",
DEF
  [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" ]] && cat >> ${FILE_PATH}/ecosystem.config.js << HIJ
      },
      {
          "name":"agent",
          "script":"${FILE_PATH}/${nez_randomness}",
          "args":"-s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_TLS}"
HIJ
  cat >> ${FILE_PATH}/ecosystem.config.js << KLM
      }
  ]
}
KLM
}

generate_pm2_file

[ -e ${FILE_PATH}/ecosystem.config.js ] && pm2 start ${FILE_PATH}/ecosystem.config.js

sleep 30

# ip and country
export server_ip=$(curl -s https://speed.cloudflare.com/meta | tr ',' '\n' | grep -E '"clientIp"\s*:\s*"' | sed 's/.*"clientIp"\s*:\s*"\([^"]*\)".*/\1/')
export country_abbreviation=$(curl -s https://speed.cloudflare.com/meta | tr ',' '\n' | grep -E '"country"\s*:\s*"' | sed 's/.*"country"\s*:\s*"\([^"]*\)".*/\1/')

# list
list() {
  if [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
    [ -s ${FILE_PATH}/boot.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/boot.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi

  # openserver不等于1
  if [ ${openserver} -ne 1 ]; then
    export ARGO_DOMAIN="${server_ip}"
  fi

VMESS="{ \"v\": \"2\", \"ps\": \"vmess-${country_abbreviation}-${SUB_NAME}\", \"add\": \"${CF_IP}\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${VMESS_WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"

  cat > ${FILE_PATH}/list.txt << ABC
***************************************************

      IP : ${server_ip}     Country： ${country_abbreviation}

***************************************************

vmess://$(echo "$VMESS" | base64 | tr -d '\n')

vless://${UUID}@${CF_IP}:443?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}

***************************************************
ABC

  cat > ${FILE_PATH}/encode.txt << EOF
vmess://$(echo "$VMESS" | base64 | tr -d '\n')
vless://${UUID}@${CF_IP}:443?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}
EOF

  base64 ${FILE_PATH}/encode.txt | tr -d '\n' > ${FILE_PATH}/sub.txt
  rm ${FILE_PATH}/encode.txt
}

# up
if [ -z "$SUB_URL" ]; then
  list
else
  list
  bash ${FILE_PATH}/up.sh >/dev/null 2>&1 &
fi
