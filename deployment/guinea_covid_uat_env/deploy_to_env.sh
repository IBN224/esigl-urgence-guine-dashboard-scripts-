#!/usr/bin/env sh

#export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="ssh://ubuntu@guinea-covid.elmis-dev.org"
#export DOCKER_CERT_PATH="${PWD}/credentials"
export KEEP_OR_WIPE="keep"

#../shared/init_env_gh.sh

../shared/pull_images.sh $1

../shared/restart.sh $1
