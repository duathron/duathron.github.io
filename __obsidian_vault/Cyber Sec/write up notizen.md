
https://tryhackme.com/room/snortchallenges2

  

traffic erstmal analysiert mit sudo snort -X -n 100 -A console. dabei fällt schnell eine ip auf, die häufig vorkommt: 10.10.245.36. die connection erfolgt von epheremal ports und läuft immer auf 10.10.140.29:22 . also über TCP port 22 = SSH Tunnel.

  

ich habe die regel dazu geschrieben:

drop tcp 10.10.245.36 any -> any any (msg:"Attacker IP dropped."; sid:1000001; rev:1;)

  

also eine local.rules datei erstellt und den command laufen lassen

  

sudo snort -c ./local.rules -v -n 15000 -X -A full 

  

-n 15000 damit auf jeden fall eine minute oder mehr geloggt wird und die flag auf dem desktop (wie beschrieben im raum) erscheint. funktioniert. vorher hatte ich kein limit eingebaut und die VM hat sich aufgehängt. ich konnte den ips modus also nicht unterbrechen. 

  
flag erscheint nach einer weile, wie im raum beschrieben, auf dem desktop. die weiteren fragen sind quasi schon beantwortet:es handelt sich um einen ssh tunnel und der funktioniert standardmäßig über tcp port 22.

PS: LEARNING: ich habe zuerst eine andere ip blockiert, die viele kurze anfragen über port 80 geschickt hat. das wiederum hat ebenfalls die flag auf dem desktop erscheinen lassen - fehler in der konfiguration? eventuell wird nur geprüft, ob die snort regel funktioniert. dann hatte ich probleme die restlichen fragen zu beantworten. nach einem kompletten neustart sind mir dann verstärkt die anfragen zu port 22 aufgefallen.
ich habe auch nicht den command sudo snort -c local.rules -Q --daq afpacket -i eth0:eth1 -A full benutzt . dieser war laut snort walkthrough room der befehl für den IPS mode von snort. sicherlich ein fehler meinerseits, der aber am ende trotzdem zur flag führte. ich werde mich mit den einzelnen modi nochmal intensiver befassen.



task 3 reverse-shell

erstmal sudo snort -X um traffic fließen zu lassen. schnell fällt auf, dass einiges an traffic an 10.10.144.156:4444 geht.

also eine rule geschrieben und getestet. 
alert tcp any any -> any 4444 (msg:"Blocked outbound port 4444."; sid:1000001; rev:1;)

funktioniert offenbar. läuft im IPS mode bis die flag auf dem desktop erscheint. 
ich habe dafür 15000 packets durchlaufen lassen, auch wenn die flag schon eher erschienen ist. hier ein screenshot des ergebnisses: (siehe bild)

die interessanten packets stammen dabei von der ip 10.10.196.55. 
die frage nach protokoll und port ist klar gelöst: TCP / 4444
and the tool commonly used with this port? Metasploit. 4444 is the default port for reverse shells / meterpreter

________________________________


lookup room

ip zu /etc/hosts hinzufügen, weil sonst dns aufgelöst wird und nichts gefunden.

nmap -sV -sC -O TARGET_IP 
-> SSH und TCP offen (22 und 80)
-> Apache auf Linux

ffuf -w '/home/kali/wordlists/SecLists/Discovery/Web-Content/common.txt' -u http://TARGET_IP/FUZZ -recursion -recursion-depth 2 -p 0.2     

enteckt mehrere seiten, darunter versteckte dateien mit mit status 403 und index.php mit 302


pause wichtig, weil sonst timeout vom server! beim zweiten versuch mit ffuf und redirects folgen -r -> index.php status 200

ffuf -w '/home/kali/wordlists/SecLists/Passwords/Leaked-Databases/rockyou.txt' -u http://lookup.thm/login.php -X POST -d 'username=admin&password=FUZZ' -p 0.3 -fs 74 -c 
falsche credentials ergeben status 200 mit mitteilung, dass es falsch ist und weiterleitung in 3 sekunden. also -fs 74 (größe der antwortseite)

echo -e "admin\Administrator" | ffuf -w '/home/kali/wordlists/SecLists/Passwords/Common-Credentials/Pwdb_top-1000000.txt':FUZZ -w  -:users -u http://lookup.thm/login.php -X POST -d 'username={users}&password=FUZZ' -H "Content-Type: application/x-www-form-urlencoded" -p 0.3 -fs 74 -c 
als alternative um zumindest die beiden usernames zu testen. keine schnellen funde

dann nochmal manuell nachgehakt: admin ergibt die fehlermeldung: wrong password.
user/ pass = karl/password ergibt wrong username and password!

also gibt es den user admin!  also nochmal rockyou herausgeholt mit user admin und treffer! = password: password123

das wirft natürlich die frage auf: gibt es andere user? nochmal baseline für die falsche nutzerkennung abgeholt: -fs 74
und ja! direkte treffer: admin und jose

dann jose cracken - selber ansatz wie beim admin passwort, nur username=jose. das passwort ist "password123"

funktioniert für jose. admin gibt eine fehlermeldung -> also falscher filter. bei jose gab es die response size 0 das richtige password. also nochmal den admin brute forcen mit -fs 0

der login bei jose führt zu files. lookup.thm -> also die subdomain in /etc/hosts

dann loggen wir uns bei jose ein und kommen auf ein virtuelles laufwerk:
http://files.lookup.thm/elFinder/files/credentials.txt?_t=1712061058
http://files.lookup.thm/elFinder/files/test?_t=1712061058
http://files.lookup.thm/elFinder/files/admin.txt?_t=1712061058

sieht nach enumeration aus -> vielleicht versteckte dateien?


scheinbar keine offensichtlichen subdomains außer "www"
