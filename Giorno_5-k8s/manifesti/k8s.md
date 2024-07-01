# kubernetes

##  Deployamo il nostro primo cluster

entra nella cartella "Giorno_5"
```
git clone https://github.com/techiescamp/vagrant-kubeadm-kubernetes/tree/main
mv K8s/ vagrant-kubeadm-kubernetes/
vagrant up
vagrant ssh controlplane
vagrant ssh node01
vagrant ssh node02
```

### Il valore dell'immutabilita'
Un container non subisce modifiche da parte dell'utente, al contrario di una vm.

### Configurazione dichiaratica
command line vs. yaml

### Sistemi Autoriparativi

## Scaling

K8S ha un sistema di deploy che favorisce lo sviluppo decoupled, 
tramite l'uso intensivo di API e Load Balancers.

- pods, o gruppi di container, si possono raggruppare insieme immagini sviluppate da team differenti. 
- servizi, offrono load balancing, naming e discovery per isolare un microservizio da un altro.
- namespaces, offrono isolamento e controlli d'accesso, cosi' che ogni microservizio possa controllare il livello di interazione con gli altri.
- Ingress, offrono un frontend comodo per combinare molteplici microservizi in una singola superfice di API esternalizzata. 

Questo permette l'adozione di soluzioni dinamiche, quali lo scaling
verticale e quello orizzontale.

### Installazione di MetalLB

 <!-- kubectl edit configmap -n kube-system kube-proxy -->

kubectl --kubeconfig=/etc/kubernetes/admin.conf get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl --kubeconfig=/etc/kubernetes/admin.conf diff -f - -n kube-system

kubectl --kubeconfig=/etc/kubernetes/admin.conf get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f - -n kube-system  

a questo punto si può deployare

kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml


poi deploy il file IPaddress-pool e L2-advertise

kubectl apply -f IPaddress-pool.yaml
kubectl get IPAddressPool  -n metallb-system
kubectl apply -f L2Advertisement.yaml
kubectl get l2advertisement -n metallb-system

### deploy nfs provisioner

cd /mnt/LinuX/Giorno_5-k8s/manifesti/nfs-provioner
kubectl apply -f .
kubectl get clusterrole,clusterrolebindings,storageclass,deployment,rolebindings,role,serviceaccount | grep nfs



### Reset
kubeadm	reset --force
systemctl stop containerd
systemctl stop kubelet
pkill kubelet kube-proxy kube-apiserver kube-scheduler
ipvsadm --clear
for x in $(mount | grep kube | awk '{print $3}') ; do umount $x ; done
rm -rf /etc/kubernetes ~/.kube /var/lib/etcd/ /etc/cni/net.d
iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
sudo swapoff -a
 iptables -F && iptables -X
for IF in $(ip a s |awk 'BEGIN { FS = ":" } ; { print $2 }' |  egrep '(dock|cni|fla|cal)') ; do ip link set $IF down && ip link delete $IF && brctl delbr $IF ; done
systemctl restart containerd
systemctl restart kubelet

se dice che non riesce ad avviare "kubeadm init ..." sdraia tutto

### destroy
pt-mark unhold kubelet kubeadm kubectl containerd.io && GNUTLS_CPUID_OVERRIDE=0x1 apt -y remove containerd.io kubectl=1.28.0-00 kubeadm=1.28.0-00  kubelet=1.28.0-00 kubernetes-cni && apt autoremove -y && find / -type d -iname "*kube*" -not -name "*kubepods*" -exec rm -rf {} + ; find / -type d -iname "*cni*"  -exec rm -rf {} + ; find / -type d -iname "*containerd*"  -exec rm -rf {} ; find / -type d -iname "*etcd*"  -exec rm -rf {} + ; find /etc/ /root/  -type f -iname "*kube*" -exec rm -f {} + ; find /etc/ /root/  -type f -iname "*containerd*" -exec rm -f  {} + && apt -y update && apt -y upgrade && reboot
