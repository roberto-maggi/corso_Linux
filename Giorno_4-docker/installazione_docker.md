## setup corretto

```
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOL
{
  "bip": "10.0.1.1/24",
  "ipv6": false,
  "default-address-pools": [
    { "base": "10.0.64.0/18", "size": 24 }
  ],
  "data-root": "/mnt/docker-data/docker"
}
EOL
```

## installazione corretta su Debian
```
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/
```
## pulisci tutto
```
systemctl stop docker.socket
systemctl stop docker.service

systemctl status docker.service --no-pager | head  -5
systemctl status docker.socket --no-pager | head  -5

for PKG in $(dpkg -l | grep -Ei '(docker|runc|conteiner)'  | awk '{print $2}') ; do apt -y remove $PKG ; done
apt autoremove -y
for BR in $( ip --brief a s | grep br- | awk '{print $1}' ) ; do ip link delete $BR ; done
ip link delete docker0
```