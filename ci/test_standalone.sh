#!/bin/sh

# enable job control
set -m

function write_scala_ssh_config() {
  local PORT="$1"
  echo "write_scala_ssh_config: $PORT"

  cat <<EOF >  ~/.scala-ssh/localhost
login-type  = keyfile
username    = root
keyfile     = id_ed25519
port        = $PORT
EOF
}

rm -rf ci/volumes

ssh-keygen -t ed25519 -f id_ed25519 -N "" -q

mkdir -p ci/volumes/client
cp id_ed25519.pub ci/volumes/
mv ci/volumes/id_ed25519.pub ci/volumes/authorized_keys

docker-compose -f ci/docker-compose.yml up sshd &

# Just to be sure sshd started
sleep 1

CONTAINER_ID=`docker ps -a -q`
echo "sshd container_id detected: $CONTAINER_ID"
SSHD_PORT=`docker inspect --format '{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' "$CONTAINER_ID"`
echo "sshd ephemeral port detected: $SSHD_PORT"
write_scala_ssh_config $SSHD_PORT

ssh-keyscan -t ed25519 -p "$SSHD_PORT" localhost >>~/.ssh/known_hosts

sbt test