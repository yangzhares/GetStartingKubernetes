#!/bin/sh

KUBE_LOGTOSTDERR=true
KUBE_LOG_LEVEL=4
KUBE_ETCD_SERVERS=http://192.168.230.3:4001
MINION_ADDRESS=192.168.230.4
MINION_PORT=10250
MINION_HOSTNAME=192.168.230.4
KUBE_ALLOW_PRIV=false

cat <<EOF >/usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.socket cadvisor.service
Requires=docker.socket

[Service]
ExecStart=/opt/kubernetes/bin/kubelet \\
    --logtostderr=${KUBE_LOGTOSTDERR} \\
    --v=${KUBE_LOG_LEVEL} \\
    --etcd_servers=${KUBE_ETCD_SERVERS} \\
    --address=${MINION_ADDRESS} \\
    --port=${MINION_PORT} \\
    --hostname_override=${MINION_HOSTNAME} \\
    --allow_privileged=${KUBE_ALLOW_PRIV}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet