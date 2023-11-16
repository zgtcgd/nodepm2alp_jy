#!/usr/bin/env bash

UUID=$UUID
VLESS_WSPATH=$VLESS_WSPATH
CF_IP=$CF_IP
SUB_NAME=$SUB_NAME
SUB_URL=$SUB_URL

while true
do
# 上传订阅
upload_url_data() {
    if [ $# -lt 3 ]; then
        return 1
    fi

    UPLOAD_URL="$1"
    URL_NAME="$2"
    URL_TO_UPLOAD="$3"

    # 检查curl命令是否存在
    if command -v curl &> /dev/null; then

        curl -s -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"URL_NAME\": \"$URL_NAME\", \"URL\": \"$URL_TO_UPLOAD\"}" "$UPLOAD_URL"

    # 检查wget命令是否存在
    elif command -v wget &> /dev/null; then

        echo "{\"URL_NAME\": \"$URL_NAME\", \"URL\": \"$URL_TO_UPLOAD\"}" | wget --quiet --post-data=- --header="Content-Type: application/json" "$UPLOAD_URL" -O -

    else
        echo "Both curl and wget are not installed. Please install one of them to upload data."
    fi
}

if [ -z "$ARGO_AUTH" ] && [ -z "$ARGO_DOMAIN" ]; then
  [ -s /tmp/argo.log ] && export ARGO_DOMAIN=$(cat /tmp/argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
fi
# 获取服务器的公共IP地址
server_ip=$(curl -s https://ipinfo.io/ip)
# 获取IP地址对应的国家简称
country_abbreviation=$(curl -s https://ipinfo.io/${server_ip}/country)
export VM_URL="vmess://$(echo "$VMESS" | base64 -w0)"
export VL_URL="vless://${UUID}@${CF_IP}:443?host=${ARGO_DOMAIN}&path=%2F${VLESS_WSPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#vless-${country_abbreviation}-${SUB_NAME}"
# upload_url_data "${SUB_URL}" "${SUB_NAME}" "${VM_URL}"
  upload_url_data "${SUB_URL}" "${SUB_NAME}" "${VL_URL}"
# echo upload ok

sleep 300
done
