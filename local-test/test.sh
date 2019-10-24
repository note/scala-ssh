#!/bin/bash

# enable job control
set -m

PRIVATE_KEY_FILENAME="id_ed25519"
PUBLIC_KEY_FILENAME="id_ed25519.pub"
DOCKER_IMAGE_NAME="rastasheep/ubuntu-sshd:16.04"

rm -f id_ed25519 id_ed25519.pub

ssh-keygen -t ed25519 -f "$PRIVATE_KEY_FILENAME" -N "" -q
#docker-compose pull --include-deps sbt
docker-compose -f local-test/docker-compose.yml up -d sshd

docker cp "$PUBLIC_KEY_FILENAME" test_sshd:/root/.ssh/authorized_keys
docker exec test_sshd chown root:root /root/.ssh/authorized_keys

docker-compose -f local-test/docker-compose.yml run --service-ports sbt
