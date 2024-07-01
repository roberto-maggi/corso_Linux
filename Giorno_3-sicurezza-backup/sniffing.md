Sniffing, le basi
Nella prima parte dell'articolo si esamineranno i concetti base sullo sniffing, che, nella seconda parte, applicheremo alle connessioni cifrate SSL.

Funzionamento della scheda di rete in modalità promiscua
In una rete Ethernet, i sistemi che ne fanno parte comunicano tra essi incapsulando i datagrammi IP in frame: ogni scheda di rete possiede un suo indirizzo MAC; al fine della spedizione, ogni sistema incapsula i pacchetti IP in frame Ethernet, che contengono l'indirizzo MAC del destinatario, e li invia sulla rete stessa, la quale rete (attenzione) è fisicamente condivisa tra tutti i sistemi.

Ognuno, all'interno di questa rete, può intercettare le comunicazioni che vi transitano. Se una scheda di rete funziona in modalità promiscua, ovvero disabilita il filtro di comparazione degli indirizzi MAC, essa è in grado di leggere ogni frame Ethernet che passa per la rete o, nel caso di reti con switch, per il segmento di rete in cui si trova. Un comune software di packet sniffing (il più famoso è Wireshark, ex Ethereal) può, quindi, intercettare quanto trasmesso su tale segmento.

Dato che i comuni protocolli di livello applicativo di Internet sono plain-text non cifrati (compreso l'HTTP), sarà possibile carpire password e frasi significative, senza sforzo alcuno. Diverso è certamente il caso dell'HTTP su SSL (chiamato spesso HTTPS) o di altri protocolli che si avvalessero dei servizi SSL. In questo caso infatti le comunicazioni sono crittografate e le informazioni che transitano sulla porzione di rete condivisa non sono leggibili.

Attacchi agli switch
Generalmente i cavi di rete che escono da ogni PC vengono "uniti" mediante dispositivi intermedi, hub o switch, prima di giungere al router. Gli hub sono ripetitori di segnale: quanto ricevuto da ogni cavo ad essi collegato viene ripetuto sui cavi rimanenti. Gli switch sono ripetitori che instradano il segnale solamente verso il cavo cui è destinato, mantenendo traccia, in una CAM table, dell'associazione "indirizzo MAC" / "porta cui è connesso il cavo". La rete risulta, in questo caso, segmentata e non più sniffabile nella sua interezza con il metodo visto.

Un possibile attacco agli switch (ad alcuni tra essi per lo meno), al fine di modificare il loro comportamento e renderli assimilabili a semplici hub, è il riempire la loro CAM table tramite pacchetti con MAC address spoofati e diversi, ovvero far sì che la scheda di rete attaccante camuffi il proprio indirizzo MAC con altri, in grande quantità e diversi tra loro (come è possibile modificare un indirizzo IP sorgente in maniera semplice, così è possibile farlo anche per indirizzi MAC).

Riempiendo la CAM table (con informazioni fasulle), verranno sicuramente svuotate le corrispondenze "indirizzo MAC" - "porte più vecchie" e, non potendo trovarvi posto quelle nuove e consistenti, lo switch sarà divenuto un hub a tutti gli effetti: non sapendo cosa fare, questo ripeterà il traffico in ingresso su tutte le sue porte in una modalità definita come failopen mode. Sarà così possibile nuovamente sniffare il traffico di rete da una qualsivoglia macchina in LAN.

Tuttavia, gli switch moderni (se configurati) non "cadono" in simili tranelli ed isolano conseguentemente le macchine che generano traffico sospetto.

È resa per il nostro pirata? Assolutamente no: negli anni sono state messe a punto tecniche più efficaci (e per nulla più complicate, dal punto di vista logico) per riuscire a sniffarei dati che transitano nell'intera rete in presenza di qualsivoglia dispositivo intermedio (oltre ad altre tecniche di attacco agli switch che però non esamineremo).

Sniffing mediante ARP cache poisoning
L'associazione MAC-IP, una volta ottenuta attraverso le funzionalità del protocollo ARP, è memorizzata in una cache, sia in host sorgente che destinazione, per qualche tempo. Un cracker può facilmente avvelenare (poisoning) la cache degli end-point inserendo un indirizzo Ethernet da egli desiderato, generalmente il proprio.

L'implementazione del protocollo ARP-RARP su Linux e Windows è tale che vengano accettate risposte ARP anche senza aver inviato alcuna richiesta ARP! Se infatti un host riceve una ARP reply, anche se non sollecitata, esso memorizzerà l'associazione contenuta nella risposta anche se già presente in cache.

I cracker si fregano già le mani dalla gioia, anche perché questo, oltre allo sniffing (senza tra l'altro dover porre la scheda di rete in modalità promiscua), potrà dare origine ad una lunga serie di attacchi man in the middle: in un simile attacco, come suggerisce il nome, il traffico di rete tra due macchine viene dirottato ad una terza macchina (attaccante), facendo però credere agli end-point che l'attaccante sia, invece, il destinatario legittimo.

L'italianissimo Ettercap, nato come uno sniffer per LAN con switch (ed ovviamente con hub), col tempo è cresciuto ed è divenuto uno tra i più potenti tool esistenti per gli attacchi di tipo man in the middle.

Vedremo ora qualche esempio sul campo utilizzando la versione di tale software per Linux Debian, del quale è un pacchetto standard. Esiste anche la versione per Windows, ma è meno potente, meno semplice e, si dice, più problematica.

Cronologia di uno sniffing in LAN mediante Ettercap
Siano 192.168.0.40 e 192.168.0.50 due PC in rete locale (mi riferirò sempre ad essi tramite IP, anziché tramite nome). Sul primo gira un sistema operativo Windows XP e sul secondo Linux Debian. Le cache ARP prima dell'attacco sono come segue (in rosso il comando dato al prompt o alla shell).

192.168.0.40 (Windows XP Professional)

arp -a

Interfaccia: 192.168.0.40 --- 0x10003
  Indirizzo Internet    Indirizzo fisico      Tipo
  192.168.0.24          00-13-20-e4-3a-5a     dinamico 
192.168.0.50 (Linux Debian 4)

arp -n

Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.0.24             ether   00:13:20:E4:3A:5A   C                     eth0
È presente in entrambe l'indirizzo 192.168.0.24 perché da tale Pc (sempre in LAN) sono ad essi collegato (rispettivamente: via VNC per Windows e via ssh per Debian).

Dalla mia macchina 192.168.0.24 (Linux Debian 4) lancio l'attacco (necessita privilegi di root):

ettercap -T -M arp /192.168.0.40/ /192.168.0.50/
Il metodo arp di Ettercap implementa l'attacco man in the middle ARP cache poisoning. Vengono inviate ARP reply alle vittime per avvelenare la loro cache ARP. Una volta terminato l'avvelenamento, le vittime invieranno i loro pacchetti TCP/IP all'attaccante, credendolo il destinatario, e questi potrà in caso modificare ogni pacchetto e rinviarlo alla destinazione reale.

Cache ARP dopo l'avvelenamento.

192.168.0.40

arp -a

Interfaccia: 192.168.0.40 --- 0x10003
  Indirizzo Internet    Indirizzo fisico      Tipo
  192.168.0.24          00-13-20-e4-3a-5a     dinamico  
  192.168.0.50          00-13-20-e4-3a-5a     dinamico 
192.168.0.50

arp -n

Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.0.24             ether   00:13:20:E4:3A:5A   C                     eth0
192.168.0.40             ether   00:13:20:E4:3A:5A   C                     eth0
L'attaccante può, a questo punto, visualizzare il traffico tra le due macchine, come ad esempio mostrato di seguito.

Richiesta HTTP (da Firefox di 192.168.0.40, richiesta di http://192.168.0.50):

[...]

TCP  192.168.0.40:1426 --> 192.168.0.50:80 | AP

GET / HTTP/1.1.
Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/msword, */*.
Accept-Language: it.
Accept-Encoding: gzip, deflate.
User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322).
Host: 192.168.0.50.
Connection: Keep-Alive.
.

[...]
Risposta HTTP dall'Apache di 192.168.0.50:

[...]

TCP  192.168.0.50:80 --> 192.168.0.40:1426 | AP

HTTP/1.1 302 Found.
Date: Tue, 06 Mar 2007 10:03:43 GMT.
Server: Apache.
Location: http://192.168.0.50/apache2-default/.
Vary: Accept-Encoding.
Content-Encoding: gzip.
Content-Length: 196.
Keep-Alive: timeout=60, max=95.
Connection: Keep-Alive.
Content-Type: text/html; charset=iso-8859-1.
.
..........-.M..0........Fb.....$~p.........0.......6.K....."..>..8.....)b..-b...H.!f.P..|])rll....X%..m.=,.x.....6.3.....).Vi.`...........-.....*t..K.x!E<..H.2A.....Z.....*.O&4J......%C......R....

[...]
Al termine dell'attacco il programma "rimetterà le cose a posto":

Address                  HWtype  HWaddress           Flags Mask            Iface
192.168.0.24             ether   00:13:20:E4:3A:5A   C                     eth0
192.168.0.40             ether   00:40:F4:B1:A5:88   C                     eth0
Affinché sia possibile lo sniffing dall'Internet, cioè dall'esterno della LAN dell'organizzazione, con tali metodologie è necessario aver preso preventivamente controllo di una macchina interna alla rete alla quale appartiene la macchina bersaglio, ed utilizzare un qualche programma che permetta la comunicazione con l'esterno.

Non sottovalutiamo mai gli attacchi dall'interno: statistiche riportano che oltre l'80% dei crimini informatici proviene dall'interno della rete.

DNS spoofing: siamo certi che il sito Web navigato sia quello richiesto?
Nella prima parte di questo articolo abbiamo visto come sia possibile, nella pratica, sniffare il traffico di rete tra due macchine di una LAN Ethernet, indipendentemente dal sistema operativo da queste utilizzato ed indipendentemente dai dispositivi di rete intermedi. Il rimanente traffico, anche quello generato da un browser (ad esempio) può esser sniffato, ed ogni dato trasmesso in chiaro visualizzato dal cracker (non che i dati cifrati non vengano letti,.. ma almeno non vengono capiti).

Più avanti vedremo appunto come l'SSL rappresenti l'unico metodo realmente valido nel combattere il fenomeno dello sniffing, a patto che venga usato consciamente. Lo sniffing in sé, tuttavia, non è il solo pericolo incombente sull'utilizzo di Internet da rete locale.

Come noto, prima della connessione effettiva, il browser od ogni altro client (il sistema operativo in realtà) risolve il nome simbolico dell'host del sito Web, od altro server, di destinazione attraverso il DNS. Dato il nome simbolico del tipo www.sito-che-voglio-vedere.com, attraverso una rete di server DNS, ne ottiene il rispettivo indirizzo IP al fine di poter fisicamente iniziare una connessione ed uno scambio di dati mediante il solito protocollo TCP/IP.

È possibile che, attraverso un attacco man in the middle, l'host del cracker si sostituisca al server DNS e dia informazioni false, associando nomi simbolici ad indirizzi IP in suo controllo, oppure ancora associ il nome simbolico del sito Web cercato dal client con il proprio IP e funga, di conseguenza, da proxy per tutti i servizi che il client si aspetta di trovare sul server (nel nostro caso appunto il Web).

Il pluigin dns_spoof di Ettercap intercetta le query DNS e risponde con le informazioni desiderate dall'attaccante.

È possibile selezionare le corrispondenze "URI richiesti" - "IP forniti" come fake tramite il file etter.dns:

cat > /usr/share/ettercap/etter.dns
*google* A 192.168.0.50
^D
A questo punto è possibile lanciare l'attacco all'host 192.168.0.40. Nel seguente scenario l'IP 192.168.0.254 è il router dell'organizzazione mentre l'IP 62.94.0.2 è il server DNS esterno.+

ettercap -T -M arp:remote /192.168.0.40/ /192.168.0.254/ -P dns_spoof

ARP poisoning victims:
GROUP 1 : 192.168.0.40  00:40:F4:B1:A5:88
GROUP 2 : 192.168.0.254 00:13:49:A3:09:CE

Starting Unified sniffing...
Activating dns_spoof plugin...

UDP  192.168.0.40:1025 --> 62.94.0.2:53 |
I............www.google.it.....

dns_spoof: [www.google.it] spoofed to [192.168.0.50]

[...]
Il risultato è che il browser del client punta al webserver su 192.168.0.50 in risposta alla chiamata HTTP a www.google.it! Ovviamente con l'aggiunta di sniffing di tutto ciò che viene trasmesso dalle parti.

Modifica dati in transito
Poiché l'attaccante ha il pieno controllo di quanto scambiato tra macchine di una LAN, tra loro o verso l'Internet, è immediato capire che un attacco man in the middle può portare, oltre al mero sniffing ed allo spoofing del DNS, anche ad attacchi più intrusivi, quali, per rimanere in ambito Web, la modifica dei dati in transito oppure la modifica dei file binari eseguibili durante lo scaricamento degli stessi.

L'SSL ci protegge? E quanto ci protegge?
L'SSL (configurato a dovere):

Protegge i dati in transito, cifrandoli, di modo che sia praticamente impossibile una loro decifratura in tempi accettabili;
Garantisce l'identità degli end-point (nel "mondo Web" generalmente solo del server), attraverso i certificati.
Ma

Non protegge (ovviamente) i dati su client e server, rispettivamente prima e dopo la cifratura/decifratura: se, in soldoni, è presente un programma trojan su un dato PC, non sperare che i numeri di carta di credito inviati rimangano segreti a lungo.. Così come è necessario proteggere i dati su server da attacchi cracker (si vedano le guide sulla sicurezza LAMP e PHP offerte da HTML.it);
L'implementazione (non l'algoritmo matematico, fino ad ora per lo meno) può esser soggetta a security hole.
Di nuovo: per i cracker è resa, per ciò che riguarda gli attacchi man in the middle su connessioni sicure? Forse. Questa volta dipende in massima parte dalla competenza degli utilizzatori finali. Del resto, è di accertata validità la seguente massima: Programming today is a race between software engineers, striving to build bigger and better idiot-proof programs, and the Universe, trying to produce bigger and better idiots. So far, the Universe is winning ['La programmazione oggi è una gara fra programmatori che si sforzano per progettare software sempre più grande e sempre più a prova di idioti e il cosmo che cerca di produrre idioti sempre più grandi e migliori. Fino ad oggi il cosmo sta vincendo'].

Torniamo sul nostro argomento, ricordando che per una panoramica sul protocollo SSL potete fare riferimento ai nostri articoli Apache e SSL: i certificati e Apache e SSL: la configurazione. Per compiere un attacco man in the middle su protocollo SSL Ettercap sostituisce il certificato reale proveniente dal server Web con un certificato fasullo, creato al volo ed analogo a quello reale, ma ovviamente firmato con una diversa chiave privata, quella di Ettercap (salvata in /usr/share/ettercap/etter.ssl.crt).

Non può ovviamente creare un certificato identico all'originale od usare l'originale medesimo superando nel contempo la fase iniziale di handshake SSL (cioè la fase in cui i partecipanti alla comunicazione si riconoscono come legittimi), perché Ettercap non è in possesso della chiave privata del server né tantomeno di quella dell'autorità di certificazione (CA).

All'atto della connessione con il server Web "sicuro", il browser darà quindi debito avviso all'utente di non essere in presenza di certificato valido, ma spesso l'utente, ignaro o tratto in inganno, passerà oltre senza curarsene.

Cronologia di uno sniffing SSL (Web)
Tentiamo lo sniffing di una connessione SSL tra 192.168.0.40 e https://addons.mozilla.org con i metodi finora visti:

ettercap -T -M arp:remote /192.168.0.40/ /192.168.0.254/

[...]

TCP  63.245.213.31:443 --> 192.168.0.40:1275 | A 

.....J..[U....9.K.......        4|.k]xG"...v..._..../.87.b..-.".2
,........w.6..^g.f..lk:....OQ.n.zEv.S..A.f....%.*'....!..i.......
..Y..2 Q...&..?B^.....i.....W...y....[.`..F......A.S..q!...?B4...
G....S.8.E.u...(..._..t......Lj........~/...).D.H8W.......u.y..=.
L...#   .8.a.x....c.1..#.G...P..Cc.BYY..NJO     .....1...j..x.O..
I>}....6xl?IUb.....Ga"D..4.?....5.7!.S..7J.=.....L...G.....x..^.`
7.n2..8....6../F-8.5r....sp.L.....9..r...>.......UDA...FX= 
.......]?....(.............X    Gm.M<.h....e.5.G{|cc...r........
.....&..g)}...0}..1F.U=.......2.....Y.....+.....2W.)E...v..@.._.
..k.!T.k.....P./d.,V..}....;.....^.,.x.jf.._._)...2j..8>

[...]
Tutto il flusso HTTP è oscurato, non è dato leggere nulla di comprensibile; il risultato, del resto, era atteso. Ma possiamo fare qualcos'altro.

Abilitiamo ora lo sniffing SSL in Ettercap, da file di configurazione /etc/etter.conf (sezione redir_command_on/off, eliminando il commento dalle righe della sottosezione iptables) ed iniziamo l'attacco man in the middle prima che la connessione SSL tra gli end-point abbia inizio, ovvero prima che l'utente inserisca l'URL da browser.

In questo caso, all'atto della connessione, l'utente di Firefox vedrà una pop-up simile alla seguente:

Figura 1: Finto certificato in Firefox
Certificato in Firefox
Il sito https://addons.mozilla.org esporrebbe un certificato valido, firmato da una CA riconosciuta dal browser. Quello che il browser riceve nell'attacco non è però il certificato del sito Web detto, ma quello creato da Ettercap, ed avvisa l'utente del pericolo. Se l'utente, ignaro, accetta, l'attaccante può sniffare il traffico trasmesso, anche in presenza di SSL!

E, detto tra noi, la massima di Cook di cui sopra ne gioverebbe.

In questo caso:

[...]

TCP  192.168.0.40:1395 --> 63.245.213.31:443 | P 

GET /it/firefox/pages/js_constants.js HTTP/1.1. 
Host: addons.mozilla.org. 
User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; it; rv:1.8.1.4) Gecko/20070515 Firefox/2.0.0.4. 
Accept: */*. 
Accept-Language: it-it,it;q=0.8,en-us;q=0.5,en;q=0.3. 
Accept-Encoding: gzip,deflate. 
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7. 
Keep-Alive: 300. 
Connection: keep-alive. 
Referer: https://addons.mozilla.org/it/firefox/. 
Cookie: __utmz=164683759.1182933364.1.1.utmccn=(direct)|utmcsr=(direct)|
utmcmd=(none); __utma=164683759.506631186.1182933364.1182934446.1182935176.5;
 __utmb=164683759; __utmc=164683759. 
. 

[...]
La causa remota della riuscita di tali attacchi (quasi da ingegneria sociale) sta nel fatto che alcuni siti Web auto-firmano i propri certificati, costringendo il browser a visualizzare spesso avvertimenti simili al precedente ed abituando l'utente, nei casi migliori, ad accettare sempre quanto gli viene proposto, senza farsi più di qualche domanda.

In sintesi: l'SSL è sicuro ed a prova di inganno solamente se i certificati sono firmati da una CA direttamente od indirettamente riconosciuta dal browser, l'utente è consapevole di ciò che fa ed ogni programma coinvolto è aggiornato e privo di buchi di sicurezza.