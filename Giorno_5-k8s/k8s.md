# Kubernetes

## Perche' Kubernetes
- pods, o gruppi di container, si possono raggruppare insieme immagini sviluppate da team differenti. 
- servizi, offrono load balancing, naming e discovery per isolare un microservizio da un altro.
- namespaces, offrono isolamento e controlli d'accesso, cosi' che ogni microservizio possa controllare
    il livello di interazione con gli altri.
- Ingress, offrono un frontend comodo per combinare molteplici microservizi in una singola superfice 
    di API esternalizzata. 

K8S ci offre "Service discovery and load balancing" esponendo i nostri servizi su container usando 
fqdn ( tramite coredns ) e/o ip interni ( ClusterIP ). 
Fa "Storage orchestration" facendo il provisioning di spazio 
disco ai vari pod che ne fanno richiesta.
Automatizza rollout e rollback, tramite i manifesti in yaml possiamo descrivere lo stato ( versione ) 
in cui vogliamo i nostri container, lasciando a lui il compito di occuparsene.
Bin Picking automatizzato, e' possibile definire le risorse che ogni container puo' assumere e 
K8S si occupera' di offrirgliele e gestirle.
### Auto Guarigione
Per i pod e' un altro potente strumento che, in caso di fallimento del componente, lo riavvia.  
### Il valore dell'immutabilita'
Un container non subisce modifiche da parte dell'utente, al contrario di una vm.
### Secret e configuration management
K8S gestisce passwords, OAuth tokens, e chiavi SSH, evitandoci di hardcodarle nei container.
### Batch executions
### Horizontal Scaling

K8S ha un sistema di deploy che favorisce lo sviluppo decoupled, 
tramite l'uso intensivo di API e Load Balancers.

Questo permette l'adozione di soluzioni dinamiche, quali lo scaling
verticale e quello orizzontale.

Visto che all'esame della CKA ci vengono presentati 6 cluster preinstallati sara' necessario spostarsi tra un cluster e l'altro con 

kubectl config current-context

kubectl config set-context <nome_del_cluster> --namespace <nome_del_namespace>

k8s ha molti comandi,la cui maggior parte ha una nomenclatura parecchio estesa, ma possiamo controllarli tutti

kubectl api-resources

## Tecniche di gestione

Kubernetes supporta tre modalita' di gestione:

- comandi imperativi

    kubectl create deployment nginx --image nginx

- configurazione imperativa degli oggetti

    kubectl create -f ./nginx.yaml

- configurazione dichiarativa degli oggetti

    kubectl diff -f <NOME_PROGETTO1>/
    kubectl apply -f <NOME_PROGETTO1>/
    kubectl diff -f <NOME_PROGETTO2>/
    kubectl apply -f <NOME_PROGETTO2>/

## Oggetti

### Nomi e UID

Ascrivibilita' in codice

siccome ogni oggetto verra' "codificato" e ad esso verranno fatti riferimenti tramite "path ( url )"
deve essere registrato secondo delle regole, k8s non supporta quindi nomi di oggetti con 
caratteri quali ".,\/%!?"

Una volta che il nome e' accettato k8s creera' un UID unico per l'oggetto generato.

kubectl get pods <NOME_POD> -o jsonpath='{.metadata.uid}'

### Labels

le etichette sono coppie "key/value" attaccate ad oggetti, ad esempio pods.
Servono essenzialmente agli utenti per identifica gli oggetti, ma non apportano 
necessariamente un valore aggiunto al motore di k8s. ( > 63 )
```
...
metadata:
  labels:
    environment: production
    app: nginx 
...
```

Non e' necessario che le labels siano uniche ne' univoche, anzi normalmente ci si aspetta 
che ce siano sia svariate etichette nello stesso oggetto che rifermenti ad ognuna.

I riferimenti o ricerche delle labels si eseguono tramite i "selectors" che supportano due 
tipi di richieste

"Equality- or inequality-based requirements"

```
...
selector:
  environment = production
  tier = frontend
  partition = true
...

oppure

...
selector:
  environment != production
  tier != frontend
  !partition
...
```
"Set-based requirement"

che supportano operatori quali: in,notin and exists

```
kubectl get pods -l environment in production
                    environment notin frontend
                    partition
                    !partition
```

Il primo ritornera' 0 con tutti i valori "environment" nelle chiavi "production" e "qa"
La seconda ricerca per tutti i risultati di tier non "frontend" ma "backend", 
mentre la terza e la quarta includeranno ed escluderanno, rispettivamente, ogni chiave 
contenente o no "partition", a prescindere dai volori ad esse associati.   

Labels suggerite
Al fine di garantire una gestione il piu' possibile semplificata e' consigliabile utilizzare
sempre il maggior numero possibile di labels potenzialmente utili. Ad esempio

```
...
  labels:
    app.kubernetes.io/name: mysql
    app.kubernetes.io/instance: mysql-abcxyz
    app.kubernetes.io/version: "5.7.21"
    app.kubernetes.io/component: database
    app.kubernetes.io/part-of: wordpress
    app.kubernetes.io/managed-by: Helm
...
```

### Annotations

Al contrario delle labels, k8s non e' in grado di usare le informazioni presenti in questi metadati.
Essi devono pero' rispettare alcuni criteri, come il fatto di essere "string", quindi non numerici 
o booleani.

### Namespaces

I namespace non vanno considerati come una sistema di segrazione "fisico", come fa docker 
con le network, ma esclusivamente logico, come se fossero delle directory.
Quelli di default sono "default, kube-public, kube-node-lease, kube-system".
Non sono consentiti ns con prefisso "kube-", poiche' assegnato a k8s.
Usa 
`kubectl get namespace`
per listare tutti gli ns presenti nel cluster.

Per definire un ns nella selezione corrente usare 
```
kubectl run nginx --image=nginx --namespace=<insert-namespace-name-here>
kubectl get pods --namespace=<insert-namespace-name-here>
```
mentre per impostarlo definitivamente ( fino al prossimo cambio )
```
kubectl config set-context --current --namespace=<insert-namespace-name-here>
kubectl config view --minify | grep namespace:
```
La maggiorparte degli oggetti in k8s sono dentro dei ns, ma molti altri no, ad esempio i ns stessi e i pv.
```
kubectl api-resources --namespaced=true
kubectl api-resources --namespaced=false

```

### Field Selector

Questo strumento ci permette di fare selezioni in base al valore dei campi attribuiti ad un oggetto
https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/#list-of-supported-fields

```
kubectl get pods --field-selector=status.phase=Running,spec.restartPolicy=Always
```

### Owners & Dependents

Con questi termini definiamo la relazione di alcuni oggetti, secondo cui, ad esempio, un ReplicaSet e' "owner" dei Pod che genera.

## I componenti di Kubernetes

Quando parliamo di k8s parliamo di un cluster, un gruppo di componenti che creano un sistema atto a svolgere un compito
distribuendo in modo ordinato specifiche operazioni.

< kubernetes cluster arch >

Un cluster k8s e' composto almeno da (N*2)+1 "controplane node" e 1 "worker node", essenzialmente il cp controlla e gestisce
il lavoro svolto dal wn.

### --> ControlPlane

### kube-api-server
E' il componente principale di un cluster, l'unico che parla con tutti gli altri e con il quale ognuno comunica.

```
siccome kubectl usa chiamate http per interrogare kube-api questo e'
un esempio per listare i pod

kubectl proxy &
curl http://localhost:8001/api/v1/namespaces/default/pods
```


### etcd
E' un database estremamente performante a "key=value".
E' fondamentale farne dei backup!

### kube-scheduler
si occupa di selezionare il nodo appropriato per ogni pod appena creato.
Alcuni fattori tenuti in considerazione per il deploy sono la affinita' o meno, richieste di 
risorse individuali ( pod ) o di gruppo ( deploy ), hardware, software policy constrains ecc.

### kube-controller-nanager
Questo e' il binario da cui scaturiscono tutti i componenti che eseguono i processi di controllo
come node, jobs, EndPointSlice, ServiAccount controllers. 

### --> WorkerNodes

### Kubelet
E' un agente in esecuzione su ogni wn del cluster e si assicura che i container siano in esecuzione dentro i relativi pod.
Essenzialmente legge i dati presenti nelle PodSpecs e li valida, assicurandosi cosi' della "salute" dei pod.

### kube-proxy
Questo e' il proxy  che gira su ogni wn del cluster e implementando una parte del concetto di Service di k8s.
Esso  amministra le regole di networking del nodo, che ne permettono la corretta comunicazione dentro e fuori dal cluster.
kp usa il layer di packet filtering del OS, se presente e disponibile, altrimenti ne esegue autonomamente il forwarding.

### Container Runtime Interface
Il CRI e' responsabile della corretta esecuzione e lifetime dei container all'interno dell'ambiente di k8s. 
k8s supporta containerd, CRI-O e ogni implementazione di Kubernetes CRI

### -> addons

### DNS
k8s ha un dns server cluster interno, quello di default e' coredns.
Le query eseguite da un pod seguono una gerarchia simile a quella di ogni altra applicazione, in cui la priorita' piu' alta
la ottiene il motore interno al pod, poi coredns, ed infine il dns dell'host su cui k8s e' installato.
Un record DNS ottiene un fqdn simile a my-svc.my-namespace.svc.cluster-domain.example ( come A/AAA record ), mentre uno 
"headless" si riferisce essenzialmente ad un pod, bypassandone il servizio.

### Dashboard ( meglio OpneLens )

### Cluster-level loggins

Testiamo il sistema di log:

cat > pod_logging.yml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  - name: count
    image: busybox:1.28
    args: [/bin/sh, -c,
            'i=0; while true; do echo "$i: $(date)"; i=$((i+1)); sleep 1; done']
EOF

kubectl apply -f ./pod_logging.yml 

kubectl logs counter -f 
kubectl logs --previous ( container precedentemente restartato )
kubectl logs counter -c count

Benche' k8s non offra nativamente un sistema di logging esistono svariati approcci che possiamo considerare.
  - un agente installato sul singolo nodo ( DaemonSet )
  - un container sidecar per loggare il pod

cat > double_format_logging.yml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  - name: count
    image: busybox:1.28
    args:
    - /bin/sh
    - -c
    - >
      i=0;
      while true;
      do
        echo "$i: $(date)" >> /var/log/1.log;
        echo "$(date) INFO $i" >> /var/log/2.log;
        i=$((i+1));
        sleep 1;
      done      
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  volumes:
  - name: varlog
    emptyDir: {}
EOF

    sidecar con agente

cat > sidecar_with_fluentd.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: counter
spec:
  containers:
  - name: count
    image: busybox:1.28
    args:
    - /bin/sh
    - -c
    - >
      i=0;
      while true;
      do
        echo "$i: $(date)" >> /var/log/1.log;
        echo "$(date) INFO $i" >> /var/log/2.log;
        i=$((i+1));
        sleep 1;
      done      
    volumeMounts:
    - name: varlog
      mountPath: /var/log
  - name: count-agent
    image: registry.k8s.io/fluentd-gcp:1.30
    env:
    - name: FLUENTD_ARGS
      value: -c /etc/fluentd-config/fluentd.conf
    volumeMounts:
    - name: varlog
      mountPath: /var/log
    - name: config-volume
      mountPath: /etc/fluentd-config
  volumes:
  - name: varlog
    emptyDir: {}
  - name: config-volume
    configMap:
      name: fluentd-config
EOF

  - un log exporter o un log push verso una applicazione di backend ( prometheus )

### CNI
La Container Network Interface e' l'oggetto specifico del deploy da parte dei vari network plugin come tigera, flannel o traefik tra gli altri. 
Il loro lavoro e' quello di allocare gli IP ai pod e abilitarli alla comunicazione interna ed esterna rispetto al cluster.

### kubernetes API

--> Discovery API
k8s pubblica al suo interno una lista di tutte le versioni dei gruppi e delle risorse supportate via "discovery API", che include:

. nome
. cluster o scopo all'interno del namespace
. indirizzo dell'endpoint e dei verbi supportati
. nomi alternativi
. gruppi, versioni e tipi

## Architettura del cluster

### I nodi

In un cluster di k8s il workload viene deployato solo sui nodi worker abilitati a riceverlo

```
Taints:             node-role.kubernetes.io/control-plane:NoSchedule
Unschedulable:      false
```
La prima `taint` e' dichiarata tramite il comando
`kubectl taint nodes controlplane key1=value1:NoSchedule`, per togliere la `taint` si aggiunge un "-" al comando precedente `kubectl taint nodes node1 key1=value1:NoSchedule-` . 
`Unschedulable: true` si ottiene "recintando" il nodo con `kubectl cordon <NOME_DEL_NODO>`, questo non ha effetto sui pod in esecuzione, che devono essere fermate ed, eventualmente, eliminati a mano.
Per eliminare tutti i pod presenti sul nodo che si sta disconnettendo, in modo "graceful" usare il comando `kubectl drain <NOME_DEL_NODO> --ignore-daemonsets --delete-emptydir-data`


Una volta che il nodo e' creato e/o si e' autoregistrato, viene analizzata la sua validita' dal controlplane, al quale basta una istruzione tipo la seguente:

```
{
  "kind": "Node",
  "apiVersion": "v1",
  "metadata": {
    "name": "10.240.79.157",
    "labels": {
      "name": "my-first-k8s-node"
    }
  }
}
```

Nella fase di auto registrazione, il default con kubeadm, kubelet si esegue con le seguenti opzioni:
```
  . --kubeconfig  ( le proprie credenziali per il kube-API-server )
  . --cloud-provider ( solo se su cloud )
  . --register-node ( registrazione autometica )
  . --register-with-taints
  . --node-ip 
  . --node-labels
  . --node-status-update-frequency
```
In caso di registrazione manuale passare  `--register-node=false` a kubeadm e nel caso in cui si voglia impedire il deploy sul nodo usare `kubectl cordon $NODENAME`

per analizzare lo stato di un nodo

kubectl get nodes <NOME_DEL_NODO>
kubectl describe node <NOME_DEL_NODO>

k8s usa un "hub-and-spoke" in cui l'API-server fa da torre di controllo per tutti gli altri componenti del cluster.
Il kubelet comunica direttamente alla 6443 dell'API e si autentica tramite un certificato client, generato tramite il TLS bootstrapping.
I pod che devono comunicare con l'API server lo fanno grazie al relativo ServiceAccount nel quale viene iniettato il certificato pubblico di root e un bearer token generato alla creazione del pod stesso.

nota: bearer token va interpretato come "l'auteticazione e' garantita al bearer ( portatore ) di questo token".
Il Service relativo e' configurato con un IP virtuale e rediretto da kube-proxy all'endpoint dell API-server.

## Il primo Deploy!

### pod

Il pod e' l'unita' atomica deployabile di kubernetes e consiste in x+1 container, che e' lo standard consigliato, perche' cosi' k8s gesti un pod anziche' un container direttamente.
E' altrimenti possibile co-locare container multipli dentro un singolo pod.
Questo li rende direttamente collegati e coesi.
Ad ogni modo difficilmente lavoreremo con singoli pod, perche' sono entita' effimere, non direvoli.

--> pod con singolo container 

```
cat > nginx_singolo.yml << EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  type: ClusterIP
---
EOF
```
curl http://$(kubectl describe svc nginx-service | grep 'IP:'|awk '{print $2}'):$(kubectl describe svc nginx-service| grep -E '^Port:' | awk '{print $3}' | sed -e 's/\/TCP//g') 

--> due container che si forwardano chiamate sul loopback

```
cat >> due_container_forward_loopback.yml << EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: mc3-nginx-conf
data:
  nginx.conf: |-
    user  nginx;
    worker_processes  1;

    error_log  /var/log/nginx/error.log warn;
    pid        /var/run/nginx.pid;

    events {
        worker_connections  1024;
    }

    http {
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile        on;
        keepalive_timeout  65;

        upstream webapp {
            server 127.0.0.1:5000;
        }

        server {
            listen 80;

            location / {
                proxy_pass         http://webapp;
                proxy_redirect     off;
            }
        }
    }
---
apiVersion: v1
kind: Pod
metadata:
  name: mc3
  labels:
    app: mc3
spec:
  containers:
  - name: webapp
    image: training/webapp
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: nginx-proxy-config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
  volumes:
  - name: nginx-proxy-config
    configMap:
      name: mc3-nginx-conf
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: mc3
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 80
  type: ClusterIP
EOF
```

kubectl apply -f ./due_container_forward_loopback.yml


curl http://$(kubectl describe svc nginx-service | grep 'IP:'|awk '{print $2}'):$(kubectl describe svc nginx-service| grep -E '^Port:' | awk '{print $3}' | sed -e 's/\/TCP//g') 


--> pods e controllers 
Anziche' forzare il deploy manualmente e' buona norma usare controllers che 
si occupino di rideployare la risorsa su componenti sani alternativi ( leggi nodi ancora vivi e vegeti ).

-->> Pod Templates

I controllers creano i vari pod attraverso dei `pod templates` e li gestiscono per noi.
Questi templates sono inclusi in alcune `workload resources` come :
  - Deployment
  - Statefulset
  - DaemonSet
  - Job

```
apiVersion: batch/v1
kind: Job
metadata:
  name: hello
spec:
  template:
    # This is the pod template
    spec:
      containers:
      - name: hello
        image: busybox:1.28
        command: ['sh', '-c', 'echo "Hello, Kubernetes!" && sleep 3600']
      restartPolicy: OnFailure
    # The pod template ends here
```

Pod phases

  - Pending
  - Running
  - Succeeded
  - Failed
  - Unknown

Container states
  - Waiting
  - Running
  - Terminated

Errori dei pods

  - Initial crash: Kubernetes attempts an immediate restart based on the Pod restartPolicy.
  - Repeated crashes: After the initial crash Kubernetes applies an exponential backoff delay for subsequent restarts, described in restartPolicy. This prevents rapid, repeated restart attempts from overloading the system.
  - CrashLoopBackOff state: This indicates that the backoff delay mechanism is currently in effect for a given container that is in a crash loop, failing and restarting repeatedly.
  - Backoff reset: If a container runs successfully for a certain duration (e.g., 10 minutes), Kubernetes resets the backoff delay, treating any new crash as the first one.

Container Restart Policy

  - Always: Automatically restarts the container after any termination.
  - OnFailure: Only restarts the container if it exits with an error (non-zero exit status).
  - Never: Does not automatically restart the terminated container.


### Deployment

Un Deployment è un oggetto Kubernetes che fornisce dichiarazioni per gestire le applicazioni. 
Si occupa di gestire la creazione e le repliche dei pod e garantisce che il numero desiderato di 
repliche di un'applicazione sia in esecuzione. 
Consente aggiornamenti e rollback delle applicazioni senza interruzioni.

kubectl apply -f nginx_deployment_su_lb.yml

### StatefulSet

Uno StatefulSet è un oggetto Kubernetes utilizzato per gestire applicazioni stateful. Garantisce che i pod siano creati e aggiornati mantenendo un'identità stabile attraverso i riavvii e le rischedulazioni.
Quando si parla di "identità stabile" in Kubernetes, specialmente in relazione agli StatefulSet, si intende che i pod gestiti da uno StatefulSet mantengono una serie di proprietà. 
Questa stabilità riguarda diversi aspetti:

Nome dei Pod
I pod creati da uno StatefulSet hanno nomi predicibili e stabili. Il nome di ogni pod include il nome dello StatefulSet e un suffisso numerico incrementale. Ad esempio, se il nome dello StatefulSet è nginx, i pod avranno nomi come nginx-0, nginx-1, nginx-2, e così via. Questo naming predicibile permette di sapere esattamente quale pod è quale, anche dopo riavvii o aggiornamenti.

Identità di Rete
Ogni pod in uno StatefulSet ha un DNS stabile. Ad esempio, il pod nginx-0 avrà un nome DNS come nginx-0.<servicename>. Questo significa che anche se un pod viene riavviato o spostato su un altro nodo, il suo nome DNS rimane lo stesso, facilitando la comunicazione tra i pod e altri servizi.

Volumi Persistenti
I pod in uno StatefulSet possono essere associati a PersistentVolumeClaims (PVC) che sono anch'essi stabili e univoci. Ogni pod mantiene un'associazione costante con il proprio volume di storage, che non cambia attraverso i riavvii. Questo è essenziale per applicazioni stateful che necessitano di accesso costante ai dati, come i database.

In questo esempio:

Nome dei Pod: nginx-0, nginx-1, nginx-2 saranno i nomi dei pod creati.
Identità di Rete: Ogni pod avrà un nome DNS stabile come nginx-0.nginx, nginx-1.nginx.
Volumi Persistenti: Ogni pod avrà un volume persistente associato specifico, assicurato dai volumeClaimTemplates.

Vantaggi dell'Identità Stabile
Facilità di Debug: Poiché ogni pod ha un nome prevedibile e una connessione DNS stabile, è più facile monitorare e fare debug delle applicazioni.
Consistenza dei Dati: Volumi persistenti associati a pod specifici garantiscono che i dati non vadano persi attraverso riavvii.
Aggiornamenti Graduali: Gli aggiornamenti ai pod possono essere eseguiti in modo graduale, riducendo il rischio di downtime o di inconsistenze.
L'identità stabile è cruciale per applicazioni stateful, come database, sistemi di messaggistica, o altre applicazioni che richiedono un accesso persistente e consistente ai dati e alle risorse di rete.

kubectl apply -f  nginx-StatefulSet.yml

kubectl get statefulsets
kubectl get pods
kubectl get pvc

### DaemonSet
Un DaemonSet è un oggetto Kubernetes utilizzato per garantire che una copia di un pod sia in esecuzione su tutti (o alcuni) nodi del cluster. È comunemente utilizzato per eseguire agenti di sistema, come log collectors o monitoring agents, su ogni nodo.
I DaemonSet sono comunemente utilizzati per eseguire compiti di sistema critici e di gestione del cluster. Di seguito sono riportati alcuni dei principali vantaggi dell'utilizzo di un DaemonSet:

Vantaggi di un DaemonSet
Gestione Centralizzata dei Servizi di Sistema:

Logging: Esempi comuni includono l'uso di DaemonSet per distribuire agenti di logging come Fluentd o Logstash su ogni nodo per raccogliere e inviare i log.
Monitoraggio: DaemonSet può essere utilizzato per eseguire agenti di monitoraggio come Prometheus Node Exporter, che raccoglie metriche di sistema da ogni nodo.
Sicurezza: Implementare agenti di sicurezza come Falco per il monitoraggio della sicurezza dei container e dei nodi.
Consistenza di Configurazione:
Assicura che tutti i nodi nel cluster abbiano configurazioni e servizi uniformi e aggiornati. Questo è particolarmente utile per applicazioni che richiedono impostazioni coerenti su tutti i nodi.
Facilità di Manutenzione:
Facilita la distribuzione e l'aggiornamento degli agenti di sistema, poiché qualsiasi modifica al DaemonSet viene automaticamente propagata a tutti i nodi. Questo riduce significativamente lo sforzo di manutenzione manuale.
Efficienza delle Risorse:
DaemonSet utilizza efficientemente le risorse del cluster assicurando che un numero minimo di pod (uno per nodo) sia in esecuzione, riducendo la duplicazione non necessaria di servizi di sistema.
Supporto per Nodi Specifici:
DaemonSet può essere configurato per eseguire pod solo su nodi specifici utilizzando selettori di etichette o tolleranze per i nodi con determinati taint. Questo è utile per eseguire servizi solo su nodi dedicati o specializzati.
Alta Disponibilità:
Poiché un DaemonSet garantisce che ogni nodo esegua una copia del pod, contribuisce ad aumentare la disponibilità dei servizi di sistema. Anche se un nodo si guasta, gli altri nodi continueranno a eseguire i pod del DaemonSet, garantendo che il servizio rimanga operativo.

kubectl apply -f  fluentd_DaemonSet.yml
                  prometheus_DaemonSet.yml

### Probes

Attraverso il "readinessGates" noi possiamo iniettare feedback extra o segnali all'interno dello `PodStatus` del Pod.

```
kind: Pod
...
spec:
  readinessGates:
    - conditionType: "www.example.com/feature-1"
status:
  conditions:
    - type: Ready                              # a built in PodCondition
      status: "False"
      lastProbeTime: null
      lastTransitionTime: 2018-01-01T00:00:00Z
    - type: "www.example.com/feature-1"        # an extra PodCondition
      status: "False"
      lastProbeTime: null
      lastTransitionTime: 2018-01-01T00:00:00Z
  containerStatuses:
    - containerID: docker://abcd...
      ready: true
...
```

Ci sono quattro possibli vie di probing dei container e sono:

- exec
Executes a specified command inside the container. The diagnostic is considered successful if the command exits with a status code of 0.
- grpc
Performs a remote procedure call using gRPC. The target should implement gRPC health checks. The diagnostic is considered successful if the status of the response is SERVING.
- httpGet
Performs an HTTP GET request against the Pod's IP address on a specified port and path. The diagnostic is considered successful if the response has a status code greater than or equal to 200 and less than 400.
- tcpSocket
Performs a TCP check against the Pod's IP address on a specified port. The diagnostic is considered successful if the port is open. If the remote system (the container) closes the connection immediately after it opens, this counts as healthy.

e posso ritornare i seguenti output:

  - Success
  - Failure
  - Unknown

### Tipi di Probes

  - livenessProbe
  - readinessProbe
  - startupProbe

--> liveness probe 
A third type of liveness probe uses a TCP socket. With this configuration, the kubelet will attempt to open a socket to your container on the specified port. If it can establish a connection, the container is considered healthy, if it can't it is considered a failure.

--> readiness probes
Sometimes, applications are temporarily unable to serve traffic. For example, an application might need to load large data or configuration files during startup, or depend on external services after startup. In such cases, you don't want to kill the application, but you don't want to send it requests either. Kubernetes provides readiness probes to detect and mitigate these situations. A pod with containers reporting that they are not ready does not receive traffic through Kubernetes Services.

--> startupProbe
The readiness and liveness probes do not depend on each other to succeed. If you want to wait before executing a readiness probe, you should use initialDelaySeconds or a startupProbe.

https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/


TESTARE 
```
cat > nginx-health_check.yml << EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configmap1
data:
  healthz: |
ciao
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  annotations:
    metallb.universe.tf/loadBalancerIPs: 10.0.0.245
spec:
  type: LoadBalancer # Espone il servizio su un indirizzo IP esterno
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---    
apiVersion: v1
kind: Pod
metadata:
  name: nginx-healthcheck
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
      - name: config1
        mountPath: /usr/share/nginx/html/healthz
        subPath: healthz
    livenessProbe:
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
  volumes:
    - name: config1
      configMap:
        name: nginx-configmap1
---
EOF
```

--> Healthcheck

Simuliamo un fallimento del `Liveness Probe`
deploy del pod
`kubectl apply -f nginx-health_check.yml`
controlla lo stato
`kubectl get pod nginx-healthcheck`
descrivi il pod
`kubectl describe pod nginx-healthcheck`
manometto il pod!
```
kubectl exec -it nginx-healthcheck -- /bin/sh
touch /usr/share/nginx/html/healthz
exit
```
Osserva l'effetto
`kubectl get pod nginx-healthcheck -w`

Simuliamo ora un fallimento del `Readiness Probe`
```
kubectl exec -it nginx-healthcheck -- /bin/sh
pkill nginx
exit
```
Il container dovrebbe morire a breve e il pod venir riavviato

`kubectl get pod nginx-healthcheck -w`


### Ingress

helm install my-release oci://ghcr.io/nginxinc/charts/nginx-ingress --version 1.3.1
kubectl get pods -n ingress-nginx

https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  type: LoadBalancer
spec:
  rules:
  - host: ciao.it
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
---


  DNS pippo.it 195.0.0.100  
  /                                       ( ingress )
casa -> www ->  router_aziendale     ->   rp / lb            ->  srv ( pippo.it)
                195.0.0.100:80/443      192.168.0.10:80/443     10.0.0.245:8080  <--> service --> nodo1 - pippo.pod1
                                        pippo.it:80/443                                       \-> nodo2 - pippo.pod2
                                        paperino.it             10.0.0.245:8081

proxy laptop_personale -> www
rp    www -> srv_singolo

                    youtube1 20
                  /
lb    www ->rp/lb - youtube2 20
                  \ 
                    youtube3 20


                    roundrobin
                    hash
                    leastconn

service port        10.0.0.245:8080
        targetport  pod:80
pod port            172.0.0.10:80
container           x:80
  nginx             x:80
      

### Volumi

--> emptyDir

For a Pod that defines an emptyDir volume, the volume is created when the Pod is assigned to a node. As the name says, the emptyDir volume is initially empty. All containers in the Pod can read and write the same files in the emptyDir volume, though that volume can be mounted at the same or different paths in each container. When a Pod is removed from a node for any reason, the data in the emptyDir is deleted permanently.


--> pod con container multipli

---
apiVersion: v1
kind: Pod
metadata:
  name: mc1
spec:
  volumes:
  - name: html
    emptyDir: {}
  containers:
  - name: 1st
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
  - name: 2nd
    image: debian
    volumeMounts:
    - name: html
      mountPath: /html
    command: ["/bin/sh", "-c"]
    args:
      - while true; do
          date >> /html/index.html;
          sleep 1;
        done
---

--> configMap

A ConfigMap provides a way to inject configuration data into pods. The data stored in a ConfigMap can be referenced in a volume of type configMap and then consumed by containerized applications running in a pod.

When referencing a ConfigMap, you provide the name of the ConfigMap in the volume. You can customize the path to use for a specific entry in the ConfigMap. The following configuration shows how to mount the log-config ConfigMap onto a Pod called configmap-pod:

kubectl apply -f nginx+pvc+lb.yml

--> PersistentVolume 

A PersistentVolume (PV) is a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using Storage Classes. It is a resource in the cluster just like a node is a cluster resource. PVs are volume plugins like Volumes, but have a lifecycle independent of any individual Pod that uses the PV. This API object captures the details of the implementation of the storage, be that NFS, iSCSI, or a cloud-provider-specific storage system.

A PersistentVolumeClaim (PVC) is a request for storage by a user. It is similar to a Pod. Pods consume node resources and PVCs consume PV resources. Pods can request specific levels of resources (CPU and Memory). Claims can request specific size and access modes (e.g., they can be mounted ReadWriteOnce, ReadOnlyMany, ReadWriteMany, or ReadWriteOncePod, see AccessModes).

While PersistentVolumeClaims allow a user to consume abstract storage resources, it is common that users need PersistentVolumes with varying properties, such as performance, for different problems. Cluster administrators need to be able to offer a variety of PersistentVolumes that differ in more ways than size and access modes, without exposing users to the details of how those volumes are implemented. For these needs, there is the StorageClass resource.

```
cat >> pod_pv+pvc.yml << EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: my-container
    image: busybox
    command: ["sleep", "3600"]
    volumeMounts:   
    - name: my-volume
      mountPath: /mnt/my-data
  volumes:
  - name: my-volume
    persistentVolumeClaim:
      claimName: my-pvc
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 1Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"  # Replace with the actual path on your node
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Mi
---
EOF
```
kubectl apply -f pod_pv+pvc.yml


DA TESTARE !!!
```
cat >> condivisione_pvc_tra_due_pod.yml << EOF
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
    name: my-pvc
spec:
    accessModes:
      - ReadWriteMany
    storageClassName: myvolume
    resources:
        requests:
            storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: myapp1
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
      - mountPath: /data
        name: data
        subPath: app1
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: 'my-pvc'
---
apiVersion: v1
kind: Pod
metadata:
  name: myapp2
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
      - mountPath: /data
        name: data
        subPath: app2
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: 'my-pvc'
---
EOF
```


--> StorageClass
A StorageClass provides a way for administrators to describe the classes of storage they offer. Different classes might map to quality-of-service levels, or to backup policies, or to arbitrary policies determined by the cluster administrators. Kubernetes itself is unopinionated about what classes represent.

The Kubernetes concept of a storage class is similar to “profiles” in some other storage system designs.



## Comprendere gli RBAC

Role-Based Access Control sono uno strumento di gestione degli accessi al cluster. Definiscono policy per utenti, gruppi e processi, permettendo od impedendo l'accesso di gestire le specifiche API.

  - possiamo stabilire un sistema per gli utenti, con diversi ruoli, per accedere a diversi blocchi di risorse di k8s
  - possiamo controllare i processi in esecuzione nei pod le operazioni che essi sono in grado di fare

Questi strumenti rispondono a tre blocchi, collegando le API primitive alle operazioni ad esse permesse al, cosiddetto, soggetto che puo' essere un utente, gruppo o ServiceAccount.

Ecco le possibili responsabilita':

Soggetto: Utente o processi che vuole accedere alle risorse
Risorsa: l'API che deve fare qualcosa
Verbo: l'operazione che deve essere svolta dall'API su richiesta del soggetto.

### oggetto

cat >> mypod_rbac.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: sise
    image: ghcr.io/learnk8s/app:1.0.0
    ports:
    - containerPort: 8080
EOF

kubectl apply -f ./mypod

in questo esempio kubectl legge le configurazioni presenti in KUBECONFIG,  scopre le API e gli oggetti interpellando kube-API, valida le risorse lato client, invia le richieste del pay-load al kube-apiserver.

kube-apiserver non invia tutto a etcd perche' venga scritto, controlla prima se il richiedente e' autorizzato a alla richiesta.

"una volta autenticato, il richiedente e' autorizzato a creare risorse?"

AAA
Autentication
Authorization
Audit

"Identita' e permessi non non sono la stessa cosa!"

Il fatto di avere accesso al cluster non implica che sia autorizzato a creare risorse. k8s gestisce le autorizzazioni, usualmente, con gli RBAC ( Role Based Access Control )  con i quali possiamo assegnare permessi e restrizioni granulari ad azioni che utenti o applicazioni possono eseguire. 

RBAC sono un modello progettato per garantire accessi alle risorse, basati sui ruoli degli utenti all'interno delle organizzazioni.

Ad esempio:

| User  | Permission | Resource |
| ----- | ---------- | -------- |
| Bob   | read+write |   app1   |
| Alice |    read    |   app2   |
| Mo    |    read    |   app2   |


In Kubernetes succede qualcosa di molto simile, analizzando l'esempio deployato 
dell'nfs-provisione:

```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  namespace: nfs-storage
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: nfs-storage
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: nfs-storage
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: nfs-storage
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
---
```

Il blocco e' diviso in tre parti:
- Il ServiAccount -> riporta l'identita' di chi richiede l'accesso alla risorsa ( il pod "nfs-client-provisioner" del namespace "nfs-storage" )
- il Role - che include i permessi per accedere alle risorse
- il RoleBinding che collega l'identita ( riportata nel ServiceAccount ) ai permessi definiti ( nel RoleBinding )

Una volta applicato correttamente possiamo l'utente designato, potra' accedere ai servizi :

```
--> Risorse interne di Kubernetes 
/api/v1/namespaces/{namespace}/services
/api/v1/namespaces/{namespace}/pods

--> 2. Una specifica estensione API ad esempio
/api/v1/namespaces/{namespace}/pods/{name}
/api/v1/namespaces/{namespace}/pods/{name}/log
/api/v1/namespaces/{namespace}/serviceaccounts/{name}
```

### --> Andiamo nel dettaglio:

Kubernetes non ha un oggetto che rappresenta correttamente un utente,
gli utenti vengono autenticati tramite la presentazione di certificati e 
autorizzati tramite di roles.
Le informazioni riportate nel certificato, vengono poi importate

```
type User struct {
    name string   // unique for each user
    ...           // other fields
}
```

Come visto per autenticare un utente si parte dalla sua "creazione via ServiceAccount".

In K8S noi siamo interessati, tramite questi utenti, a modellare le risorse, siano esse pods, Services o Endpoints. Usualmente le informazioni a questo
riguardo sono salvate in etcd e ad esse si accede tramite le API.
Esse accettano come azioni, descrizioni quali :

```
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
```

La apiGroup e' un API speciale vuota che si riferisce ad un oggetto "builtin", 
ecco perche' le risorse sono interne al cluster, altre possibilita' sono pods, deploy, serviceaccounts ecc.

Kubernetes legge `""` ed espande il nome a `/api/v1/xxx` altrimenti diventa
qualcosa tipo `/apis/{apigroup_name}/{apigroup_version}/xxx`.
Nel nostro esempio noi scriviamo `resources: ["endpoints"]` e lui legge `/api/v1/namespaces/{ns}/endpoints`

In K8S una collezione di risorse e verbi si chiama "regola" perche' di fatto definisce un protocollo di ingaggio
```
...
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
    ...
```

queste regole contengono gli apiGroups, resources e verbs che abbiamo appena nominato.

Una collezione di regole prende il nome di "Role" in Kubernetes.

```
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: nfs-storage
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
```

Fino ad ora abbiamo istruito Kubernetes che esiste un `ServiceAccount`, il signor `nfs-client-provisioner` e che esiste un `Role`, ma i due non sono ancora collegati in alcun modo, sono "dormienti".
A collegare questi due oggetti ci pensano i `RoleBindings`.

```
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: nfs-storage
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: nfs-storage
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
```
Osservando questo esemppio notiamo che ci sono due 
aree specifiche di particolare importanza: 
  - `roleRef` che fa riferimento al `Role` `leader-locking-nfs-client-provisioner`
  - `subject` che connette il `ServiceAccount` `nfs-client-provisioner`






https://learnk8s.io/rbac-kubernetes



### resource Capping

kubectl create namespace resource-cap-example
kubectl apply -f <your-file-name>.yaml
kubectl get pod resource-demo --namespace=resource-cap-example -o yaml
kubectl top pod resource-demo --namespace=resource-cap-example