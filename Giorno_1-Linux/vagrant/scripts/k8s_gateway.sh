#!/bin/bash
#
systemctl set-default multi-user.target
export DEBIAN_FRONTEND=noninteractive
apt -y update
apt install -y bzip2 chrony net-tools vim net-tools console-data bash-completion ufw tree git systemd-resolved parted ca-certificates curl
systemctl disable --now apparmor
apt -y remove apparmor

# FIREWALL 

ufw disable 

if test -e /usr/sbin/iptables ;
	then
		iptables -F
		iptables -X ;
fi

sysctl net.ipv6.conf.all.disable_ipv6=1 > /dev/null
sysctl net.ipv6.conf.default.disable_ipv6=1 > /dev/null
for NIC in $(ip -br a s  | grep -vE '(br-|docker|vbo|tun|lo)'|awk '{print $1}') ; do
    sysctl net.ipv4.conf.$NIC.forwarding=1 > /dev/null
    sysctl net.ipv6.conf.$NIC.disable_ipv6=1 > /dev/null; done
sysctl --system > /dev/null

IPT="/sbin/iptables"

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#SSH
iptables -A INPUT -i $PUB_IN -p tcp --dport 22 -j ACCEPT

iptables -I FORWARD -i $PUB_IN -o $PRIV_OUT -j ACCEPT
iptables -I FORWARD -i $PRIV_OUT -o $PUB_IN -j ACCEPT

# $IPT -t nat -A POSTROUTING -o $IF_OUT -j MASQUERADE
# $IPT -A FORWARD -i $IF_IN -o $IF_OUT -j ACCEPT
# $IPT -A FORWARD -m state --state RELATED,ESTABLISHED -i $IF_OUT -o $IF_IN -j ACCEPT


# there's a bug in debian/ubuntu on keymap ...
# wget https://mirrors.edge.kernel.org/pub/linux/utils/kbd/kbd-2.5.1.tar.gz -O /tmp/kbd-2.5.1.tar.gz
# cd /tmp/ && tar xzf kbd-2.5.1.tar.gz
# cp -Rp /tmp/kbd-2.5.1/data/keymaps/* /usr/share/keymaps/
# localectl set-keymap it
# rm -fr /tmp/kbd-*

# user 		vagrant
# password 	vagrant
usermod -aG vagrant
chmod 700 /home/vagrant/		
ln -sf /vagrant/ /home/vagrant/
mkdir -p /home/vagrant/.ssh
chmod -R 700 /home/vagrant/.ssh
cp -a /home/vagrant/vagrant/keys/* /home/vagrant/.ssh/
chmod 600 /home/vagrant/.ssh/*
chown -R vagrant:vagrant /home/vagrant/
# root 
ln -sf /vagrant/ /root/
mkdir -p /root/.ssh
cp -a /home/vagrant/vagrant/keys/* /root/.ssh/
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
chown -R root:root /root
# change root settings and password
# ROOT PASSWORD IS "vagrant"
sed -i '/root/d' /etc/shadow
sed -i '/root/d' /etc/passwd
echo -e 'root:$y$j9T$QRUL1vvFTES9KBZQPTbmU0$0UP00dtIsELRf7b2p4YnTZ3TfytpD9ty49VA63Ko4.9:19874:0:99999:7:::' >> /etc/shadow
echo -e 'root:x:0:0:root:/root:/bin/bash' >> /etc/passwd
# VIM
# users=(vagrant)
# for x in ${users[@]}; 
# 	do
# 		echo -e 'set mouse-=a' >> /home/$x/.vimrc
# 		echo -e 'syntax on' >> /home/$x/.vimrc
# 		echo -e 'colorscheme desert' >> /home/$x/.vimrc
# 		mkdir -p /.vim /home/${users[$x]}/.vim/colors;
# done
echo -e 'set mouse-=a' >> ~/.vimrc
echo -e 'syntax on' >> ~/.vimrc
echo -e 'colorscheme desert' >> ~/.vimrc
mkdir -p /.vim ~/.vim/colors;

# chrony
cp -a /vagrant/files/chrony.conf /etc/chrony/
chronyc -a makestep
systemctl restart chrony

# give system wide access to sudoers
sed -i '/sudo/d' /etc/sudoers
echo -e '%  ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

# ssh setup
mkdir -p /etc/systemd/system/ssh.socket.d/
echo -e "[Socket]" > /etc/systemd/system/ssh.socket.d/listen.conf 
echo -e "ListenStream=9222" >> /etc/systemd/system/ssh.socket.d/listen.conf
sed -i 's/^#Port 22/Port 9222/g' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin/PermitRootLogin/g' /etc/ssh/sshd_config
sed -i 's/prohibit-password/yes/g' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication/PubkeyAuthentication/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/#Port/Port/g' /etc/ssh/sshd_config
sed -i 's/#AllowAgentForwarding/AllowAgentForwarding/g' /etc/ssh/sshd_config
systemctl daemon-reload
cp /vagrant/files/ssh_restart.sh /root/ssh_restart.sh
chmod +x /root/ssh_restart.sh
/root/ssh_restart.sh &

# Common setup for all servers (Control Plane and Nodes)

set -euxo pipefail

# Variable Declaration

# DNS Setting
if [ ! -d /etc/systemd/resolved.conf.d ]; then
	mkdir -p /etc/systemd/resolved.conf.d/
fi
cat <<EOF | tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF

systemctl restart systemd-resolved

# enable swap
swapon -a

# install and configure docker
# mkdir -p /etc/docker /mnt/docker-data/docker
# cat > /etc/docker/daemon.json << EOL
# {
#   "bip": "10.0.1.1/24",
#   "ipv6": false,
#   "default-address-pools": [
#     { "base": "10.0.64.0/18", "size": 24 }
#   ],
#   "data-root": "/mnt/docker-data/docker"
# }
# EOL

# install -m 0755 -d /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
# chmod a+r /etc/apt/keyrings/docker.asc
# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
#   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#   tee /etc/apt/sources.list.d/docker.list > /dev/null
# apt-get update -y

# apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/

# # install gitlab
# cd /opt
# git clone git@github.com:roberto-maggi/CI-CD.git
# ln -sf /opt/CI-CD/Giorno_2_Docker/gitlab/ ./gitlab
# GITLAB_HOME=/opt/gitlab
# cd $GITLAB_HOME
# mkdir -p data logs config/gitlab-runner
# touch config/gitlab-runner/config.toml
# GITLAB_HOME=/opt/gitlab/ docker-compose -d up

