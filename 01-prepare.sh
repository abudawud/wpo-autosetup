#!/usr/bin/bash

source ./module
source ./profile

set -e

if [ $(id -un) != 'root' ]; then
    print_error "This script must be run as 'root' !"
    exit 1
fi

# Disable SELinux
print_info "Disabling SELinux..."
setenforce 0
## Permanently disable SELinux
sed -ri 's/SELINUX=enforcing/SELINUX=permissive/' /etc/sysconfig/selinux
## Add local/bin path
if [ $PATH != "/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin/" ]; then
    echo export PATH=$PATH:/usr/local/bin/ >> ~/.bashrc
fi

# Install Plugins repo and add epel repo
print_info "Setting up repository..."
## Install and setup plugin repo
yum -y install yum-plugin-priorities 
sed -i -e "s/\]$/\]\npriority=1/g" /etc/yum.repos.d/CentOS-Base.repo
## Install epel and set to disabled by default
yum -y install epel-release 
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/epel.repo 

# Install required tools: docker, and docker-compose
print_info "Installing required tools: docker, docker-compose, etc..."
## install docker and enable it
yum -y install docker
systemctl enable docker 
systemctl start docker 
print_info "Docker version is: $(docker -v)"
## Install docker-compose
yum install -y python3-pip
pip3 install docker-compose
print_info "Docker compose version is: $(docker-compose -v)"
## Install other tools
yum install -y unzip

# Install nginx as proxy server
print_info "Installing nginx"
yum --enablerepo=epel -y install nginx 
systemctl enable nginx 
print_info "nginx version is: $(nginx -v)"

# Setup SSL for nginx
print_info "Setup self-signed SSL and proxy..."
mkdir /etc/ssl/private
chmod 700 /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout /etc/ssl/private/nginx-selfsigned.key \
		-out /etc/ssl/certs/nginx-selfsigned.crt \
		-subj "/C=ID/ST=Jatim/L=Pasuruan/O=PLTGU Grati/CN=${SERVER_IP_ADDR:-192.168.107.12}"

cat > /etc/nginx/conf.d/ssl.conf << EOF
server {
    listen 443 http2 ssl;
    listen [::]:443 http2 ssl;

    server_name ${SERVER_IP_ADDR:-192.168.107.12};

    ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

    root /usr/share/nginx/html;

    location /izinkerja {
        proxy_pass http://127.0.0.1:8880/izinkerja;
    }

    error_page 404 /404.html;
    location = /404.html {
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
    }
}
EOF
## Redirect HTTP to HTTPS
sed -i '46ireturn 301 https://$host$request_uri;' /etc/nginx/nginx.conf