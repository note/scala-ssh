#!/bin/bash

# enable job control
set -m

PRIVATE_KEY_FILENAME="id_ed25519"
PUBLIC_KEY_FILENAME="id_ed25519.pub"
DOCKER_IMAGE_NAME="rastasheep/ubuntu-sshd:16.04"

function write_scala_ssh_config() {
  local PORT="$1"
  echo "write_scala_ssh_config: $PORT"

  mkdir ~/.scala-ssh
  echo localhost > ~/.scala-ssh/.testhost
  FULLPATH=`realpath $PRIVATE_KEY_FILENAME`

  cat <<EOF >  ~/.scala-ssh/localhost
login-type  = keyfile
username    = root
keyfile     = $FULLPATH
port        = $PORT
EOF
}

ssh-keygen -t ed25519 -f "$PRIVATE_KEY_FILENAME" -N "" -q

docker pull "$DOCKER_IMAGE_NAME"
docker run -d -P --name test_sshd "$DOCKER_IMAGE_NAME"

# Just to be sure sshd started
RETRIES_LEFT=15
COMMAND_STATUS=1
until { [ $COMMAND_STATUS -eq 0 ] || [ $RETRIES_LEFT -eq 0 ]; }; do
  echo "checking if sshd is up: $RETRIES_LEFT"
  docker ps -a | grep test_sshd
  COMMAND_STATUS=$?
  sleep 2
  let RETRIES_LEFT=RETRIES_LEFT-1
done

docker cp "$PUBLIC_KEY_FILENAME" test_sshd:/root/.ssh/authorized_keys
docker exec test_sshd chown root:root /root/.ssh/authorized_keys

# returns e.g. 0.0.0.0:32875
SSHD_HOST_PORT=`docker port test_sshd 22`

# returns e.g. 32875, uses https://stackoverflow.com/a/3162500/429311
SSHD_PORT=${SSHD_HOST_PORT##*:}
echo "sshd ephemeral port detected: $SSHD_PORT"
write_scala_ssh_config $SSHD_PORT

ssh-keyscan -t ed25519 -p "$SSHD_PORT" localhost >>~/.ssh/known_hosts

sbt test
