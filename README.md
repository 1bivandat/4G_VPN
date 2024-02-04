VPS: Ubuntu
1. apt-get update -y    
2. bash <(curl -Ls https://raw.githubusercontent.com/1bivandat/4G_VPN/main/4g.sh)
3. ufw allow 54321
4. ufw allow 443
5. ufw allow 80
7. systemctl stop nginx

SNI LQ: dl.kgvn.garenanow.com
