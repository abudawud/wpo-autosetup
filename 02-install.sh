#!/usr/bin/bash

source ./module
source ./profile

set -e

# Save dir and move to project dir
LAST_DIR=$(pwd)
cd $PROJECT_DIR

print_info "Building and starting up services..."
print_info "this process will taking long time, if the proses done, press CTRL+C to continue to the next process!"
docker-compose up

cd $LAST_DIR