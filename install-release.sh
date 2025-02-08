#                             Online Bash Shell.
#                 Code, Compile, Run and Debug Bash script online.
# Write your code in this editor and press "Run" button to execute it.
getIP(){
    local serverIP=
    serverIP=$(curl -s -4 http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "[=]" '{print $2}')
    if [[ -z "${serverIP}" ]]; then
        serverIP=$(curl -s -6 http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "[=]" '{print $2}')
    fi
    echo "${serverIP}"
}
getShortId(){
    hexchars="0123456789abcdef"
    str=""
    for _ in $(seq 1 16); do
        str="$str${hexchars:RANDOM%16:1}"
    done
    echo "$str"
}
configReality(){
    v2uuid=$(/usr/local/bin/xray/xray uuid)
        reX25519Key=$(/usr/local/bin/xray/xray x25519)
    rePrivateKey=$(echo "${reX25519Key}" | head -1 | awk '{print $3}')
    rePublicKey=$(echo "${reX25519Key}" | tail -n 1 | awk '{print $3}')
    read -t 15 -p "please input port or use drfault 443 port(1-65535)："  getPort
if [ -z $getPort ];then
    getPort=443
fi
shortId1=$(getShortId)
shortId2=$(getShortId)

    # Step 4: Create the Xray configuration file
cat >/usr/local/etc/xray/config.json<<EOF
{
    "inbounds": [
        {
            "port": $getPort,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$v2uuid",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "www.amazon.com:443",
                    "xver": 0,
                    "serverNames": [
                        "uedata.amazon.com",
                        "corporate.amazon.com",
                        "mp3recs.amazon.com"
                    ],
                    "privateKey": "$rePrivateKey",
                    "minClientVer": "",
                    "maxClientVer": "",
                    "maxTimeDiff": 0,
                    "shortIds": [
                        "$shortId1",
                        "$shortId2"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "blocked"
        }
    ]    
}
EOF
service xray restart
}


configRealityRegion(){
destNames=("www.t-mobile.com" "www.arm.com" "www.tsukuba.ac.jp" "www.hongkongdisneyland.com" "www.china-airlines.com" "sigtelinc.com" "www.bouyguestelecom.fr" "www.mercedes-benz.de" "www.incredibleindia.gov.in" "www.amazon.com")
sniNames=("business.t-mobile.com" "learn.arm.com" "www.tsukuba.ac.jp" "entitlement.hongkongdisneyland.com" "book.china-airlines.com" "www.sigtelinc.com" "www.bouygtel.fr" "pro.mercedes-benz.com" "www.incredibleindia.org" "corporate.amazon.com")
echo "Please select a region:"
echo "1. US"
echo "2. UK"
echo "3. JP"
echo "4. HK"
echo "5. TW"
echo "6. SG"
echo "7. FR"
echo "8. DE"
echo "9. IN"
echo "10. Others"

# Read user input
read -r userInput

if [ "$userInput" -ge 1 ] && [ "$userInput" -le 10 ]; then
    index=$((userInput - 1))  # Adjust index to match array (0-based)
    serverName=${destNames[$index]}
    sniName=${sniNames[$index]}
else
    echo "Invalid selection. Please enter a number between 1 and 10."
    configRealityRegion
fi


    v2uuid=$(/usr/local/bin/xray/xray uuid)
        reX25519Key=$(/usr/local/bin/xray/xray x25519)
    rePrivateKey=$(echo "${reX25519Key}" | head -1 | awk '{print $3}')
    rePublicKey=$(echo "${reX25519Key}" | tail -n 1 | awk '{print $3}')
    read -t 15 -p "please input port or use drfault 443 port(1-65535)："  getPort
if [ -z $getPort ];then
    getPort=443
fi
shortId1=$(getShortId)
shortId2=$(getShortId)


    # Step 4: Create the Xray configuration file
cat >/usr/local/etc/xray/config.json<<EOF
{
    "inbounds": [
        {
            "port": $getPort,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$v2uuid",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "$serverName:443",
                    "xver": 0,
                    "serverNames": [
                        "$sniName"
                    ],
                    "privateKey": "$rePrivateKey",
                    "minClientVer": "",
                    "maxClientVer": "",
                    "maxTimeDiff": 0,
                    "shortIds": [
                        "$shortId1",
                        "$shortId2"
                    ]
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "blocked"
        }
    ]    
}
EOF
service xray restart
}


installXray(){
    apk update && apk upgrade

# Step 2: Install required dependencies
apk add curl bash unzip grep

# Step 3: Download and install Xray
XRAY_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip

# Create directories
mkdir -p /usr/local/bin/xray
mkdir -p /usr/local/etc/xray

# Unzip the Xray package
unzip /tmp/xray.zip -d /usr/local/bin/xray

# Make Xray binary executable
chmod +x /usr/local/bin/xray/xray


# Step 5: Create OpenRC init script for Xray
cat <<EOF > /etc/init.d/xray
#!/sbin/openrc-run

name="Xray"
description="Xray Proxy Service"

command="/usr/local/bin/xray/xray"
command_args="-config /usr/local/etc/xray/config.json"
pidfile="/var/run/xray.pid"
command_background="yes"

depend() {
    need net
}

start_pre() {
    checkpath --file --mode 0644 --owner root:root /var/run/xray.pid
}
EOF

# Make the init script executable
chmod +x /etc/init.d/xray

# Step 6: Enable and start the Xray service
rc-update add xray default
#service xray start

# Step 7: Clean up temporary files
rm -f /tmp/xray.zip

# Step 8: Show status of Xray service
service xray status

echo "Xray installation complete!"

   echo "Please select a configuration method:"
    echo "1) Auto Config"
    echo "2) Manual Config"
    echo "3) Exit"

    while true; do
        read -r -p "Enter your choice (1-3): " choice
        case "$choice" in
            1) configReality; break ;;
            2) configRealityRegion; break ;;
            3) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid input. Please enter 1, 2, or 3." ;;
        esac
    done




clear
client_re
}
client_re(){
    echo
    echo "安装已经完成"
    echo
    echo "===========reality配置参数============"
    echo "代理模式：vless"
    echo "地址：$(getIP)"
    echo "端口：${getPort}"
    echo "UUID：${v2uuid}"
    echo "流控：xtls-rprx-vision"
    echo "传输协议：tcp"
    echo "Public key：${rePublicKey}"
    echo "底层传输：reality"
    echo "SNI: $sniName"
    echo "shortIds: ${getPort}"
    echo "===================================="
    echo "vless://${v2uuid}@$(getIP):${getPort}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$sniName&fp=chrome&pbk=${rePublicKey}&sid=${shortId1}&type=tcp&headerType=none#xrayReality"
    echo
}


installHy2(){
    echo "install hystria2 and config it"
    # Hysteria 2 installation script for Alpine Linux 3.19

set -e

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Update and install necessary packages
apk update && apk upgrade
apk add bash gawk curl openssl

# Generate a random password
hyPasswd=$(openssl rand -hex 16)

# Get server IP
getIP() {
    curl -s https://api.ipify.org
}

serverIP=$(getIP)

# Install Hysteria 2
bash <(curl -fsSL https://get.hy2.sh/)

# Create Hysteria config directory
mkdir -p /etc/hysteria

# Generate Hysteria 2 server config
cat <<EOF > /etc/hysteria/config.yaml
listen: :443
protocol: udp
auth:
  type: password
  password: "$hyPasswd"
masquerade:
  type: proxy
  proxy:
    url: https://www.bing.com
    rewriteHost: true
EOF

# Create OpenRC service script
cat << 'EOF' > /etc/init.d/hysteria
#!/sbin/openrc-run

name="hysteria"
description="Hysteria 2 VPN server"

command="/usr/local/bin/hysteria"
command_args="server --config /etc/hysteria/config.yaml"
pidfile="/var/run/${name}.pid"
command_background="yes"

depend() {
    need net
}
EOF

# Set permissions and enable service
chmod +x /etc/init.d/hysteria
rc-update add hysteria default
service hysteria start

# Output connection details
echo "Hysteria 2 has been installed successfully!"
echo "Server IP: $serverIP"
echo "Password: $hyPasswd"
echo "Configuration file: /etc/hysteria/config.yaml"
}

menu(){
    echo "0. Exit"
    echo "1. install Xray and Config Reality"
    echo "2. install hystria2"
    read option
    if [[ option -eq 0 ]]; then
        exit 0
    elif [[ option -eq 1 ]]; then
        installXray
    elif [[ option -eq 2 ]]; then
        installHy2
    else
        echo "invid option"
        menu
    fi
}
# Ensure this script is run as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root!" 
   exit 1
fi
menu #special thanks to administrator of 1024.day
