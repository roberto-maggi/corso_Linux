# La nascita del Porto
Docker significa "portuale", nel senso di colui che lavora al porto, 
e nasce da una esigenza di semplificazione del processo di deploy dei programmi.

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


Docker utilizza una architettura client-server, dove il client comunica con il daemon Docker tramite una API RESTful. Il daemon Docker gestisce il ciclo di vita dei container, inclusa la creazione, l’avvio, la sospensione, la ripresa e la rimozione.

Per creare un container, è necessario definire una immagine Docker. Un’immagine Docker è una sorta di template che descrive come un container deve essere costruito. L’immagine può contenere tutti i file dell’applicazione, le dipendenze e le configurazioni necessarie per far funzionare l’applicazione in un ambiente containerizzato.

Una volta creata l’immagine, è possibile utilizzarla per creare uno o più container. Quando un container viene avviato, Docker crea un nuovo sandboxed environment e avvia l’applicazione al suo interno, utilizzando l’immagine come base.

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


### Docker: Immagini vs Containers 
Qual è la differenza tra immagini e container Docker?
Le immagini e i container Docker sono tecnologie di implementazione delle applicazioni. In passato, per eseguire qualsiasi applicazione, era necessario installare la versione corrispondente al sistema operativo della macchina. Tuttavia, oggi è possibile creare un singolo pacchetto software, o container, che viene eseguito su tutti i tipi di dispositivi e sistemi operativi. Docker è una piattaforma software che impacchetta il software in container. Le immagini Docker sono modelli di sola lettura che contengono istruzioni per creare un container. Un'immagine Docker è uno snapshot o un modello delle librerie e delle dipendenze necessarie all'interno di un container per l'esecuzione di un'applicazione.

I container consentono agli sviluppatori di impacchettare software da eseguire su qualsiasi sistema di destinazione. In precedenza, era necessario creare pacchetti software specifici per diversi sistemi di destinazione. Ad esempio, se si voleva che un'applicazione funzionasse su macOS e Windows, era necessario modificare il design dell'applicazione e impacchettarla per i diversi sistemi.

La containerizzazione consente a un'applicazione software di funzionare come microservizi su architetture hardware distribuite e multipiattaforma. Poiché i container sono estremamente portabili, queste applicazioni software possono essere eseguite su quasi tutte le macchine con una implementazione rapida. Ad esempio, un'applicazione aziendale può avere centinaia di microservizi. Potrebbe funzionare come container su più macchine e macchine virtuali (VM) in un data center dedicato e nel cloud.
Docker è una piattaforma di containerizzazione che si può utilizzare per impacchettare i software in container ed eseguirli su qualunque macchina si desideri. I container Docker vengono eseguiti su qualsiasi macchina o macchina virtuale in cui è installato il motore Docker. 
E funzionano senza conoscere l'architettura del sistema sottostante. Il motore Docker funziona solo con il sistema operativo Linux. Un container Docker è un container realizzato utilizzando la piattaforma di containerizzazione Docker; esistono anche altre piattaforme di containerizzazione meno diffuse.

Come funzionano i container Docker
Un container Docker è un ambiente di runtime con tutti i componenti necessari, come codice, dipendenze e librerie, indispensabili per eseguire il codice dell'applicazione senza utilizzare le dipendenze della macchina host. Questo runtime del container viene eseguito sul motore su un server, una macchina o un'istanza cloud. Il motore gestisce più container a seconda delle risorse sottostanti disponibili. 

Per implementare e dimensionare un set di container per comunicare in modo efficace tra diverse macchine o macchine virtuali, è necessaria una piattaforma di orchestrazione dei container come Kubernetes. Questo aiuta indipendentemente dal fatto che le macchine siano on-premise o nel cloud. Nel contesto delle operazioni dei container, Kubernetes gestisce più macchine note come cluster.

Come funzionano le immagini Docker
Un'immagine Docker, o immagine container, è un file eseguibile autonomo utilizzato per creare un container. Questa immagine del container contiene tutte le librerie, le dipendenze e i file necessari per l'esecuzione del container. Un'immagine Docker è condivisibile e portabile, quindi è possibile distribuire la stessa immagine in più posizioni contemporaneamente, proprio come un file binario software. 

È possibile archiviare immagini nei registri per tenere traccia di architetture software complesse, progetti, segmenti aziendali e accessi di gruppi di utenti. Ad esempio, il registro pubblico di Docker Hub contiene immagini come sistemi operativi, framework di linguaggi di programmazione, database ed editor di codice. 

Creazione di container Docker da immagini Docker
Per creare un container da un'immagine Docker specifica, avvia il motore su una macchina. Quindi, usa il comando di esecuzione Docker di base.

Ecco un comando di esempio:

`docker run -it MyImage bash`

Questo comando crea un container da un file di immagine denominato MyImage. -it crea uno pseudo-terminale all'interno del container in esecuzione. E specificando bash come comando, un terminale bash si apre all'interno del container.
Differenze principali tra immagini Docker e container Docker
Un container Docker è un'applicazione o un servizio software autonomo ed eseguibile. Un'immagine Docker, invece, è un modello caricato sul container per eseguirlo, come un set di istruzioni.

Si archiviano immagini per condividerle e riutilizzarle, ma durante il ciclo di vita di un'applicazione si creano e distruggono container. Illustreremo altre differenze successivamente.

Fonte
Si crea un'immagine Docker da un Dockerfile, un file di testo leggibile dall'uomo simile a un file di configurazione. Il Dockerfile contiene tutte le istruzioni per creare l'immagine. È necessario posizionare il Dockerfile insieme a tutte le librerie e le dipendenze associate in una cartella per creare l'immagine.

Al contrario, si creano container Docker direttamente dal file di immagine Docker. 

Composizione
Il file di immagine Docker è composto da vari livelli di immagine per mantenere le dimensioni del file ridotte.  Ogni livello rappresenta una modifica apportata all'immagine. I livelli sono di sola lettura e possono essere condivisi tra più container.

Il container Docker, essendo un'istanza di immagine, contiene anche i livelli. Tuttavia, ha un ulteriore livello scrivibile, noto come livello container, sulla parte superiore. Il livello container consente l'accesso in lettura e scrittura. Inoltre, consente di isolare qualsiasi modifica apportata al container da altri container basati sulla stessa immagine.

Mutabilità
Le immagini Docker sono immutabili, il che significa che non possono essere modificate una volta che sono state create. Se è necessario apportare modifiche a un'immagine, è necessario creare una nuova immagine con le modifiche desiderate.

Al contrario, i container sono mutabili e consentono modifiche durante l'esecuzione. Le modifiche apportate all'interno di un container sono isolate in quel particolare container e non influiscono sull'immagine associata. Alcuni esempi di modifiche possono essere quando si scrivono nuovi file, si installa software o si modificano le configurazioni.

Quando usare le immagini Docker e quando usare i container Docker
Quando crei e implementi software, puoi utilizzare immagini e container Docker in combinazione tra loro.

I container vengono utilizzati per creare applicazioni una sola volta ed eseguirle ovunque. Puoi avviare, arrestare e riavviare rapidamente i container in base alle esigenze. Quindi, è facile aumentarli o diminuirli in base alla domanda dell'applicazione.

Alla luce di questo, la gestione è più semplice quando si utilizzano sia immagini sia container. Ad esempio, ecco come puoi usarli insieme:

Dimensiona la tua applicazione orizzontalmente eseguendo più istanze di container basate sulla stessa immagine.
Automatizza le pipeline di integrazione e implementazione continua (CI/CD) utilizzando immagini diverse per ambienti di sviluppo, test e produzione.
Tagga e gestisci versioni diverse delle tue immagini. Ciò consente di ripristinare o distribuire versioni specifiche in base alle esigenze.

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

### cluster docker
su tutte le vm
```
cat >> index.html << EOF
ciao sono $(hostname)
EOF
docker run -d -p 80:80 -v ./index.html:/usr/share/nginx/html/index.html --name=nginx nginx:latest
curl 10.0.0.230:8080
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
