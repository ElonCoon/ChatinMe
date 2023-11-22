#!/bin/bash

export ports=""

#纯净系统安装aichat
install_aichat() {

# 检测操作系统类型
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
fi

# 判断是否为CentOS/debian/ubuntu安装对应docker
if command -v docker &>/dev/null; then
    echo "Docker 已经安装。跳过 Docker 安装步骤。"
else
    if [[ "$ID" == "centos"* ]]; then
        sudo yum update -y
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
        sudo systemctl start docker
        sudo systemctl enable docker.service
    elif [[ "$ID" == "debian"* ]]; then
        sudo apt-get update -y
        sudo apt-get install ca-certificates curl gnupg -y
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null        
        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    elif [[ "$ID" == "ubuntu"* ]]; then
        sudo apt-get update -y
        sudo apt-get install ca-certificates curl gnupg -y
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null        
        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    else
        echo "该脚本仅支持 CentOS、Debian 和 Ubuntu"
        exit 1
    fi
fi


#创建文件
touch /etc/docker/daemon.json
touch /etc/docker/docker-compose.yml

#下载docker-compose.yml
echo "下载docker-compose.yml中..."
curl -o /etc/docker/docker-compose.yml https://raw.githubusercontent.com/Nanjiren01/AIChatWeb/pro/docker-compose.yml

#配置AIChat专业版许可证
echo "****************** 配置AIChat专业版许可证 ******************"
while true; do
    read -p "请输入许可证的QQ邮箱：" LICENSE_SUBJECT
    if [[ -n $LICENSE_SUBJECT ]]; then
        if [[ $LICENSE_SUBJECT =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            echo "输入的许可证QQ邮箱有效"
            break
        else
            echo "无效的邮箱格式，请重试！"
        fi
    else
        echo "许可证邮箱不能为空，请重试！"
    fi
done
    
while true; do
    read -p "请输入许可证的SK码：" LICENSE_SK
        if [[ -n $LICENSE_SK ]]; then
            echo "输入的许可证SK码有效"
            break
    else
        echo "许可证SK码不能为空，请重试！"
    fi
done

sed -i "s/LICENSE_SUBJECT:.*/LICENSE_SUBJECT: $LICENSE_SUBJECT/g" /etc/docker/docker-compose.yml
sed -i "s/LICENSE_SK:.*/LICENSE_SK: $LICENSE_SK/g" /etc/docker/docker-compose.yml
echo "**************** 成功配置AIChat专业版许可证 ******************"

#配置超级管理员
echo "######################## 配置超级管理员 ############################"
while true; do
    echo "仅支持字母和数字，长度应在4到20之间，并且不能以数字开头。"
    read -p "请输入超级用户的账户名称： " SUPER_USERNAME
    regex='^[A-Za-z][A-Za-z0-9]{4,19}'
    if [[ $SUPER_USERNAME =~ $regex ]]; then
        echo "超级管理员账户名称有效"
        break
    else
        echo "超级管理员账户名称无效，请重试！"
    fi
done
    
while true; do
    echo "仅支持字母和数字，长度应在6到20之间。您可以在应用程序运行后在管理后台上进行更改。"
    read -p "请输入超级用户的账户密码：" SUPER_PASSWORD
    regex='^[A-Za-z0-9]{6,20}'
    if [[ $SUPER_PASSWORD =~ $regex ]]; then
        echo "超级管理员账户密码有效"
        break
    else
        echo "超级管理员账户密码无效，请重试！"
    fi
done
    
sed -i "s/SUPERADMIN_USERNAME:.*/SUPERADMIN_USERNAME: $SUPER_USERNAME/g" /etc/docker/docker-compose.yml
sed -i "s/SUPERADMIN_PASSWORD:.*/SUPERADMIN_PASSWORD: $SUPER_PASSWORD/g" /etc/docker/docker-compose.yml
echo "**************** 成功配置超级管理员账户 ******************"

echo "******************** 配置WEB端口号 ********************"
echo "请输入WEB端口号："
read -p "端口号： " ports
sed -i "s/"80:3000"/"$ports:3000"/g" /etc/docker/docker-compose.yml
echo "****************** WEB端口号配置成功 ******************"

#配置AIChat专业版对象存储
echo "**************** 配置AIChat专业版对象存储 ******************"
echo "你想进行配置吗？（可选） (按Y开始/按N跳过)"
read -p "Choice: " CONFIGURE_OSS
      
if [[ $CONFIGURE_OSS == "Y" || $CONFIGURE_OSS == "y" ]]; then
    while true; do
        read -p "请输入对象存储的OSS_ENDPOINT： " OSS_ENDPOINT
        if [[ -n $OSS_ENDPOINT ]]; then
            echo "输入在OSS_ENDPOINT有效"
            break
        else
            echo "OSS_ENDPOINT不能为空，请重试！"
        fi
    done
      
    OSS_ENDPOINT2=$OSS_ENDPOINT  
      
    # Replace all '/' with '\/'
    OSS_ENDPOINT=${OSS_ENDPOINT//\//\\/}
      
    while true; do
        read -p "请输入对象存储的OSS_BUCKET_NAME： " OSS_BUCKET_NAME
        if [[ -n $OSS_BUCKET_NAME ]]; then
            echo "输入在OSS_BUCKET_NAME有效"
            break
        else
            echo "OSS_BUCKET_NAME不能为空，请重试！"
        fi
    done
      
    while true; do
        read -p "请输入对象存储的OSS_ACCESS_KEY_ID： " OSS_ACCESS_KEY_ID
        if [[ -n $OSS_ACCESS_KEY_ID ]]; then
            echo "输入在OSS_ACCESS_KEY_ID有效"
            break
        else
            echo "OSS_ACCESS_KEY_ID不能为空，请重试！"
        fi
    done
      
    while true; do
        read -p "请输入对象存储的OSS_ACCESS_KEY_SECRET： " OSS_ACCESS_KEY_SECRET
        if [[ -n $OSS_ACCESS_KEY_SECRET ]]; then
            echo "输入在OSS_ACCESS_KEY_SECRET有效"
            break
        else
            echo "OSS_ACCESS_KEY_SECRET不能为空，请重试！"
        fi
    done
      
sed -i "s/STORE_TYPE:.*/STORE_TYPE: oss/" /etc/docker/docker-compose.yml
sed -i "s/OSS_ENDPOINT:.*/OSS_ENDPOINT: $OSS_ENDPOINT/g" /etc/docker/docker-compose.yml
sed -i "s/OSS_BUCKET_NAME:.*/OSS_BUCKET_NAME: $OSS_BUCKET_NAME/g" /etc/docker/docker-compose.yml
sed -i "s/OSS_ACCESS_KEY_ID:.*/OSS_ACCESS_KEY_ID: $OSS_ACCESS_KEY_ID/g" /etc/docker/docker-compose.yml
sed -i "s/OSS_ACCESS_KEY_SECRET:.*/OSS_ACCESS_KEY_SECRET: $OSS_ACCESS_KEY_SECRET/g" /etc/docker/docker-compose.yml
echo "**************** 成功配置AIChat专业版对象存储 ******************"
fi

# 修改UTIL_ENDPOINT
GATEWAY_IP=$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Gateway}}')
sed -i "s/UTIL_ENDPOINT:.*/UTIL_ENDPOINT: http:\/\/$GATEWAY_IP:7788/g" /etc/docker/docker-compose.yml

echo "============================== 配置总结 ==============================="
echo "AIChat专业版许可证信息："
echo "许可证QQ邮箱： $LICENSE_SUBJECT"
echo "许可证SK码： $LICENSE_SK"
echo "**********************************************************************"
echo "超级管理员信息："
echo "账户名称： $SUPER_USERNAME"
echo "密码： $SUPER_PASSWORD"
echo "**********************************************************************"
echo "端口号和IP地址信息："
echo "WEB端口号： $ports"
echo "UTIL_ENDPOINT: $GATEWAY_IP"
echo "**********************************************************************"
echo "AIChat专业版对象存储信息："
if [[ $CONFIGURE_OSS == "Y" || $CONFIGURE_OSS == "y" ]]; then
    echo "OSS_Endpoint: $OSS_ENDPOINT2"
    echo "OSS_Bucket_Name: $OSS_BUCKET_NAME"
    echo "OSS_Access_Key_ID: $OSS_ACCESS_KEY_ID"
    echo "OSS_Access_Key_Secret: $OSS_ACCESS_KEY_SECRET"
else
    echo "对象存储未进行配置"
fi
echo "======================================================================"
      
# Prompt for confirmation
echo "请检查上述配置是否正确，如果确认无误，请按 Enter 继续，或按 Ctrl+C 取消。"
read

#配置和登录AIChat专业版授权私有库
echo '{ "insecure-registries": ["harbor.nanjiren.online:8099"] }' | sudo tee /etc/docker/daemon.json
systemctl restart docker

echo "****************** 配置AIChat专业版授权私有库账户 ******************"
while true; do
    echo "请输入AIChat专业版授权私有库的授权用户名："
    read -p "授权用户名： " DOCKER_REGISTRY_USERNAME
    echo "请输入AIChat专业版授权私有库的授权密码："
    read -s -p "授权密码： " DOCKER_REGISTRY_PASSWORD

    echo "正在登录到AIChat专业版的Docker私有仓库..."
    if docker login -u $DOCKER_REGISTRY_USERNAME -p $DOCKER_REGISTRY_PASSWORD http://harbor.nanjiren.online:8099; then
        break
    else
        echo "AIChat专业版私有库登录失败，请重新输入您的账户和密码。"
    fi
done   
echo "**************** 成功设置AIChat专业版授权仓库账户 ******************"

#启动docker
cd /etc/docker
docker compose up -d
docker ps
}

install_nginx_ssl(){

#创建文件夹
folders=(/etc/Acme_SSL /etc/Acme_SSL/chat_cert /etc/Acme_SSL/console_cert)

for folder in "${folders[@]}"; do
    if [ ! -d "$folder" ]; then
        mkdir "$folder"
    fi
done

#检测系统类型
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
fi

#安装nginx
if [[ "$ID" == "centos"* ]]; then
    sudo yum install -y nginx socat
    sudo systemctl start nginx
    sudo systemctl enable nginx
elif [[ "$ID" == "debian"* ]]; then
    sudo apt-get install nginx socat -y
    sudo systemctl enable nginx
elif [[ "$ID" == "ubuntu"* ]]; then
    sudo apt-get install nginx socat -y
    sudo systemctl enable nginx
else
    exit 1
fi

#安装acme
if command -v /root/.acme.sh/acme.sh &> /dev/null
then
    echo "acme 已安装，跳过..."
else
    curl https://get.acme.sh | sh
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
fi

#申请证书
echo "请输入WEB端域名："
read -p "输入您的域名：" domain
echo "请输入控制台域名："
read -p "输入您的域名：" domain1
if [[ "$ID" == "centos"* ]]; then
    /root/.acme.sh/acme.sh --issue -d $domain -k ec-256 --webroot /usr/share/nginx/html
    /root/.acme.sh/acme.sh --issue -d $domain1 -k ec-256 --webroot /usr/share/nginx/html
elif [[ "$ID" == "debian"* ]]; then
    /root/.acme.sh/acme.sh --issue -d $domain -k ec-256 --webroot /var/www/html
    /root/.acme.sh/acme.sh --issue -d $domain1 -k ec-256 --webroot /var/www/html
elif [[ "$ID" == "ubuntu"* ]]; then
    /root/.acme.sh/acme.sh --issue -d $domain -k ec-256 --webroot /var/www/html
    /root/.acme.sh/acme.sh --issue -d $domain1 -k ec-256 --webroot /var/www/html
else
    exit 1
fi

#安装证书
/root/.acme.sh/acme.sh --install-cert -d $domain --ecc \
    --fullchain-file /etc/Acme_SSL/chat_cert/chat.crt \
    --key-file /etc/Acme_SSL/chat_cert/chat.key --reloadcmd "systemctl force-reload nginx"
/root/.acme.sh/acme.sh --install-cert -d $domain1 --ecc \
    --fullchain-file /etc/Acme_SSL/console_cert/console.crt \
    --key-file /etc/Acme_SSL/console_cert/console.key --reloadcmd "systemctl force-reload nginx"
chmod +r /etc/Acme_SSL/chat_cert/chat.key
chmod +r /etc/Acme_SSL/console_cert/console.key
/root/.acme.sh/acme.sh --upgrade --auto-upgrade

# 删除nginx.conf文件中的所有内容
> /etc/nginx/nginx.conf

# 将新的内容写入到nginx.conf文件中，同时替换变量
cat << EOF >> /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
}

http {
    map \$http_upgrade \$connection_upgrade {
        default upgrade;
        ''      close;
    }

    server {
        listen 80;
        listen 443 ssl;
        server_name $domain;

        if ($server_port !~ 443){
            rewrite ^(/.*)\$ https://\$host\$1 permanent;
        }

        ssl_certificate    /etc/Acme_SSL/chat_cert/chat.crt;
        ssl_certificate_key    /etc/Acme_SSL/chat_cert/chat.key;
        ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        add_header Strict-Transport-Security "max-age=31536000";
        error_page 497  https://\$host\$request_uri;

        location / {
            proxy_pass http://127.0.0.1:$ports;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header REMOTE-HOST \$remote_addr;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_http_version 1.1;

            add_header X-Cache $upstream_cache_status;

            set \$static_filerDMgmXdG 0;
            if ( \$uri ~* "\.(gif|png|jpg|css|js|woff|woff2)\$" ) {
                set \$static_filerDMgmXdG 1;
                expires 1m;
            }
            if ( \$static_filerDMgmXdG = 0 ) {
                add_header Cache-Control no-cache;
            }
        }
    }
     server {
        listen 80;
        listen 443 ssl;
        server_name $domain1;

        if ($server_port !~ 443){
            rewrite ^(/.*)\$ https://\$host\$1 permanent;
        }

        ssl_certificate    /etc/Acme_SSL/console_cert/console.crt;
        ssl_certificate_key    /etc/Acme_SSL/console_cert/console.key;
        ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        add_header Strict-Transport-Security "max-age=31536000";
        error_page 497  https://\$host\$request_uri;

        location / {
            proxy_pass http://127.0.0.1:8080;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header REMOTE-HOST \$remote_addr;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection \$connection_upgrade;
            proxy_http_version 1.1;

            add_header X-Cache \$upstream_cache_status;

            set \$static_filerDMgmXdG 0;
            if ( \$uri ~* "\.(gif|png|jpg|css|js|woff|woff2)\$" ) {
                set $static_filerDMgmXdG 1;
                expires 1m;
            }
            if ( $static_filerDMgmXdG = 0 ) {
                add_header Cache-Control no-cache;
            }
        }
    }
}
EOF

#重启nginx
systemctl restart nginx
}

while true; do
    echo "*****************************一键部署AIChat专业版********************************"
    echo "*                           1.一键安装AIChat"
    echo "*                           2.配置nginx、SSL证书"
    echo "*                           3.退出"
    echo "*******************************************************************************"
    read -p "请选择:" option
    case ${option} in
    1)
       install_aichat
       ;;
    2)
        install_nginx_ssl
       ;;
    3)
       exit 0
       ;;
     *)
        echo "无效的选择，请重新输入！"
        ;;
    esac
done
