#!/usr/bin/env bash

# 设置UUID、端口和路径，CF_IP是优选IP，SUB_NAME为节点名称
export UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
export VMESS_WSPATH=${VMESS_WSPATH:-'startvm'}
export VLESS_WSPATH=${VLESS_WSPATH:-'startvl'}
export CF_IP=${CF_IP:-'www.who.int'}
export SUB_NAME="$SUB_NAME"
export FILE_PATH=${FILE_PATH:-'/tmp'}

# 设置订阅上传地址
export SUB_URL="$SUB_URL"

# 哪吒的2个参数
NEZHA_SERVER="$NEZHA_SERVER"
NEZHA_KEY="$NEZHA_KEY"

# argo参数
export ARGO_DOMAIN="$ARGO_DOMAIN"
export ARGO_AUTH="$ARGO_AUTH"

cleanup_files() {
  rm -rf ${FILE_PATH}/out.json ${FILE_PATH}/boot.log ${FILE_PATH}/country.txt ${FILE_PATH}/list.txt ${FILE_PATH}/sub.txt
}
cleanup_files

# 生成X配置文件
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
if [ -e ${FILE_PATH}/server ]; then
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

generate_pm2_file() {
  data_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 4)
  server_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 5)
  nez_RANDOMNESS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
  cp ${FILE_PATH}/data ${FILE_PATH}/${data_RANDOMNESS} && rm ${FILE_PATH}/data
  cp ${FILE_PATH}/server ${FILE_PATH}/${server_RANDOMNESS} && rm ${FILE_PATH}/server
  cp ${FILE_PATH}/agent ${FILE_PATH}/${nez_RANDOMNESS} && rm ${FILE_PATH}/agent

  cat > ${FILE_PATH}/ecosystem.config.js << ABC
module.exports = {
  "apps":[
      {
          "name":"data",
          "script":"${FILE_PATH}/${data_RANDOMNESS} run -c ${FILE_PATH}/out.json"
ABC
  [ -e ${FILE_PATH}/server ] && cat >> ${FILE_PATH}/ecosystem.config.js << DEF
      },
      {
          "name":"cff",
          "script":"${FILE_PATH}/server",
          "args":"${ARGO_ARGS}"
DEF
  [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" ]] && cat >> ${FILE_PATH}/ecosystem.config.js << HIJ
      },
      {
          "name":"agent",
          "script":"${FILE_PATH}/${nez_RANDOMNESS}",
          "args":"-s ${NEZHA_SERVER}:443 -p ${NEZHA_KEY} --tls"
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

# 获取服务器的公共IP地址及国家简称
function read_country() {
  server_ip=$(curl -s https://ipinfo.io/ip)

  if [ -z "$server_ip" ]; then
    echo "UN" > ${FILE_PATH}/country.txt
    return
  fi

  if [ -z "${apikey}" ]; then
    response=$(curl -s "https://ipinfo.io/${server_ip}/country")
  else
    response=$(curl -s "https://ipinfo.io/${server_ip}/country?token=${apikey}")
  fi

  status_code=$(echo "$response" | grep -o '"title": "Rate limit exceeded"')

  if [ -n "${status_code}" ]; then
    echo "UN" > ${FILE_PATH}/country.txt
  else
    country_abbreviation=$(echo "$response")
    echo "$country_abbreviation" > ${FILE_PATH}/country.txt
  fi
}

read_country

list() {
if [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
  [ -s ${FILE_PATH}/boot.log ] && export ARGO_DOMAIN=$(cat ${FILE_PATH}/boot.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
fi
country_abbreviation=$(cat ${FILE_PATH}/country.txt)
VMESS="{ \"v\": \"2\", \"ps\": \"vmess-${country_abbreviation}-${SUB_NAME}\", \"add\": \"${CF_IP}\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${VMESS_WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"

  cat > ${FILE_PATH}/list.txt <<ABC
***************************************************

      IP : ${server_ip}     Country： ${country_abbreviation}

***************************************************

vmess://$(echo "$VMESS" | base64 | tr -d '\n')

vless://${UUID}@${CF_IP}:443?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}

***************************************************
ABC

  cat > ${FILE_PATH}/encode.txt <<EOF
vmess://$(echo "$VMESS" | base64 | tr -d '\n')
vless://${UUID}@${CF_IP}:443?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}
EOF

base64 ${FILE_PATH}/encode.txt | tr -d '\n' > ${FILE_PATH}/sub.txt
# cat ${FILE_PATH}/list.txt
# echo -e "\n节点信息已保存在 list.txt"
rm ${FILE_PATH}/encode.txt
}

if [ -z "$SUB_URL" ]; then
list

else
list

bash ${FILE_PATH}/up.sh >/dev/null 2>&1 &
fi
