#!/usr/bin/env bash

# 设置UUID、端口和路径，CF_IP是优选IP，SUB_NAME为节点名称,FLIE_PATH为代码所在的目录
# export SERVER_PORT==${SERVER_PORT:-''}
export VMESS_WSPATH=${VMESS_WSPATH:-'startvm'}
export VLESS_WSPATH=${VLESS_WSPATH:-'startvl'}
export CF_IP=${CF_IP:-'www.who.int'}
export UUID=${UUID:-'a9d16cf3-d2ac-4ea6-b354-fb42dda42b7a'}
export FLIE_PATH=${FLIE_PATH:-'/tmp/'}
export SUB_NAME="$SUB_NAME"

# 设置订阅上传地址
export SUB_URL="$SUB_URL"

# 哪吒的四个参数
NEZHA_SERVER="$NEZHA_SERVER"
NEZHA_KEY="$NEZHA_KEY"

# argo参数
export ARGO_DOMAIN="$ARGO_DOMAIN"
export ARGO_AUTH="$ARGO_AUTH"

cleanup_files() {
  rm -rf ${FLIE_PATH}argo.log ${FLIE_PATH}argo.sh ${FLIE_PATH}web.sh ${FLIE_PATH}nezha.sh ${FLIE_PATH}list.txt ${FLIE_PATH}sub.txt
}
cleanup_files

# 生成X配置文件
generate_config() {
  cat > ${FLIE_PATH}config.json << EOF
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
    echo "ARGO_AUTH or ARGO_DOMAIN is empty, use Quick Tunnels"
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
    echo "ARGO_AUTH Mismatch TunnelSecret"
  fi
}

args() {
if [ -e ${FLIE_PATH}argo ]; then
  if [ -n "$(echo "$ARGO_AUTH" | grep '^[A-Z0-9a-z=]\{120,250\}$')" ]; then
    args="tunnel --edge-ip-version auto --protocol http2 --logfile ${FLIE_PATH}argo.log run --url http://localhost:8080 --token ${ARGO_AUTH}"
  elif [ -n "$(echo "$ARGO_AUTH" | grep TunnelSecret)" ]; then
    args="tunnel --edge-ip-version auto --config tunnel.yml run"
  else
    args="tunnel --edge-ip-version auto --protocol http2 --no-autoupdate --logfile ${FLIE_PATH}argo.log --url http://localhost:8080"
  fi
fi
}

generate_config
argo_type
args

generate_pm2_file() {
  # 伪装 X 执行文件
  RELEASE_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
  cp ${FLIE_PATH}web ${FLIE_PATH}${RELEASE_RANDOMNESS}

  cp ${FLIE_PATH}config.json > ${FLIE_PATH}index.json
  sed -i "s#UUID#$UUID#g;s#VMESS_WSPATH#$VMESS_WSPATH#g;s#VLESS_WSPATH#$VLESS_WSPATH#g" ${FLIE_PATH}index.json
  cat > /tmp/ecosystem.config.js << EOF
module.exports = {
  "apps":[
      {
          "name":"web",
          "script":"${FLIE_PATH}${RELEASE_RANDOMNESS} run -c ${FLIE_PATH}index.json"
EOF
  [ -e ${FLIE_PATH}argo ] && cat >> /tmp/ecosystem.config.js << EOF
      },
      {
          "name":"argo",
          "script":"${FLIE_PATH}argo $args"
EOF
  [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" ]] && cat >> /tmp/ecosystem.config.js << EOF
      },
      {
          "name":"agent",
          "script":"${FLIE_PATH}nezha-agent",
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

sleep 30

list() {
if [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
  [ -s ${FLIE_PATH}argo.log ] && export ARGO_DOMAIN=$(cat ${FLIE_PATH}argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
fi
# 获取服务器的公共IP地址
server_ip=$(curl -s https://ipinfo.io/ip)
# 获取IP地址对应的国家简称
country_abbreviation=$(curl -s https://ipinfo.io/${server_ip}/country)
VMESS="{ \"v\": \"2\", \"ps\": \"vmess-${country_abbreviation}-${SUB_NAME}\", \"add\": \"${CF_IP}\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${VMESS_WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"
  cat > ${FLIE_PATH}list.txt <<ABC
***************************************************

      IP : ${server_ip}     Country： ${country_abbreviation}

***************************************************

vmess://$(echo "$VMESS" | base64 -w0)

vless://${UUID}@${CF_IP}:443?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}

***************************************************
ABC

  cat > ${FLIE_PATH}encode.txt <<EOF
vmess://$(echo "$VMESS" | base64 -w0)
vless://${UUID}@${CF_IP}:443?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}
EOF

base64 -w0 ${FLIE_PATH}encode.txt > ${FLIE_PATH}sub.txt
#    cat list.txt
#   echo -e "\n节点信息已保存在 list.txt"
rm ${FLIE_PATH}encode.txt
}


if [ -z "$SUB_URL" ]; then
list


else
list

sleep 30

chmod +x upload.sh
bash upload.sh >/dev/null 2>&1 &

fi
