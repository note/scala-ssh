#!/bin/sh

# enable job control
set -m

function write_scala_ssh_config() {
  local PORT="$1"
  echo "write_scala_ssh_config: $PORT"

  mkdir ~/.scala-ssh
  echo localhost > ~/.scala-ssh/.testhost
  FULLPATH="$(pwd)/id_ed25519"

  cat <<EOF >  ~/.scala-ssh/localhost
login-type  = keyfile
username    = root
keyfile     = $FULLPATH
port        = $PORT
EOF
}

cd ci

ssh-keygen -t ed25519 -f id_ed25519 -N "" -q

#mkdir -p volumes/sshd
#cp id_ed25519.pub volumes/sshd
#mv volumes/sshd/id_ed25519.pub volumes/sshd/authorized_keys

#ls -al volumes
#cat volumes/authorized_keys

docker pull rastasheep/ubuntu-sshd:16.04
docker run -d -P --name test_sshd rastasheep/ubuntu-sshd:16.04

docker ps -a

# Just to be sure sshd started
sleep 9

docker ps -a
docker --version

docker cp id_ed25519.pub test_sshd:/root/.ssh/authorized_keys
docker exec test_sshd chown root:root /root/.ssh/authorized_keys

CONTAINER_ID=`docker ps -a -q`
echo "sshd container_id detected: $CONTAINER_ID"
SSHD_PORT=`docker inspect --format '{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' "$CONTAINER_ID"`
echo "sshd ephemeral port detected: $SSHD_PORT"
write_scala_ssh_config $SSHD_PORT

ssh-keyscan -t ed25519 -p "$SSHD_PORT" localhost >>~/.ssh/known_hosts

cd ..
sbt test