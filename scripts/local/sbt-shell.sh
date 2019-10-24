#!/bin/bash

PRIVATE_KEY_FILENAME="id_ed25519"

function write_scala_ssh_config() {
  local PORT="$1"
  echo "write_scala_ssh_config: $PORT"

  mkdir ~/.scala-ssh
  echo sshd > ~/.scala-ssh/.testhost
  FULLPATH=`realpath $PRIVATE_KEY_FILENAME`

  cat <<EOF >  ~/.scala-ssh/sshd
login-type  = keyfile
username    = root
keyfile     = $FULLPATH
port        = $PORT
EOF
}

write_scala_ssh_config 22

mkdir ~/.ssh
ssh-keyscan -t ed25519 -p 22 sshd >>~/.ssh/known_hosts

sbt shell
