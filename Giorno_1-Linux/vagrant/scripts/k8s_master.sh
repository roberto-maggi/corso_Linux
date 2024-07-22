#!/bin/bash
#

## install nfs
apt -y install nfs-kernel-server
mkdir -p /nfs
echo -e "/nfs *(rw,sync,no_root_squash,no_subtree_check)"  > /etc/exports
exportfs -ra 

# primo script
echo "#\!/bin/bash \necho -e 'hello world!'" > hello.sh && chmod +x ./hello.sh

# Setup for Control Plane (Master) servers

set -euxo pipefail

NODENAME=$(hostname -s)

sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

sudo kubeadm init --apiserver-advertise-address=$CONTROL_IP --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Save Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

config_path="/vagrant/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh

kubeadm token create --print-join-command > $config_path/join.sh

# Install Calico Network Plugin

curl https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml -O

kubectl apply -f calico.yaml

sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF

# Install Metrics Server
# kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# download the lecture's repo
cd /opt
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" git clone git@github.com:roberto-maggi/CI-CD.git

# install MetalLB
# kubectl --kubeconfig=/etc/kubernetes/admin.conf get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl --kubeconfig=/etc/kubernetes/admin.conf diff -f - -n kube-system
# kubectl --kubeconfig=/etc/kubernetes/admin.conf get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f - -n kube-system  
# kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
# kubectl apply -f  /opt/CI-CD/Giorno_3_k8s/manifesti/metal-lb/IPaddress-pool.yaml
# kubectl apply -f  /opt/CI-CD/Giorno_3_k8s/manifesti/metal-lb/L2Advertisement.yaml

# deploy nfs provisioner
# kubectl apply -f  /opt/CI-CD/Giorno_3_k8s/manifesti/nfs-provioner/nuovo/dynamic_subdir.yml

# install nginx on 10.0.0.245 ( LB )
# kubectl apply -f   /opt/CI-CD/Giorno_3_k8s/manifesti/nginx/nginx+pvc+lb.yml