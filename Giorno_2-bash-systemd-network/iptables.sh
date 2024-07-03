#!/bin/bash

###########################
# Imposto alcune variabili
###########################

# Il path di iptables
IPT="/sbin/iptables"

# Interfacce di rete esterna
IFACES=("enp43s0" "wlp0s20f3")

# VARS per FOWARDING 
IF_IN=wlp0s20f3
IF_OUT=tun0
IP_OUT=$(ip --brief a s tun0 | awk '{print $3}'  | sed -e 's/\/24//g')

count=0

sysctl net.ipv4.conf.wlp0s20f3.forwarding=1 > /dev/null
sysctl net.ipv6.conf.wlp0s20f3.forwarding=1 > /dev/null
sysctl net.ipv4.conf.tun0.forwarding=1 > /dev/null
sysctl net.ipv6.conf.tun0.forwarding=1 > /dev/null
sysctl --system > /dev/null

########################
# Un messaggio di avvio
########################

echo -n " Loading iptables rules"

#####################################
# Pulisco la configurazione corrente
#####################################

# Cancellazione delle regole presenti nelle chains
$IPT -F
$IPT -F -t nat
# Eliminazione delle chains non standard vuote
$IPT -X
# Inizializzazione dei contatori (utile per il debugging)
$IPT -Z
let count++
echo -n " $count "

###################################################
# Blocco tutto il traffico tranne quello in uscita.
# NOTA: per ragioni di sicurezza sarebbe opportuno
# bloccare anche il traffico in uscita e stabilire
# poi delle regole selettive
###################################################

$IPT -P INPUT DROP
$IPT -P FORWARD DROP
$IPT -P OUTPUT ACCEPT
let count++
echo -n " $count "

##############################
# Abilito il traffico locale
##############################

$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT
let count++
echo -n " $count "

#####################################################
# Imposto alcune regole per i pacchetti ICMP di ping
#####################################################

$IPT -A INPUT -p icmp --icmp-type echo-reply -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/s -m state --state NEW -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type destination-unreachable -m state --state NEW -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type time-exceeded -m state --state NEW -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type timestamp-request -m state --state NEW -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type timestamp-reply -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
$IPT -A OUTPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
let count++
echo -n " $count "

###############################################
# Mi difendo dallo spoofing
###############################################

# $IPT -A INPUT -s 10.0.0.0/8 -j DROP # RETE DI DOCKER 
$IPT -A INPUT -s 169.254.0.0/16 -j DROP
$IPT -A INPUT -s 172.16.0.0/12 -j DROP
$IPT -A INPUT -s 127.0.0.0/8 -j DROP
$IPT -A INPUT -s 192.168.0.0/24 -j DROP
# $IPT -A INPUT -s 192.168.1.0/24 -j DROP # RETE di CASA
$IPT -A INPUT -s 192.168.10.0/24 -j DROP
$IPT -A INPUT -s 224.0.0.0/4 -j DROP
$IPT -A INPUT -d 224.0.0.0/4 -j DROP
$IPT -A INPUT -s 240.0.0.0/5 -j DROP
$IPT -A INPUT -d 240.0.0.0/5 -j DROP
$IPT -A INPUT -s 0.0.0.0/8 -j DROP
$IPT -A INPUT -d 0.0.0.0/8 -j DROP
$IPT -A INPUT -d 239.255.255.0/24 -j DROP
$IPT -A INPUT -d 255.255.255.255 -j DROP
let count++
echo -n " $count "

########################################
# Mi proteggo da attacchi SMURF
########################################

$IPT -A INPUT -p icmp -m icmp --icmp-type address-mask-request -j DROP
$IPT -A INPUT -p icmp -m icmp --icmp-type timestamp-request -j DROP
$IPT -A INPUT -p icmp -m icmp  --icmp-type 8 -m limit --limit 1/second -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --tcp-flags RST RST -m limit --limit 2/second --limit-burst 2 -j ACCEPT
let count++
echo -n " $count "
#####################################
# Elimino pacchetti non validi
#####################################

$IPT -A INPUT -m state --state INVALID -j DROP
$IPT -A FORWARD -m state --state INVALID -j DROP
$IPT -A OUTPUT -m state --state INVALID -j DROP
let count++
echo -n " $count "

##############################################
# Impedisco i port scan e loggo i tentativi
# Gli IP sono bloccati per 24 ore
##############################################

$IPT -A INPUT -m recent --name portscan --rcheck --seconds 86400 -j DROP
$IPT -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP
$IPT -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j LOG --log-prefix "portscan:"
$IPT -A INPUT -p tcp -m tcp --dport 139 -m recent --name portscan --set -j DROP
let count++
echo -n " $count "

###############################################
# Blocco le nuove connessioni senza SYN e
# mi proteggo dagli attacchi Denial of Service
###############################################

$IPT -N syn-flood
for NIC in $IFACES; do 
$IPT -A INPUT -i $NIC -p tcp --syn -j syn-flood ; done
$IPT -A syn-flood -m limit --limit 1/s --limit-burst 4 -j RETURN
$IPT -A syn-flood -j DROP
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
let count++
echo -n " $count "

#########################################################
# Consento il traffico delle connessioni gia' stabilite
#########################################################

$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
let count++
echo -n " $count "

#########################################################
# Regole sulle porte. Da modificare secondo le esigenze
# Per ogni regola nel commento viene indicato:
# 1) il numero della porta
# 2) il nome del servizio
# 3) il protocollo
# 4) il livello di accesso
#    - pubblico = accesso permesso a tutti
#    - LAN = accesso permesso solo ai client della LAN
#########################################################

# 21 - ProFTPD - FTP - pubblico
# $IPT -A INPUT -p tcp --dport 21 -m state --state NEW -j ACCEPT
# Abilito le porte dinamiche. Configurare correttamente la
# direttiva PassivePorts in /etc/proftpd/proftpd.conf
# $IPT -A INPUT -m state --state NEW -m tcp -p tcp --dport 60000:65000 -j ACCEPT

# 25 - Postfix - SMTP - pubblico
# $IPT -A INPUT -p tcp --dport 25 -m state --state NEW -j ACCEPT

# 80/443 - Apache - HTTP - pubblico
$IPT -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
$IPT -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT

# 110 - Dovecot - POP3 - pubblico
# $IPT -A INPUT -p tcp --dport 110 -m state --state NEW -j ACCEPT

# 111 - Ulogd - Syslog Server - LAN
# $IPT -A INPUT -p tcp --dport 111 -m state --state NEW -s 192.168.90.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 111 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 111 -m state --state NEW -s 192.168.90.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 111 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 143 - Dovecot - IMAP - pubblico
# $IPT -A INPUT -p tcp --dport 143 -m state --state NEW -j ACCEPT

# 667 - Darkstat - Statistiche - LAN
# $IPT -A INPUT -p tcp --dport 667 -m state --state NEW -s 192.168.90.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 667 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 993 - Dovecot - IMAPs - pubblico
# $IPT -A INPUT -p tcp --dport 993 -m state --state NEW -j ACCEPT

# 995 - Dovecot - POP3s - pubblico
# $IPT -A INPUT -p tcp --dport 995 -m state --state NEW -j ACCEPT

# 1050/1051 - Zabbix - Monitor - LAN
# $IPT -A INPUT -p tcp --dport 1050 -m state --state NEW -s 192.168.90.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 1050 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 1051 -m state --state NEW -s 192.168.90.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 1051 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 1194 - OpenVPN - pubblico
# $IPT -A INPUT -p tcp --dport 1194 -m state --state NEW -j ACCEPT


# 2000 - Sieve - Spam filter - localhost
# Non ha bisogno di configurazione

# 2293 - OpenSSH - SSH - pubblico
$IPT -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT
$IPT -A INPUT -p tcp --dport 9222 -m state --state NEW -j ACCEPT

# 2605 - BitMeter - Monitor - LAN
# $IPT -A INPUT -p tcp --dport 2605 -m state --state NEW -s 192.168.90.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 2605 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 2812 - Monit - Monitor - LAN
# $IPT -A INPUT -p tcp --dport 2812 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 3000 - ntop - Monitor - LAN
# $IPT -A INPUT -p tcp --dport 3000 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 3306 - MySQL - localhost
# Non ha bisogno di configurazione

# 10000  Webmin - Monitor - LAN
# $IPT -A INPUT -p tcp --dport 10000 -m state --state NEW -s 192.168.90.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 10000 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 10024/10025 - Amavis - localhost
# Non ha bisogno di configurazione

# 8980 - OpenNMS - Server Monitor - LAN
# $IPT -A INPUT -p tcp --dport 8980 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 8980 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 9000 - 9200 - 9300 - 8514 - GrayLOG - LOG Monitor - LAN
# $IPT -A INPUT -p tcp --dport 9000 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 9200 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 9300 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 8514 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 9000 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 9200 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 9300 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 8514 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 5353 mDNS - LAN
# $IPT -A INPUT -p udp -m udp --dport 5353 --sport 5353 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 67-68 DHCP - LAN
# $IPT -A INPUT -p udp -m udp --dport 67 --sport 68 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 4200 - Shell in a Box - LAN
# $IPT -A INPUT -p tcp --dport 4200 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 4200 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# 173 - 138 - 139 - 445 - 389 - 901 - Samba - LAN
# $IPT -A INPUT -p tcp --dport 137 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 137 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 138 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 138 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 139 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 139 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 445 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 445 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 389 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 389 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p tcp --dport 901 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT
# $IPT -A INPUT -p udp --dport 901 -m state --state NEW -s 10.0.0.0/24 -j ACCEPT

# NFS 
$IPT -A INPUT -s 192.168.1.0/24 -m state --state NEW -p udp --dport 111 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 111 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24 -m state --state NEW -p tcp --dport 2049 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24  -m state --state NEW -p tcp --dport 32803 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24  -m state --state NEW -p udp --dport 32769 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24  -m state --state NEW -p tcp --dport 892 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24  -m state --state NEW -p udp --dport 892 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24  -m state --state NEW -p tcp --dport 875 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24  -m state --state NEW -p udp --dport 875 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24  -m state --state NEW -p tcp --dport 662 -j ACCEPT
$IPT -A INPUT -s 192.168.1.0/24 -m state --state NEW -p udp --dport 662 -j ACCEPT
let count++
echo -n " $count "

###############################################################
# Regole di sicurezza
# Block fragments and Xmas tree as well as SYN,FIN and SYN,RST
###############################################################

$IPT -A INPUT -p ip -f -j DROP
$IPT -A INPUT -p tcp --tcp-flags ALL ACK,RST,SYN,FIN -j DROP
$IPT -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
$IPT -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
let count++
echo -n " $count "

###############################################################
# Regole per il FORWARDING
###############################################################

$IPT -t nat -A POSTROUTING -o $IF_OUT -j MASQUERADE
$IPT -A FORWARD -i $IF_IN -o $IF_OUT -j ACCEPT
$IPT -A FORWARD -m state --state RELATED,ESTABLISHED -i $IF_OUT -o $IF_IN -j ACCEPT
let count++
echo -n " $count "

###############################
# Concludo lo script firewall
###############################

echo -n "done."

