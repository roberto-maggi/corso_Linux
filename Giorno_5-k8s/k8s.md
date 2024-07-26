# Kubernetes

K8S ci offre "Service discovery and load balancing" esponendo i nostri servizi su container usando 
fqdn ( tramite coredns ) e/o ip interni. Fa "Storage orchestration" facendo il provisioning di spazio 
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
K8S gestisce passwords, OAuth tokens, e chiazvi SSH, evitandoci di hardcodarle nei container
### Batch executions
### Horizontal Scaling

K8S ha un sistema di deploy che favorisce lo sviluppo decoupled, 
tramite l'uso intensivo di API e Load Balancers.

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

### CNI
La Container Network Interface e' la specification oggetto del deploy da parte dei vari network plugin come tigera, flannel o traefik tra gli altri. Il loro lavoro e' quello di allocare gli IP ai pod e abilitarli alla comunicazione interna ed esterna rispetto al cluster. 

## Perche' Kubernetes
- pods, o gruppi di container, si possono raggruppare insieme immagini sviluppate da team differenti. 
- servizi, offrono load balancing, naming e discovery per isolare un microservizio da un altro.
- namespaces, offrono isolamento e controlli d'accesso, cosi' che ogni microservizio possa controllare
    il livello di interazione con gli altri.
- Ingress, offrono un frontend comodo per combinare molteplici microservizi in una singola superfice 
    di API esternalizzata. 

Questo permette l'adozione di soluzioni dinamiche, quali lo scaling
verticale e quello orizzontale.

Visto che all'esame della CKA ci vengono presentati 6 cluster preinstallati sara' necessario spostarsi tra un cluster e l'altro con 

k8s config set-context <nome_del_cluster> --namespace <nome_del_namespace>

k8s ha molti comandi,la cui maggior parte ha una nomenclatura parecchio estesa, ma possiamo controllarli tutti

kubectl api-resources


## Comprendere gli RBAC

Role-Based Access Control sono uno strumento di gestione degli accessi al cluster. Definiscono policy per utenti, gruppi e processi, permettendo od impedendo l'accesso di gestire le specifiche API.

  - possiamo stabilire un sistema per gli utenti, con diversi ruoli, per accedere a diversi blocchi di risorse di k8s
  - possiamo controllare i processi in esecuzione nei pod le operazioni che essi sono in grado di fare

Questi strumenti rispondono a tre blocchi, collegando le API primitive alle operazioni ad esse permesse al, cosiddetto, soggetto che puo' essere un utente, gruppo o ServiceAccount.

Ecco le possibili responsabilita':

Soggetto: Utente o processi che vuole accedere alle risorse
Risorsa: l'API che deve fare qualcosa
Verbo: l'operazione che deve essere svolta dall'API su richiesta del soggetto.

### Creiamo un soggetto
Innanzitutto bisogna chiarire che utenti e gruppi non sono registrati in etcd, non facendo parte del cluster. I ServiceAccount esistono, invece, come oggetti di k8s e sibi usati dai processi in esecuzione nel cluster.

mkdir -p cert
--> creo la chiave
openssl genrsa -out UTENTE.key 2048
--> creo e firmo il certificato con la chiave per "utente" che e' parte di "gruppo" 
openssl req -new -key ./UTENTE.key -out UTENTE.csr -subj /"CN=UTENTE/O=gruppo"
--> firmo firmo il certificato definitivo con la ca del cluster
openssl x509 -req -in ./UTENTE.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out UTENTE.crt -days 364
--> creo un utente e lo registro in kubeconfig
ubectl config set-credentials UTENTE --client-certificate=./UTENTE.crt --client-key=UTENTE.key
--> creo un contesto per UTENTE
kubectl config set-context UTENTE-context --cluster=kubernetes --user=UTENTE
(
--> per cambiare contesto useremmo
kubectl config use-context UTENTE-context 
kubectl config current-context
--> per tornare al constesto di default usare il comando
kubectl config use-context
)

Ora abbiamo creato un utente che equivale ad una persona fisica che puo' loggarsi, ma i servizi usano i ServiceAccount per autenticarsi al cluster.

kubectl create serviceaccount build-bot

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build-bot
---

kubectl get sa
kubectl describe serviceaccounts build-bot

apiVersion: v1
kind: Secret
metadata:
  name: secret-sa-sample
  annotations:
    kubernetes.io/service-account.name: "build-bot"
type: kubernetes.io/service-account-token
data:
  extra: YmFyCg==

https://learnk8s.io/rbac-kubernetes