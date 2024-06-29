#!/bin/bash

while true; do
    if [ $# -eq 0 ]; then
        echo "select master/worker"
        read -p "Enter master/worker: " input
        set -- "$input"
    else
        if [ "$1" != "master" ] && [ "$1" != "worker" ]; then
            echo "select master/worker"
            read -p "Enter master/worker: " input
            set -- "$input"
        fi
    fi

    if [ "$1" = "master" ]; then
        echo "Master $1"
        break
    elif [ "$1" = "worker" ]; then
        echo "Worker $1"
        break
    fi
done

echo "Kubernetes setting"
echo "update"
sudo apt-get update
sudo apt-get upgrade -y

echo "disable swap memory"
free -h
sudo swapoff -a
sudo rm /swap.img
sed -i '/swap/s/^/#/' /etc/fstab

echo "ufw settings"
if [ "$1" = "master" ]; then
    systemctl start ufw
    sudo ufw enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 6443/tcp
    sudo ufw allow 2379:2380/tcp
    sudo ufw allow 10250/tcp
    sudo ufw allow 10259/tcp
    sudo ufw allow 10257/tcp
    sudo ufw allow from 10.0.0.0/8
    sudo ufw allow from 172.16.0.0/12
    sudo ufw allow from 192.168.0.0/16
    sudo ufw reload
elif [ "$1" = "worker" ]; then
    systemctl start ufw
    sudo ufw enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 10250/tcp
    sudo ufw allow 30000:32767/tcp
    sudo ufw allow 10256/tcp
    sudo ufw allow from 10.0.0.0/8
    sudo ufw allow from 172.16.0.0/12
    sudo ufw allow from 192.168.0.0/16
    sudo ufw reload
fi

echo "Installing docker"
apt-get install docker.io -y

echo "set containerd"
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

echo "set iptables"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
sudo systemctl restart containerd

echo"Get kubernetes"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo"Installing kubernetes"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

if [ "$1" = "master" ]; then
    echo "do you want to init cluster with flannel?[y/n]"
    read -p "Enter y/n: " input
    answer="$input"
    
    if [ "$answer" = "y" ]; then
        echo "Init cluster"
        sudo kubeadm init --pod-network-cidr=10.244.0.0/16

        echo "Kubectl enabled"
        export KUBECONFIG=/etc/kubernetes/admin.conf
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

        echo "Installing Flannel"
        kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    elif [ "$answer" = "n" ]; then
        exit 1
    fi
fi
