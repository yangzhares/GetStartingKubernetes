#!/bin/sh

DOCKER_BRIDGE=kbr0
DOCKER_CONFIG=/etc/sysconfig/docker

cat <<EOF >$DOCKER_CONFIG
OPTIONS=--selinux-enabled=false
EOF

cat <<EOF >/usr/lib/systemd/system/docker.socket
[Unit]
Description=Docker Socket for the API

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

source $DOCKER_CONFIG
cat <<EOF >/usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target docker.socket
Requires=docker.socket

[Service]
Type=notify
EnvironmentFile=-$DOCKER_CONFIG
ExecStart=/usr/bin/docker -d --bridge=$DOCKER_BRIDGE -H fd:// $OPTIONS
LimitNOFILE=1048576
LimitNPROC=1048576

[Install]
Also=docker.socket
EOF

systemctl daemon-reload
systemctl enable docker
systemctl start docker
