#!/usr/bin/env sh

docker-compose pull

docker-compose kill
docker-compose down -v
docker rm $(docker ps -aq)

export spring_profiles_active='production'
echo "Profiles to use: $spring_profiles_active"

docker-compose up --build --force-recreate -d

