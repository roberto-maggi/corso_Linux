# La nascita del Porto
Docker significa "portuale", nel senso di colui che lavora al porto, 
e nasce da una esigenza di semplificazione del prtocesso di deploy dei programmi.

### Lo sviluppo non basato su container necessita di decine di passaggi, tra i quali:

1. Application developers request resources from operations engineers.
2. Resources are provisioned and handed over to developers.
3. Developers script and tool their deployment.
4. Operations engineers and developers tweak the deployment repeatedly.
5. Additional application dependencies are discovered by developers.
6. Operations engineers work to install the additional requirements.
7. Loop over steps 5 and 6 N more times.
8. The application is deployed.

### Sviluppo basato su Docker
1. Developers build the Docker image and ship it to the registry.
2. Operations engineers provide configuration details to the container and provi‐
sion resources.
3. Developers trigger deployment.

Docker adotta un sistema client - server preferibilmente su su socket unix

### Container Networking
Docker permette ai container di fare il binding delle porte dell'host su cui gira dockerd.
Lo fa allocando una classe di subnet privata inutilizzata, fino a quel momento, e mettendola a 
disposizione dei container, ma non puo' essere consapevole degli sviluppi che avvengono 
dopo nella rete. Per questo e' buona regola hardcodare la rete nel daemon.json .
Questo permette, fin quando non si delimitano sottoreti con il comando "networks", a tutti 
container di comunicare liberamente tra loro.

I container docker sono stateless e permettono di sviluppare applicazioni decoupled.

`docker network ls`

### Filesystem layers
I container sono costituiti da strati impilati di file system ( sempre lo stesso tipo ),
sui quali vengono registrati solo i cambiamenti rispetto allo strato precedente.
Questo permette un'aumento delle prestazioni di download, perche' vengono scaricati solo i layer mancanti, e gestione della storia del container.

### Il nostro primo build
```
git clone https://github.com/spkane/docker-node-hello.git
cd docker-node-hello
docker build -t example/docker-node-hello:latest .
docker run -d -p 8081:8080 example/docker-node-hello:latest
curl http://localhost:8081
```

controlliamo i processi

```
docker ps -a 
ps laxf | grep node
```

se lo uccidiamo e lo rilanciamo con una var diversa otteniamo

```
docker stop <nome_del_tuo_container>
docker rm -f <nome_del_tuo_container>
docker run -d -p 8081:8080 -e WHO="ROB" example/docker-node-hello:latest
```

### Il Container Registry

I piu famosi e piu' riforniti tra quelli pubblici sono Docker Hub e Quai.io, 
mentre tra i privati i migliori sono harbor e portus.

### Cosa e' un container ?

"Un container e' un ambiente esecutivo auto-contenuto, che condivide il kernel
dell'host su cui gira dockerd e che puo' essere isolato dagli altri container
del sistema."

Cioe'? e' un chroot!

### Creiamo un container 

```
docker create --name="testONE" alpine
docker run -d -ti --name testTWO --hostname=ciao -l Friday=Jason -l Night=Freddy -l Halloween=Michael alpine:latest
docker exec -ti testTWO /bin/sh && docker stop testTWO && docker rm -f testTWO
```
```
hostname
mount | hostname
mount | grep res
```

Uccidiamo il container e riproviamo cambiando il dns

```
docker run -d -ti --name testONE --dns=8.8.8.8 --dns=8.8.4.4 --dns-search=example1.com --dns-search=example2.com alpine:latest
docker exec -ti testONE /bin/sh && docker stop testONE && docker rm -f testONE
docker run -d -ti --name testONE --mac-address="a2:11:aa:22:bb:33" alpine:latest
docker exec -ti testONE /bin/sh && docker stop testONE && docker rm -f testONE
docker run -d -ti --name testONE -v /vagrant_data:/data alpine:latest
docker exec -ti testONE /bin/sh && docker stop testONE && docker rm -f testONE
docker run -d -ti --name testONE --read-only=true -v /vagrant_data:/data alpine:latest
docker exec -ti testONE /bin/sh && docker stop testONE && docker rm -f testONE
```

### Resource quotas
La capacita' di Docker di modificare le risorse disponibili, per i container, e' 
legata alla presenza dei relativi moduli del kernel, in loro assenza bisognera' 
ricompilarlo.

```
docker info | less
docker run -d -ti --name testONE --cpu 1 --io 1 --vm 2 --vm-bytes 128M --timeout 120s alpine:latest
docker exec -ti testONE /bin/sh && docker stop testONE && docker rm -f testONE
```

--> CPU shares

Il "compute pool" totale e' il default di 1024. Nel caso in cui volessimo dimezzare
la disponibilita' vero un container imposteremmo "-c 512", ma questo non cambiera' 
la reale disponibilita' di clock.
Cio' che avverra' sara' una sorta di "renice" del processo, percui la sua 
"l'aggressivita'" nei confronti del processore scendera' da 100ms a 50.
I limiti alle CPU sono "relative limits"
--> CPU pinning

`docker run --rm -ti -c 512 --cpuset=0 testONE --cpu 2 --io 1 --vm 2 --vm-bytes 128M --timeout 120s`

--> swap

```
docker run --rm -ti -m 512m --memory-swap=768m testONE --cpu 2 --io 1 --vm 2 --vm-bytes 128M --timeout 120s
docker run --rm -ti -m 512m --memory-swap=-1 testONE --cpu 2 --io 1 --vm 2 --vm-bytes 128M --timeout 120s
```

I limiti alla memoria ( ram / swap ) sono "hard limits".

### Start / Stop / Restart / Pause / Unpause

`docker run testONE`

### Le immagini dei container

```
    docker images
docker rmi <nome_dell_immagine>
```

cancellare tutte le immagini dei container in status "exited"

`docker rmi $(docker ps -a -q --filter 'status=exited')`

### Ispezioniamo un container 
```
docker run -d -ti --name testONE --hostname=ciao alpine:latest
docker inspect testONE | less
```

### Dentro un container

`docker exec -ti testONE`

### Logs

`docker logs testONE`

### Monitorare i container

`docker stats testONE`

### Wrap it up!

```
systemctl disable --now docker.service
systemctl disable --now docker.socket
systemctl disable --now haproxy.service 
systemctl disable --now keepalived.service
for BR in $( ip --brief a s | grep br- | awk '{print $1}' ) ; do ip link delete $BR ; done
ip link delete docker0

```


### Consigli

alias dock_ck='docker-compose -f config --quiet && printf "OK\n" || printf "ERROR\n"'
alias dp='docker ps -a'
alias docker_prune='for x in $(docker ps -a | grep Exited | awk "{print $1}") ; do docker rm -f $x ; done'

function docker_sdraia_tutto() {
        for DOCK in $( docker ps -a | awk '{print $NF}' | tail -n +2 ) ; do 
                docker stop $DOCK 2>&1 > /dev/null
                docker rm -f  $DOCK ;
        done
}
