#!/bin/bash

check_dependencies() {
    local dependencies=("curl" "wget" "unzip")

    for dep in "${dependencies[@]}"; do
        if ! dpkg -s "${dep}" &> /dev/null; then
            echo "${dep} is not installed. Installing..."
            apt install "${dep}" -y
        fi
    done
}

download-xray() {
    pkg update -y
    check_dependencies
    mkdir xray && cd xray
    wget https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-android-arm64-v8a.zip
    unzip Xray-android-arm64-v8a
    mv Xray-android-arm64-v8a xray
    chmod +x xray
}

config() {
    cat << EOL > config.json
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "ip": [
                    "geoip:private"
                ],
                "outboundTag": "block"
            }
        ]
    },
    "inbounds": [
        {
            "listen": "12",
            "port": $port,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$uuid"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct",
            "settings": {
                "domainStrategy": "AsIs",
                "fragment": {
                    "packets": "tlshello",
                    "length": "100-200",
                    "interval": "10-20"
                }
            }
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOL
}

install() {
    clear
    download-xray
    config
    uuid=$(xray uuid)
    read -p "Enter a Port between [1024 - 65535]: " port
    vmess='{"add":"127.0.0.1","aid":"0","alpn":"","fp":"","host":"","id":"$uuid","net":"ws","path":"","port":"$port","ps":"Peyman YouTube X","scy":"auto","sni":"","tls":"","type":"","v":"2"}'
    encoded_vmess=$(echo -n "$vmess" | base64 -w 0)
    echo "vmess://$encoded_vmess"
    echo "vmess://$encoded_vmess" > "/xray/vmess.txt"
}

install