#!/usr/bin/env sh

#export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="ssh://ubuntu@guinea-covid.elmis-dev.org"
#export DOCKER_CERT_PATH="${PWD}/credentials"
#export KEEP_OR_WIPE="wipe"

../shared/init_env_gh.sh

# Add traefik as a separate docker compose file and run it as such
docker-compose -f traefik-docker-compose.yml down -d
docker-compose -f traefik-docker-compose.yml up -d