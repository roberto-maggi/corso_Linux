# Kubernetes


K8S ci offre "Service discovery and load balancing" esponendo i nostri servizi su container usando fqdn ( tramite coredns ) e/o ip interni. Fa "Storage orchestration" facendo il provisioning di spazio disco ai vari pod che ne fanno richiesta.
Automatizza rollout e rollback, tramite i manifesti in yaml possiamo descrivere lo stato ( versione ) in cui vogliamo i nostri container, lasciando a lui il compito di occuparsene.
Bin Picking automatizzato, e' possibile definire le risorse che ogni container puo' 
assumere e K8S si occupera' di offrirgliele e gestirle.
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

- pods, o gruppi di container, si possono raggruppare insieme immagini sviluppate da team differenti. 
- servizi, offrono load balancing, naming e discovery per isolare un microservizio da un altro.
- namespaces, offrono isolamento e controlli d'accesso, cosi' che ogni microservizio possa controllare il livello di interazione con gli altri.
- Ingress, offrono un frontend comodo per combinare molteplici microservizi in una singola superfice di API esternalizzata. 

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