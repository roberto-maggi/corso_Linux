
cp -a /vagrant_data/cluster/keepalived/ /etc/
chmod 0700  /etc/keepalived/
chmod 0400 /etc/keepalived/keepalived.conf
chmod 0100 /etc/keepalived/check_ha.sh
cp -a /vagrant_data/cluster/haproxy /etc
chmod 0700  /etc/haproxy/
chmod 0400  /etc/haproxy/haproxy.cfg
