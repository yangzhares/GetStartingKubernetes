#!/bin/sh

KUBE_LOGTOSTDERR=true
KUBE_LOG_LEVEL=4
KUBE_BIND_ADDRESS=192.168.230.4
KUBE_ETCD_SERVERS=http://192.168.230.3:4001

cat <<EOF >/usr/lib/systemd/system/proxy.service
[Unit]
Description=Kubernetes Proxy
# the proxy crashes if etcd isn't reachable.
# https://github.com/GoogleCloudPlatform/kubernetes/issues/1206
After=network.target

[Service]
ExecStart=/opt/kubernetes/bin/proxy \\
    --logtostderr=${KUBE_LOGTOSTDERR} \\
    --v=${KUBE_LOG_LEVEL} \\
    --bind_address=${KUBE_BIND_ADDRESS} \\
    --etcd_servers=${KUBE_ETCD_SERVERS} 
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable proxy
systemctl start proxy