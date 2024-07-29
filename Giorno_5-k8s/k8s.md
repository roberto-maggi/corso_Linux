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

k8s config set-context <nome_del_cluster> --namespace <nome_del_namespace>

k8s ha molti comandi,la cui maggior parte ha una nomenclatura parecchio estesa, ma possiamo controllarli tutti

kubectl api-resources

## Tecniche di gestione

Kubernetes supporta tre modalita' di gestione:

- comandi imperativi

    kubectl create deployment nginx --image nginx

- configurazione imperativa degli oggetti

    kubectl create -f ./nginx.yaml

- configurazione dichiarativa degli oggetti

    kubectl diff -f configs/
    kubectl apply -f configs/

## Oggetti

### Nomi e UID

Ascrivibilita' in codice

siccome ogni oggetto verra' "encodato" e ad esso verranno fatti riferimenti tramite "path"
deve essere registrato secondo delle regole, k8s non supporta quindi nomi di oggetti con 
caratteri quali ".,/%!?"

Una volta che il nome e' accettato k8s creera' un UID unico per l'oggetto generato.

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
...

oppure

...
selector:
  environment != production
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
La seconda ricerca per tutti i risultati di tier non nelle chiavi "frontend" e "backend", 
mentre la terza e la quarta includeranno ed escluderanno, rispettivamente, ogni chiave 
contenente o no "partition", a prescindere dai volori ad esse associati.   

Labels suggeriti
Al fine di garantire una gestione il piu' possibile semplificata e' comnsigliabile di utilizzare
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

### Annotations

Al contrario delle labels, k8s non e' in grado di usare le informazioni presenti in questi metadati.
Essi devono pero' rispettare alcuni criteri, come il fatto di essere "string", quindi non numerici 
o booleani.

### Field Selector

Questo strumento ci permette di fare selezioni in base al valore dei campi attribuiti ad un oggetto
https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/#list-of-supported-fields

```
kubectl get pods --field-selector=status.phase=Running,spec.restartPolicy=Always
```

### Owners & Dependents

Con questi termini definiamo la relazione di alcuni oggetti, secondo cui, ad esempio, un ReplicaSet e' "owner" dei Pod che genera.


## I componenti di di Kubernetes

Quando parliamo di k8s parliamo di un cluster, un gruppo di componenti che creano un sistema atto a svolgere un compito
distribuendo in modo ordinato specifiche operazioni.

< kubernetes cluster arch >

Un cluster k8s e' composto almeno da (N*2)+1 "controplane node" e 1 "worker node", essenzialmente il cp controlla e gestisce
il lavoro svolto dal wn.

### --> ControlPlane

### kube-api-server
E' il componente principale di un cluster, l'unico che parla con tutti gli altri e con il quale ognuno comunica.

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
E' un agente che in esecuzione su ogni wn del cluster e si assicura che i container siano in esecuzione dentro i relativi pod.
Essenzialmente legge i dati presenti nei PodSpecs e li valida, assicurandosi cosi' della "salute" dei pod.

### kube-proxy
Questo e' il proxy  che gira su ogni wn del cluster e implementando una parte del concetto di Service di k8s.
Esso  amministra le regole di networking del nodo, che ne permettono la corretta comunicazione dentro e fuori dal cluster.
kp Usa il layer di packet filtering del OS, se presente e disponibile, altrimenti ne esegue autonomamente il forwarding.

### Container Runtime
Il CRI e' responsabile della corretta esecuzione e lifetime dei container all'interno dell'ambiente di k8s. 
k8s supporta containerd, CRI-O e ogni implementazione di Kubernetes CRI

### -> addons

### DNS
k8s ha un dns server cluster interno, quello di default e' coredns.
Le query eseguite da un pod seguono una gerarchia simile a quella di ogni altra applicazione, in cui la priorita' piu' alta
la ottiene il motore interno al pod, poi coredns, ed infine il dns dell'host su cui k8s e' installato.
Un record DNS ottiene un fqdn simile a my-svc.my-namespace.svc.cluster-domain.example ( come A/AAA record ), mentre uno 
"headless" si riferisce essenzialmente ad un pod, bypassandone il servizio.

### Dashboard

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
kubectl logs --previous
kubectl logs counter -c count

Benche' k8s non offra nativamente un sistema di logging esistono svariati approcci che possiamo considerare.
  - un agente installato sul singolo nodo ( DaemonSet )
  - un container sidecar per loggare il pod

cat > sidecar_logging.yml << EOF
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

  - un log exporter o un log push verso una applicazione di backend

### CNI
La Container Network Interface e' la specification oggetto del deploy da parte dei vari network plugin come tigera, flannel o traefik tra gli altri. Il loro lavoro e' quello di allocare gli IP ai pod e abilitarli alla comunicazione interna ed esterna rispetto al cluster. 

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
Una volta che il nodo e' creato e/o si e' autoregistrato, viene analizzata la sua validita' dal controlplane, al quale basta una istruzione tipo la seguente:

cat > nodo_che_si_rompe.yml << EOF
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
EOF

Nella fase di auto registrazione, il default con kubeadm, kubelet si esegue con le seguenti opzioni:
  . --kubeconfig  ( le proprie credenziali per il kube-API-server )
  . --cloud-provider ( solo se su cloud )
  . --register-node ( registrazione autometica )
  . --register-with-taints
  . --node-ip 
  . --node-labels
  . --node-status-update-frequency

In caso di registrazione manuale passare  `--register-node=false` a kubeadm e nel caso in cui si voglia impedire il deploy sul nodo usare `kubectl cordon $NODENAME`

per analizzare lo stato di un nodo

kubectl get nodes <NOME_DEL_NODO>
kubectl describe node <NOME_DEL_NODO>

k8s usa un "hub-and-spoke" in cui l'API-server fa da torre di controllo per tutti gli altri componenti del cluster.
Il kubelet comunica direttamente tramite la 443 all'API e si autentica tramite un certificato client, generato tramite il TLS bootstrapping.
I pod che devono comunicare con l'API server lo fanno grazie al relativo ServiceAccount nel quale viene iniettata il certificato pubblico di root e un bearer token generato alla creazione del pod stesso.

nota: bearer token va interpretato come "l'auteticazione e' garantita al bearer ( portatore ) di questo token".
Il Service relativo e' configurato con un IP virtuale e rediretto da kube-proxy all'endpoint dell API-server.


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

https://learnk8s.io/rbac-kubernetes