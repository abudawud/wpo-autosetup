#!/usr/bin/bash

source ./module
source ./profile

set -e

# Save dir and move to project dir
LAST_DIR=$(pwd)
cd $PROJECT_DIR

# Start servce
print_info "Starting cluster in background..."
docker-compose start

# Start nginx
print_info "Starting nginx..."
systemctl start nginx

# Setup firewall
print_info "Open incoming connection on: http, https, oracle, gateapi, and mqtt"
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=1521/tcp
firewall-cmd --permanent --add-port=5000/tcp
firewall-cmd --permanent --add-port=1883/tcp

firewall-cmd --reload

cd $LAST_DIR
print_info "All setup complete!"