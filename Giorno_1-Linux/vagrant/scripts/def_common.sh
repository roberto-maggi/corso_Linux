#!/bin/bash

# Common setup for all servers (Control Plane and Nodes)

set -euxo pipefail

systemctl set-default multi-user.target
export DEBIAN_FRONTEND=noninteractive
apt -y update
apt install -y bzip2 chrony net-tools vim net-tools console-data bash-completion ufw tree git systemd-resolved parted
apt -y remove apparmor

ufw disable 

if test -e /usr/sbin/iptables ;
	then
		iptables -F
		iptables -X ;
fi

# there's a bug in debian/ubuntu on keymap ...
# wget https://mirrors.edge.kernel.org/pub/linux/utils/kbd/kbd-2.5.1.tar.gz -O /tmp/kbd-2.5.1.tar.gz
# cd /tmp/ && tar xzf kbd-2.5.1.tar.gz
# cp -Rp /tmp/kbd-2.5.1/data/keymaps/* /usr/share/keymaps/
# localectl set-keymap it
# rm -fr /tmp/kbd-*

# user 		vagrant
# password 	vagrant
usermod -aG sudo vagrant
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
echo -e '%sudo   ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

# ssh setup
mkdir -p /etc/systemd/system/ssh.socket.d/
echo -e "[Socket]" > /etc/systemd/system/ssh.socket.d/listen.conf 
echo -e "ListenStream=22" >> /etc/systemd/system/ssh.socket.d/listen.conf
sed -i 's/^#Port 22/Port 22/g' /etc/ssh/sshd_config
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

# DNS Setting
if [ ! -d /etc/systemd/resolved.conf.d ]; then
	sudo mkdir /etc/systemd/resolved.conf.d/
fi
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF

sudo systemctl restart systemd-resolved

# disable swap
# sudo swapoff -a

# keeps the swaf off during reboot
# (crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

sysctl -w net.ipv4.icmp_echo_ignore_all=1
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv4.ip_forward=1
for NIC in $(ip -br a s | awk '{print $1}') ; do
	sysctl -w net.ipv6.conf.$NIC.disable_ipv6=1 ;
	done
sysctl -p

