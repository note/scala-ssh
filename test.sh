#!/bin/sh

rm -rf volumes/authorized_keys
rm -rf volumes/client

ssh-keygen -t ecdsa -f id_ecdsa -N "" -q

mkdir -p volumes/client
cp id_ecdsa.pub volumes/
mv volumes/id_ecdsa.pub volumes/authorized_keys
cp id_ecdsa volumes/client/

docker-compose run sbt
