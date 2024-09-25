# IPTABLES


## Introduzione ai firewall e a iptables 
Un firewall è uno strumento hardware o software che, in base a regole specifiche, consente di autorizzare o meno il transito di pacchetti.

L’esame dei pacchetti può essere svolto secondo varie filosofie, con un diverso livello di complessità.

A livello base si parla di packet filtering, politica per cui la decisione viene presa a livello di pacchetto in maniera stateless (ogni pacchetto è analizzato a sé stante, senza avere memoria dei pacchetti passati) o stateful (si ha una qualche memoria dei pacchetti precedenti e si parla talvolta di session filtering).
Queste discriminanti solo legate esclusivamente alla connessione di riferimento.

Strumenti più potenti possono agire anche a più alto livello, fino a raggiungere quello applicativo.

Il filtraggio pacchetti ha senso per non consentire la ricezione di quelli provenienti da domini o indirizzi IP indesiderati: blacklisting e whitelisting.

Altro fattore da considerare è la modalità d’uso del firewall: proteggiamo una rete o una macchina? Nel primo caso parliamo di firewall perimetrale, nel secondo di firewall personale.

La componente firewall di iptables fa riferimento a una tabella detta filter, che è anche la tabella di default, per cui nei vari comandi non c’è bisogno di specificarla. L’altra informazione fondamentale è che iptables fa riferimento ad alcune sequenze di regole, dette chains (catene): ne esistono tre predefinite che si chiamano INPUT, OUTPUT e FORWARD ed è inoltre possibile crearne altre (più avanzato).

Tali regole definiscono il comportamento di iptables in merito al transito dei pacchetti: mentre la chain INPUT fa riferimento alle regole da applicare ai pacchetti destinati allo host dove è in esecuzione iptables, la chain OUTPUT si riferisce alle regole valide per i pacchetti originati dallo host (e destinati all’esterno dello host), mentre la chain FORWARD contiene le regole per i pacchetti che provengono dall’esterno e sono destinati all’esterno (rispetto all'host stesso).

Ne segue che normalmente un firewall perimetrale conterrà la chain FORWARD (e forse anche INPUT e OUTPUT), mentre un firewall personale userà INPUT e OUTPUT e mai FORWARD.

I comportamenti, in corrispondenza a ciascuna regola, prendono il nome di TARGET e, per ora, limitiamoci a dire che sono ACCEPT (pacchetto accettato) e DROP (pacchetto bloccato; DROP = lasciar cadere). Esistono altri TARGET ma ne parleremo più in avanti. Occupiamoci per ora del semplice packet filtering.

Come configurare il packet filtering
Si potrà iniziare digitando:

`iptables -vL`

dove l’opzione -L chiede di visualizzare la lista delle regole attive e -v richiede la modalità “verbosa” che in questo caso fornisce informazioni preziose (sulle interfacce di rete a cui le regole fanno riferimento).

Possiamo modificare la policy delle chain con:

`iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT`

Il risultato è cambiato per le chain diventando policy DROP.

Come esempio proviamo il comando:

`ping <IP_DELL'HOST>`

### Utilizzo di iptables come personal firewall

Oggi analizziamo iptables usato come personal firewall

Cominciamo a impostare la nostra whitelist, specificando le azioni consentite.

La prima è senz’altro autorizzare la connessione a localhost, perché molto software usa questa tecnica per la comunicazione fra le sue diverse componenti.

`iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT`

Qui l’opzione -A significa la volontà di “appendere” una nuova regola in calce alla chain specificata e le opzioni -i e lo introducono il nome dell’interfaccia di rete su cui le regole agiscono: lo denota appunto localhost.

L’opzione -j serve a introdurre il TARGET. Si noti che l’ordine con cui le regole appaiono nelle chains è significativo: esse vengono scandite sequenzialmente ed appena se ne incontra una applicabile si ha un “match,” la si usa e la scansione viene interrotta.

Proviamo ora a richiedere l’elenco delle regole:

`iptables -vL`

Notiamo che nella colonna prot (protocolli) appare scritto all, perché abbiamo specificato una regola senza precisare un particolare protocollo.

Supponiamo di voler consentire il ping, lo stesso di prima: per prima cosa si dovrà autorizzare il servizio DNS e poi lo specifico protocollo.

Come è noto, il protocollo DNS lavora sulla porta 53, nota con il nome domain, principalmente in UDP e qualche volta in TCP.

Specifichiamo allora l’autorizzazione in ingresso e uscita per UDP sulla porta 53: 

iptables -A INPUT -p udp –sport 53 -j ACCEPT
iptables -A OUTPUT -p udp –dport 53 -j ACCEPT.

In questi due nuovi comandi notiamo qualcosa di nuovo: l’autorizzazione (ACCEPT) data per il protocollo UDP con porta destinazione 53 (–dport 53) o porta sorgente 53 (–sport 53).

L’opzione -p introduce il nome del protocollo a cui ci si riferisce ed è importante sapere quali protocolli possiamo usare: tutti quelli di livello non superiore a TCP, poiché iptables non lavora a livello più alto. Così non avrebbe senso scrivere -p http o -p SSH (perché di livello più alto).

Autorizziamo la porta 53 anche per TCP, ottenendo:

iptables -vL

Si noti che dpt:domain indica la porta destinazione domain, cioè 53. Se tentiamo il comando ping menzionato ancora non ne abbiamo ancora il funzionamento.

Ciò perché non abbiamo ancora autorizzato il protocollo ping, che fa parte di ICMP.

Facciamolo: i messaggi inviati si chiamano echo-request e quelli ricevuti echo-reply.

iptables -A INPUT -p icmp --icmp-type echo-reply -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/s -m state --state NEW -j ACCEPT

Ovviamente, l’opzione –icmp-type introduce il tipo di messaggio desiderato.

Otteniamo:

iptables -vL

Dopo aver fatto ciò, siamo pronti a ripetere il ping:

ping <IP_DELL'HOST>

Siamo a buon punto. Se abbiamo compreso tutto, allora sarà facile consentire la visione del sito web di IMDB (Internet Movie Database). Basta autorizzare le connessioni TCP (in ingresso e uscita) con la porta 443 (https):

iptables -A INPUT -s 18.66.218.239 -p tcp –sport 443 –dport 1024:65535 -j ACCEPT

iptables -A OUTPUT -d 18.66.218.239 -p tcp –sport 1024:65535 –dport 443 -j ACCEPT

Qui notiamo le opzioni -s, che introduce l’IP sorgente del pacchetto, e -d, che introduce l’IP destinazione.

Evidentemente abbiamo usato la conoscenza del fatto che il FQDN[7] www.imdb.com corrisponde all’IP 18.66.218.239.

Mentre il server https conversa usando la porta 443, il client può usare un numero qualsiasi di porta, purché non well-known[8] (da 1024 a 65535, intervallo indicato con 1024:65535, anche se talvolta si usano convenzioni diverse[9]).


Nel caso si voglia autorizzare il protocollo SSH (usa TCP su porta 22) occorreranno regole differenti per un client o un server. Per un client:

iptables -A INPUT -p tcp –sport 22 –dport 1024:65535 -j ACCEPT

iptables -A OUTPUT -p tcp –sport 1024:65535 –dport 22 -j ACCEPT

Invece, per un server:

iptables -A INPUT -p tcp –sport 1024:65535 –dport 22 -j ACCEPT

iptables -A OUTPUT -p tcp –sport 22 –dport 1024:65535 -j ACCEPT

Le varie tecnicalità viste si possono combinare in vari modi, specificando in uno stesso comando anche cose come IP sorgente, IP destinazione, protocollo, porta, interfaccia di rete ecc. Inoltre, notiamo che abbiamo sempre usato -A (append) per aggiungere regole in ultima posizione della chain: invece di -A possiamo usare -I <chain> <numero> per inserire al posto specificato da <numero> la regola in questione nella chain <chain> (la prima è la regola numero 1).

Se si vuole, invece, rimpiazzare la seconda regola con un’altra <S> possiamo scrivere iptables -R <chain> 2 <S>. L’opzione -D permette la cancellazione di una regola: per cancellare la prima regola dalla chain OUTPUT scriveremo iptables -D OUTPUT 1.

Dal punto di vista amministrativo va notato che le regole entrano in vigore appena definite e si perdono al riavvio della macchina.

Per questo ci sono i comandi iptables-save > iptables_rules.dat e iptables-restore < iptables_rules.dat che consentono di salvare le regole correnti e di ripristinarle appoggiandosi al file iptables_rules.dat.

In alternativa, occorre inserire le regole all’interno della sequenza di avvio.

Le estensioni per iptables
Il software, già di per sé piuttosto ricco, ammette un cospicuo numero di moduli aggiuntivi che lo estendono in varie direzioni, arricchendolo ulteriormente. Essi possono essere specificati attraverso l’opzione -m.

Implicitamente abbiamo già sfruttato dei moduli aggiuntivi perché la specificazione di un protocollo attraverso l’opzione -p, determina l’inclusione automatica del relativo modulo. La lista delle estensioni è grande e può essere consultata digitando man iptables-extensions.

Come esempio, e con riferimento all’ultimo illustrato, mostriamo come si possa ottenere il blacklisting di 5.6.7.8 per 1.2.3.4 sia per http che per https. Senza estensioni avremmo dovuto impostare quattro regole. Con un’apposita estensione (la multiport) si ottiene una maniera compatta di specificare più porte sorgente o destinazione:

iptables -A FORWARD -s 1.2.3.4 -d 5.6.7.8 -tcp -m multiport –sports 1024:65535 –dports 80,443 -j DROP

iptables -A FORWARD -s 5.6.7.8 -d 1.2.3.4 -tcp -m multiport –sports 80,443 –dports 1024:65535 -j DROP

Notiamo le opzioni –dports e –sports (‘s’ aggiuntiva rispetto le tradizionali –dport e –sport) che introducono una sequenza di numeri di porta separati da virgole.

Ogni estensione può prevedere la possibilità di usare opzioni specifiche introdotte da essa, sempre precedute da “—“.

Le principali estensioni per iptables
Ecco un elenco non esaustivo di alcune estensioni notevoli:

addrtype: per distinguere fra indirizzi UNICAST, BROADCAST ecc.);
connbytes: per ragionare sulla quantità di byte già trasmessi in una connessione TCP);
connlimit: per limitare il numero di connessioni parallele a un server);
icmp: già implicitamente visto, poiché caricato con -p icmp);
iprange: per trattare con intervalli di indirizzi IP);
mac: per filtrare indirizzi MAC; può essere usata solo per pacchetti provenienti da rete Ethernet);
quota: per realizzare meccanismi di quota);
state: per distinguere in base allo stato della connessione TCP);
TCP: già introdotta;
e innumerevoli altre; per dettagli rimandiamo alla documentazione menzionata.

Come già accennato, quando si usa l’opzione -p seguita dal nome di un protocollo[10], il comportamento implicito di iptables è caricare una estensione corrispondente, così -p tcp produce lo stesso effetto di -m tcp.

Session filtering
Chiamiamo session filtering l’approccio di selezionare i pacchetti che possono passare basato su una qualche memoria: tipicamente lo stato della connessione TCP (UDP è connectionless) o i suoi flag.

Questo aiuta in alcune circostanze. Ad esempio, se consideriamo il protocollo ftp, questo prevede che il client si connetta al server sulla porta 21.

A connessione avvenuta, il trasferimento file avviene sulla porta 20.

Una tipica configurazione di iptables è bloccare le connessioni alla porta 20 a meno che queste non siano collegate (RELATED) a un’altra connessione già aperta.

Così se immaginiamo un firewall perimetrale, con interfaccia di rete eth1 verso Internet e eth2 verso la rete locale, con policy di default DROP, potremo abilitare la connessione sulla porta 20 del server ftp locale 1.2.3.4, con le seguenti regole:

iptables -A FORWARD -d 1.2.3.4 -sport 1024:65535 -dport 20 -i eth1 -o eth2 -m –state RELATED,ESTABLISHED -j ACCEPT

iptables -A FORWARD -s 1.2.3.4 -sport 20 -dport 1024:65535 -i eth2 -o eth1 -m –state RELATED,ESTABLISHED -j ACCEPT

I principali stati possibili sono:

NEW, pacchetto che ha iniziato una nuova connessione TCP o associato a una connessione TCP che non ha ancora inviato dati in entrambi le direzioni;
RELATED, pacchetto che sta iniziando una nuova connessione ma è logicamente associato ad una già esistente;
ESTABLISHED, pacchetto associato a una connessione che ha già inviato dati in entrambi le direzioni);
INVALID. pacchetto non associato ad alcuna connessione nota). Da non dimenticare che, essendo le comunicazioni bidirezionali, le regole vanno sempre a coppie.
Come altro esempio, per mostrare l’uso dei flag di una connessione TCP per un web server sulla porta 443.

Immaginiamo uno scenario rigidamente controllato, ove è in uso una policy basata su whitelisting (come spiegato, nessun transito di pacchetto è permesso tranne quelli esplicitamente concessi).

Supponiamo che siano già autorizzate le consultazioni del DNS (abbiamo visto come nel paragrafo Primo approccio a iptables).

Supponiamo di gestire un firewall perimetrale che protegge una LAN e che mostra un’interfaccia di rete eth1 verso Internet ed eth2 verso la LAN.

Desideriamo consentire agli utenti della LAN la connessione ai web server in https (porta 443). Dunque, la trasmissione dei pacchetti dai client della LAN ai web server richiederà una regola di questo tipo:

iptables -A FORWARD -i eth2 -o eth1 -p tcp –sport 1024:65535 –dport 443 -j ACCEPT

in cui si esplicita che i client debbono usare una porta non well-known per inviare dati alla porta 443 di un server.

D’altra parte, desideriamo anche che i web server forniscano risposte alle richieste ricevute:

iptables -A FORWARD -i eth1 -o eth2 -p tcp –sport 443 –dport 1024:65535 ! –syn -j ACCEPT

ove vale la pena precisare che si vogliono pacchetti dal server, ma questi debbono essere sempre forniti come una risposta (e quindi con il flag SYN a FALSE).

Se il server chiedesse di aprire una connessione avrebbe il flag TCP SYN impostato a TRUE: con l’opzione ! –syn chiediamo la negazione (è il ruolo del simbolo !) del fatto che il flag SYN sia a TRUE (e i flag RST, ACK e FIN a FALSE).

In generale l’estensione tcp consente di ragionare sui flag TCP attraverso l’opzione –tcp-flags <lista1> <lista2>, dove <lista1> è la lista di flag (separati da virgola) da prendere in esame e <lista2> è la sottoparte di <lista1> in cui sono elencati i flag che debbono valere TRUE (i non elencati debbono perciò essere FALSE).

Premettendo il ! a –tcp-flags si ottiene la negazione logica. Naturalmente –syn è equivalente a –tcp-flags END,ACK,FIN,SYN SYN.

Usi più avanzati di iptables
Un tipico uso “più professionale” dello strumento prevede la creazione di nuove chain, dette user-defined; queste chain hanno un nome scelto in fase di creazione e si vanno a sommare alle chain di default (INPUT, OUTPUT, FORWARD), dette built-in.

Il comando iptables -N mychain crea una user-defined chain, inizialmente vuota.

Sarà possibile aggiungere a tale chain regole tramite il costrutto iptables -A mychain <regola>.

In ogni regola, quando si specifica un target, sarà possibile usare, oltre ai classici ACCEPT e DROP, anche il nome di una user-defined chain (produrrà un effetto simile a una chiamata a subroutine) o la keyword RETURN (valida solo per le user-defined chains), che produrrà un ritorno del controllo alla chain chiamante.

Mentre per le built-in chains è possibile definire una policy, la cosa non è possibile per le user-defined chains, che in caso di scansione terminata si comporteranno come se avessero una policy RETURN.

Dopo la creazione di mychain sarà possibile considerare il nuovo target: -j mychain che, come accennato, produrrà la scansione, alla ricerca di un match, delle regole inserite nella chain mychain.

Queste possibilità consentono una migliore organizzazione delle regole in termini di leggibilità e gestione e permetteranno di avere la loro fattorizzazione e incapsulamento (le stesse proprietà che si desiderano nel software).

Ad esempio, con riferimento alle ultime regole specificate nella sezione precedente, che permettono ai client della LAN di usare il web, avremmo potuto definire le user-defined chains chiamate WEB_IN e WEB_OUT:

iptables -N WEB_IN

iptables -N WEB_OUT

e inserire le due regole della sezione precedente in queste user-defined chain:

iptables -A WEB_OUT -i eth2 -o eth1 -p tcp –sport 1024:65535 –dport 443 -j ACCEPT

iptables -A WEB_IN -i eth1 -o eth2 -p tcp –sport 443 –dport 1024:65535 ! –syn -j ACCEPT

inserendo nella FORWARD le chiamate:

iptables -A FORWARD -i eth2 -o eth1 -p tcp –dport 443 -j WEB_OUT

iptables -A FORWARD -i eth1 -o eth2 -p tcp –sport 443 -j WEB_IN

la cui logica mostra che non appena un pacchetto proveniente dalla o diretto alla porta 443 (le due regole in pratica realizzano l’OR logico, non disponibile come primitiva nello strumento) allora demandiamo la gestione del problema alle chain WEB_*, che potrebbero avere un numero superiore di regole (come in pratica accade) per distinguere casi desiderati e indesiderati.

A questo punto ci sentiamo di dire che il lettore che ha avuto tenacia e pazienza di leggere fino a qui può approfondire facilmente (opzioni e comandi sono molti) consultando le citate pagine di man.