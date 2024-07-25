*****************************
# Giorno 1
*****************************
## Linux:
### Cos'e' differenze tra windows e linux

### Sistema operativo VS Kernel

### Linux Distros

    https://truelist.co/wp-content/uploads/2022/01/Top-Linux-Subcategories-by-Market_Share.jpg
    https://upload.wikimedia.org/wikipedia/commons/1/1b/Linux_Distribution_Timeline.svg

### Installare Linux Debian

    https://download.virtualbox.org/virtualbox/7.0.18/VirtualBox-7.0.18-162988-Win.exe
    https://developer.hashicorp.com/vagrant/install?product_intent=vagrant
    https://download.mobatek.net/2412024041614011/MobaXterm_Installer_v24.1.zip
    https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-microsoft-visual-c-redistributable-version
    https://www.debian.org/

### Controllare i componenti del sistema

    setup tastiera
    dpkg-reconfigure keyboard-configuration
    setupcon
    
    cpu         lscpu
    pci         lspci
    usb         lsusb
    ram         free
    sensori     inxi    
    tutto       hwinfo
                cat /proc/  cpu*
                            mem*
                            partitions*
    manipolare 
        le nic
                ifconfig
                - show
                    ip
                    ip -br a s 
                    ip a show dev <dev>
                - status
                    ip link set dev {DEVICE} {up|down}
                - addresses
                    ip a add 192.168.1.200/24 dev eth0
                    ip a del 192.168.1.200/24 dev eth0
                - maximum transmission units (MTU)
                    ip link set mtu 9000 dev eth0 && ip a list eth0
                - routing
                    ip r list 192.168.1.0/24
                    ip route add 192.168.1.0/24 via 192.168.1.254
                    ip route add 192.168.1.0/24 dev eth0

    storage     lsblk
    manipolare
        dischi  fdisk / cfdisk / blkid
        spazio
         disco  df -hs / du -h
         updatedb & locate
         find

    cartelle e mountpoint
        mount / findmnt

Controllare i processi di sistema e le risorse
    
    ps / htop / kill - kilall

     1) SIGHUP 2) SIGINT 3) SIGQUIT	4) SIGILL 5) SIGTRAP 6) SIGABRT	7) SIGBUS 8) SIGFPE
     9) SIGKILL	10) SIGUSR1 11) SIGSEGV 12) SIGUSR2	13) SIGPIPE	14) SIGALRM	15) SIGTERM

   -15 SIGTERM quando si vuole uccidere "gracefully" un processo, cioe' permettendo
    al programma di salvare i propri dati e chiudersi correttamente   
   -9 SIGKILL lo uccide immediatamente e forzatamente, abbandonando dati a loro stessi
    senza tenere conto di eventuali possibili controindicazioni
   -1 SIGHUP usato per "riavviare un PID senza passare dal chiudere il programma 
    che lo ha gerato
    `kill -SIGHUP $(cat /var/run/sshd.pid)`
 

### Creare e gestire il Filesystem Linux

### Tipi di FS
xfs ext* reiserfs
### files di testo e device file
- editor di testo: vim

### LAB

### lvm
- aggiunta di dischi e creazione lvm
        - sulla VM 1
            spegni le vm e aggiungi due dischi
            pvscan
```
for x in /sys/class/scsi_host/host* ; do echo "- - -" > $x/scan && echo " test ->  $x/scan" ; done
dmesg -dT | egrep -i '(detected capacity change|Attached SCSI disk)'|tail -n 1
fdisk /dev/sdb
partprobe /dev/sdb se il primo non funziona usa -> partx -av /dev/sdb1
pvcreate /dev/sdb1
VG=VolGr1
LV=LogVol1
vgcreate $VG /dev/sdb1
vgs
lvcreate -n $LV -l +100%free $VG
LV_MAP=$(ls /dev/mapper/ | grep $LV )
mkfs.ext4 /dev/mapper/$LV_MAP
lsblk
pvcreate /dev/sdc
vgextend $VG /dev/sdc
lvextend -r -l +100%free /dev/mapper/$LV_MAP
cp -av /etc/fstab /etc/fstab.bak
echo "$(blkid /dev/mapper/$LV_MAP | awk '{print $2}' | sed -e 's/\"//g ') /nfs ext4 defaults 0 2" >> /etc/fstab
systemctl daemon-reload
mount /nfs
df -h | grep nfs 
mkdir -p /nfs/nginx /nfs/backup /nfs/kube-nfs-pv
ln -sf /nfs/nginx /etc/nginx
chown nobody:nogroup -R /nfs
rm -rf /nfs/lost+found
```
- esportiamo una share via nfs
- sulla VM 1
```
echo "/nfs *(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
systemctl restart nfs-server.service
exportfs -ar
showmount -a 127.0.0.1
```
- sulle vm 2 e 3 
```
mkdir -p /nfs
cp -av /etc/fstab /etc/fstab.bak
echo "controlplane:/nfs /nfs nfs defaults,proto=tcp,port=2049 0 0" >> /etc/fstab
systemctl daemon-reload
mount /nfs
ln -sf /nfs/nginx /etc/nginx
df -h  | grep nfs 
```