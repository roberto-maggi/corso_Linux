#!/bin/bash
#

## install nfs
apt -y install nfs-kernel-server
mkdir -p /nfs
echo -e "/nfs *(rw,sync,no_root_squash,no_subtree_check)"  > /etc/exports
exportfs -ra 

# Setup for Control Plane (Master) servers

set -euxo pipefail

NODENAME=$(hostname -s)

#  Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

config_path="/vagrant/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi
