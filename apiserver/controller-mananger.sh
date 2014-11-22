#!/bin/sh

KUBE_LOGTOSTDERR=true
KUBE_LOG_LEVEL=4
KUBE_MASTER=192.168.230.3:8080

cat <<EOF >/usr/lib/systemd/system/controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/opt/kubernetes/bin/controller-manager \\
    --logtostderr=${KUBE_LOGTOSTDERR} \\
    --v=${KUBE_LOG_LEVEL} \\
	--machines=${MINION_ADDRESSES} \\
    --master=${KUBE_MASTER}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable controller-manager
systemctl start controller-manager