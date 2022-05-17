#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

source /etc/packer/files/functions.sh

# wait for cloud-init to finish
wait_for_cloudinit

# upgrade the operating system
#apt-get update -y && apt-get upgrade -y
apt-get update

# install dependencies
apt-get install -y \
    ca-certificates \
    curl \
    auditd \
    parted \
    unzip \
    lsb-release

#install_jq

# enable audit log
systemctl enable auditd && systemctl start auditd

# enable the /etc/environment
configure_http_proxy

# install aws cli
#install_awscliv2

# install ssm agent
#install_ssmagent

# partition the disks
systemctl stop rsyslog irqbalance polkit
partition_disks /dev/nvme1n1

mkdir -p /etc/eks/containerd
mv /tmp/containerd-config.toml /etc/eks/containerd
mv /tmp/kubelet-containerd.service /etc/eks/containerd
mv /tmp/pull-sandbox-image.sh /etc/eks/containerd
mv /tmp/sandbox-image.service /etc/eks/containerd
chmod +x /etc/eks/containerd/pull-sandbox-image.sh

# Setting resolv.conf for the node
rm -rf /etc/resolv.conf
sed -i 's/#DNS=/DNS=10.1.0.2/g' /run/systemd/resolve/resolv.conf
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-resolved

reboot
