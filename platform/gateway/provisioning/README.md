# Host-Provisionierung

Zielumfang, Profile, offene Entscheidungen und Entwicklungspakete stehen im [Installationskonzept](INSTALLATIONSKONZEPT.md). Die übergeordnete Architektur und der Fahrplan A–F sind freigegeben; Vorschlagsdetails werden im jeweiligen Paket gesondert festgelegt und freigegeben. Diese README beschreibt die verfügbare Implementierung; tatsächliche Hardwaremeldungen stehen im [Projektstatus](../../../docs/PROJEKTSTATUS.md#gateway-provisionierung).

[`install.sh`](install.sh) prüft die Laborbasis, legt fehlende Projekt- und Laufzeitverzeichnisse unter dem ermittelten Benutzer-Home an und richtet den Node-RED-Container ein. Neue Verzeichnisse erhalten die UID und primäre GID des Projektkontos sowie den Modus `0750`. Bei `sudo` läuft die Verzeichnisanlage mit den Rechten des Projektkontos über `setpriv`.

Der Installer prüft vorhandene Pfade auf Typ, Eigentümer und Zugriff, bevor er Verzeichnisse anlegt. Konflikte werden mit dem betroffenen Pfad gemeldet. Die Hardwareergebnisse und der jeweilige Prüfstand stehen im [technischen Projektstand](../../../docs/PROJEKTSTATUS.md#gateway-provisionierung).

Aufruf aus der Repository-Wurzel auf dem Gateway

```bash
sudo bash platform/gateway/provisioning/install.sh labor
```

## C1 – Beide vorhandenen Profile per MAC binden

`c1-install` bindet automatisch die eindeutig vorhandenen LAN1-/LAN2-Ethernetprofile an die permanente Hardware-MAC und leert nur `connection.interface-name` und `match.interface-name`. UUIDs, Autoconnect und vollständige IP-/DHCP-/Gateway-/DNS-/Routen-/IPv6-Einstellungen bleiben erhalten; LAN2 bleibt normal IP-fähig. Kein neues Profil, Up/Down/Reapply, Konfigurationsreload oder Unmanaged-Delta. Unklare Zuordnung blockiert.

```bash
sudo bash platform/gateway/provisioning/install.sh c1-install
sudo bash platform/gateway/provisioning/install.sh c1-status
```

`c1-install`: Exit `0` fertig/korrekter No-op, `1` Fehler. `c1-status`: ausschließlich lesend, Exit `0` Bindungen korrekt, `1` fehlend/Fehler; keine Datei-/Lockanlage. Vor erster Änderung entsteht das einmalige private Backup beider Original-Keyfiles mit Hashes und Metadaten unter `/var/lib/friedrich/c1/profile-backup`; nie überschreiben. Kein automatischer Rückfall bei Teilfehlern; gezielten manuellen Restore beider Manifestpfade verwenden. [Konkreter Ablauf und Restore](C1_NETZWERK.md).

Der Status des letzten alten Hardwareversuchs `fdc6522353f89699` ist unbekannt. Bei einer entsprechenden Blockade nimmt Johannes ihn mit dessen eingefrorenem Helper über USB/Konsole zurück. Pending/offene/inkonsistente Altzustände und alte LAN2-Unmanaged-Dateien blockieren; nichts pauschal löschen. 31 gezielte Tests, Python-/Bash-Syntax und Hilfetext bestanden; Hashes/Grenzen siehe [C1-Prüfnachweis](C1_NETZWERK.md#prüfnachweis-und-abnahme). USB-Kaltstart ohne LAN1 ist auf beiden Geräten erfolgreich berichtet, C1-Hardwareabnahme bleibt offen. `C1_IN_LAB_APPROVED=no` bleibt bis zur Hardware-/Neustartabnahme beider Geräte; später nutzt der Laborpfad denselben Bindungscode. Codex führt keine Gatewayaktionen aus.

**Genau ein nächster Schritt:** Johannes führt nach gegebenenfalls nötiger Altbereinigung über USB/Konsole den beschriebenen AI7100-C1-Test mit Wiederholung und manuellem Neustart durch; erst bei Erfolg folgt AI7020. Paket A/Node-RED/B2 bleiben erhalten.

## Voraussetzungen und Container

Das Laborprofil setzt Ubuntu 22.04 auf ARM64 mit L4T R36.4.0, vorhandenes `python3` sowie Docker Server ab Version 28 voraus. `docker.service` muss aktiv und für den Bootstart aktiviert sein. Der Installer meldet eine fehlende Voraussetzung zur Klärung. Paket-, BSP- und Netzwerkprofile werden durch diesen Node-RED-Schritt nicht geändert.

Das festgelegte Image ist

```text
ghcr.io/node-red/node-red:5.0.9-debian@sha256:260face7ad06c0968dd130717d1f08fa1d9985e6ff20e26d66f366b9d27bc22a
```

Die [offizielle Paketseite](https://github.com/node-red/node-red-docker/pkgs/container/node-red) ordnet diesen Digest `linux/arm64` zu. Die [Image-Dokumentation](https://github.com/node-red/node-red-docker#image-variations) nennt Node.js 24 und Debian `trixie-slim` für `5.0.9-debian`. Tag und Digest legen den gewählten Stand fest. Ein späterer Versionswechsel braucht eine eigene Prüfung.

Der Container heißt `mynodered`. Er läuft mit der ermittelten UID und primären GID des Projektkontos. Dieses Image enthält den Benutzer `node-red` mit UID 1000. Deshalb setzt der aktuelle Schritt Projektkonto-UID 1000 voraus und meldet abweichende UIDs als Anpassungsbedarf. OpenSSH benötigt für den Projects-Zugriff einen zur UID passenden Benutzereintrag im Container. Die Verzeichnisse der beiden berichteten Testgeräte gehören bereits UID/GID `1000:1000`. [Image-Benutzer](https://github.com/node-red/node-red-docker/blob/master/.docker/Dockerfile.debian#L22), [OpenSSH-Benutzerauflösung](https://github.com/openssh/openssh-portable/blob/master/ssh.c#L635).

## Projekte, Runtime und Neustart

| Hostpfad unter dem ermittelten Benutzer-Home | Containerpfad | Zweck |
|---|---|---|
| `friedrich-projects/nodered_runtime` | `/data` | Einstellungen und persistente Laufzeitdaten |
| `friedrich-projects/workspace/nodered/projects` | `/data/projects` | Node-RED-Projekte |

Unter `nodered_runtime` wird `projects` als leerer Mountpunkt mit Eigentümer und Modus der übrigen neuen Projektverzeichnisse angelegt. Der zweite Bind-Mount stellt dort die separat gespeicherten Projekte bereit. Beide Hostpfade gehören zusammen in die Datensicherung. Der bestehende Pfad `workspace/project` bleibt für die bisherigen Anwendungsquellen vorgesehen. Der aktuelle Node-RED-Schritt verändert die VS-Code-Übertragungslogik nicht.

`HOME=/data` stellt ein beschreibbares, persistentes Container-Home bereit. `NODE_RED_ENABLE_PROJECTS=true` aktiviert Projects bereits beim Start. Node-RED 5.0.9 wertet die Variable im Core aus und übernimmt eine fehlende `settings.js` aus seiner eigenen Vorlage. Vorhandene Einstellungen und Credential-Schlüssel bleiben erhalten. Generierte Projektschlüssel können unter `/data/projects/.sshkeys` liegen und gehören zur geschützten Sicherung. [Settings-Erstlauf](https://github.com/node-red/node-red/blob/5.0.9/packages/node_modules/node-red/red.js#L118), [Projects-Aktivierung](https://github.com/node-red/node-red/blob/5.0.9/packages/node_modules/node-red/red.js#L199), [Projektschlüssel](https://github.com/node-red/node-red/blob/5.0.9/packages/node_modules/%40node-red/runtime/lib/storage/localfilesystem/projects/ssh/index.js#L29).

Die Restart-Regel `unless-stopped` ermöglicht den erneuten Start mit Docker nach einem Gateway-Neustart. Ein bewusst gestoppter Container bleibt nach einem Daemon-Neustart gestoppt. [Docker-Restart-Regeln](https://docs.docker.com/engine/containers/start-containers-automatically/).

## Editor über SSH erreichen

Für diesen Schritt wurde die Hostbindung `127.0.0.1:1880` ausdrücklich gewählt. Den SSH-Tunnel auf dem Entwicklungsrechner öffnen und Platzhalter durch die bekannten Zugangsdaten ersetzen

```text
ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:1880:127.0.0.1:1880 <projektkonto>@<gateway>
```

Anschließend ist der Editor auf dem Entwicklungsrechner unter `http://127.0.0.1:1880` erreichbar. Im Container lauscht Node-RED auf Port 1880 an den Containerinterfaces. Die Hostbindung begrenzt die veröffentlichte Verbindung auf die Loopbackadresse des Gateways. Wegen einer Einschränkung älterer Docker-Versionen wird ein Server vor Version 28 abgewiesen. Vorausgesetzt wird die Docker-Standardkonfiguration für NAT und Filterregeln ohne direkte Routbarkeit der Container aus fremden Netzen. Andere lokale Benutzer und Container im selben Docker-Netz können den Editor ebenfalls erreichen; dieser Laborzugang setzt einen vertrauenswürdigen Gateway-Host voraus. [Docker-Portveröffentlichung](https://docs.docker.com/engine/network/port-publishing/).

## Bestehende Installation und Prüfstand

Bei erneutem Aufruf wird ein Container nur weiterverwendet, wenn Verwaltungskennzeichnung, Image und relevante Konfiguration vollständig passen. Abweichende oder fremde Container werden als Konflikt gemeldet. Vorhandene Laufzeitdaten ohne zugeordneten verwalteten Container werden nicht automatisch übernommen. Bestehende Container, Settings, Flows und Projektdaten werden durch den Installer nicht gelöscht oder unkontrolliert ersetzt.

Johannes berichtete am 10.11.2026 erfolgreiche Verzeichnistests auf AI7020 und AI7100. Je Gerät hatten alle sechs vorgesehenen Verzeichnisse UID/GID `1000:1000` und Modus `0750`. Anlegen, Ändern und Löschen von Testdateien in drei Zielverzeichnissen gelangen ohne gemeldete Fehler. Der zunächst offene Linux-Wiederholungslauf wurde am 11.11.2026 für beide Plattformen erfolgreich berichtet.

## Lokales Testprotokoll, 10.11.2026

Geprüfter Installer: SHA-256 `be0fa73f7f61c82de5adbb3d66145c6c2f2a6f1175fbfa23805841076536226c`. Die Prüfung erfolgte unter Windows mit vorhandenem Git Bash und Python 3.11. Nach einem durch die Sandbox blockierten Start wurden die Tests außerhalb der Sandbox ausgeführt.

| Prüfung | Tatsächliches Ergebnis |
|---|---|
| Bash-Syntax und Hilfe | `bash -n`, `--help` und `-h` erfolgreich |
| Isolierter Testharness | 44 von 44 Fällen bestanden; Docker-Antworten simuliert |
| Erstanlage | ARM64-Pin, UID/GID `1000:2000`, Home mit Leerzeichen, genau zwei Mounts, ENV, Restart-Regel und Loopback-Bindung als übergebene Argumente bestätigt |
| Wiederholung | Vorhandene Runtime-/Projektdateien unverändert; kein erneuter Pull, Create oder Start bei laufendem passenden Container |
| Bestandskonflikte | Versteckte Dateien, Datei-/Linkkonflikte am Mountpunkt, abweichende Containerkonfiguration und gemeinsam verwendete Daten erkannt; kein Pull/Create/Start |
| Fehler und Wiederanlauf | Fehler bei Abfragen, Pull, Create und Start erkannt; erneuter Lauf nach Create-/Startfehler erfolgreich; vorhandene Testdaten erhalten |
| Voraussetzungen und Bereitschaft | Alte/unbekannte Docker-Version, inaktiver/nicht aktivierter Dienst und abweichende UID abgewiesen; verzögerte Bereitschaft und 30 erfolglose Versuche geprüft |
| Echte lokale HTTP-Abfragen | 3 von 3 bestanden: HTTP 200, HTTP 503 und geschlossener Port; gesetzte Proxy-Umgebung umgangen. Dafür wurde ausschließlich im Test ein kurzlebiger Loopback-Port verwendet. |

Der Harness führte den Node-RED-Funktionsteil des Installers mit isolierten Testverzeichnissen aus. Linux-Eigentümer, Modus und Privilegwechsel waren simuliert; die tatsächliche UID/GID-/Rechteprüfung der bisherigen sechs Verzeichnisse stammt aus Johannes' Hardwaretest. Das Image wurde von Codex weder heruntergeladen noch gestartet. Zum damaligen Prüfstand waren ARM64-Laufzeit, Projects-Modus, Bind-Mount-Verhalten, Schreibzugriff aus dem Container, Netzwerkabschottung und Bootstart auf beiden Gateways offen. Die Windows-Prüfung ist kein vollständiger Linux-Installerlauf.

## Korrektur der Docker-Bestandsprüfung, 11.11.2026

In der ersten Rückmeldung vom 11.11.2026 berichtete Johannes auf AI7020 einen funktionierenden Node-RED-Betrieb und erhaltenes `FLOW1` nach Containerrestart. Der zweite Installerlauf scheiterte damals beim Zugriff auf `.Config.Cmd`. Nach der folgenden Korrektur wurden die Wiederholung und unveränderte Container-ID auf beiden Plattformen erfolgreich berichtet. Der damals noch offene vollständige Gateway-Neustart ist inzwischen ebenfalls auf beiden Geräten bestanden; siehe Abschluss von Paket A unten.

Ursache: Docker 29 lässt leere optionale Image-Config-Felder wie `Cmd`, `Entrypoint` und `WorkingDir` in der Inspect-Antwort weg. Die bisherige Vorlage verlangte diese Felder unmittelbar. Die beiden Abfragen lesen jetzt die Pflicht-ID und die gesamte `Config` als JSON. Der gemeinsame Vergleich behandelt fehlende, `null` und leere Standardwerte gleich; nichtleere Startbefehle, deren Reihenfolge, Arbeitsverzeichnis und Image-ID werden weiterhin strikt verglichen. Ungültige Metadaten führen zum Abbruch. [Offizielle Docker-Dokumentation](https://docs.docker.com/engine/deprecated/#emptynil-fields-in-image-config-from-inspect-api).

Geprüfter korrigierter Installer: SHA-256 `c9b0691de4c35d950de713ad1cfabfdb45cbad6fbb2d94f7627b78dfc8322b3c`.

- Bash-Syntaxprüfung erfolgreich.
- 14 gezielte Fälle unter Git Bash/Python mit simulierten Docker- und HTTP-Antworten bestanden: fehlendes `Cmd`, leere optionale Felder, Sonderzeichen, echte Konfigurationsabweichungen sowie Abfrage- und JSON-Fehler. Die vorhandenen Prüfungen für Benutzer, Mounts und Portbindung wurden ebenfalls auf Abweisung geprüft.
- Dabei ausschließlich lesende Docker-Aufrufe zugelassen; bestehende Runtime-/Projekt-Testdateien und Verzeichnisse blieben unverändert. Keine Anlage oder Änderung eines Containers, kein Start, Restart oder Pull.
- Der unverändert extrahierte JSON-Vergleich bestand zusätzlich 829 Fixture-Fälle, darunter 729 Kombinationen fehlender/`null`/leerer Werte, echte Unterschiede, Sonderzeichen sowie ungültige Typen und Metadaten.

Die früheren Stubs lieferten fertige Vergleichsstrings und bildeten die ausgelassenen Config-Felder nicht ab. Die neuen Prüfungen führen den tatsächlichen JSON-Vergleich mit diesen Feldausprägungen aus. Docker-API, Linux-Rechte und das echte Gateway waren in dieser lokalen Prüfung simuliert. Die anschließenden erfolgreichen Hardwaremeldungen beider Plattformen sind im [Projektstatus](../../../docs/PROJEKTSTATUS.md#gateway-provisionierung) dokumentiert. Der Rückfall der Korrektur betrifft nur die Skriptkopie; Containerkonfiguration und beide Datenverzeichnisse bleiben erhalten.

## Paket A abgeschlossen – Hardwareabnahme vom 11.11.2026

Johannes hat den vollständigen Linux-Neustart auf AI7020-8 (Orin Nano) und AI7100-3 (Orin NX) erfolgreich durchgeführt. Docker und Node-RED starten automatisch; `mynodered` läuft ohne manuellen Start. `FLOW1`, `flows.json` und die übrigen Projektdateien bleiben erhalten, die Dateieigentümer weiterhin `friedrich`. Node-RED funktioniert nach dem Neustart auf beiden Plattformen. Für AI7020 ist zusätzlich ausdrücklich der Docker-Zustand `healthy` gemeldet; für AI7100 wurde kein eigener Health-Status übermittelt.

Die bisherigen erfolgreichen Erstinstallations-, Wiederholungs- und Containerneustarttests bleiben gültig. **Paket A ist hardwareseitig abgenommen und abgeschlossen.** Diese Ergebnisse stammen aus Johannes' Rückmeldung; Codex hat keine Gatewaytests ausgeführt. Die Abnahme gilt für Paket A, nicht für den noch fehlenden Gesamtumfang des Laborprofils.

Paket B – BSP-Schutz und Hostvoraussetzungen – beginnt mit der unten beschriebenen B1-Diagnose. Offene technische Einzelentscheidungen bleiben gesondert freizugeben. Der aktuelle Nachweis und nächste Schritt stehen im [Projektstatus](../../../docs/PROJEKTSTATUS.md#gateway-provisionierung), der technische Rahmen im [Installationskonzept](INSTALLATIONSKONZEPT.md). Installer-Funktionen wurden für diesen Abschluss nicht geändert.

## B1: Lesendes BSP-Inventar

Die Originalprotokolle beider Gateways vom 11.11.2026 sind inzwischen in [B1_AUSWERTUNG.md](B1_AUSWERTUNG.md) ausgewertet. Der folgende Abschnitt beschreibt den dafür verwendeten Sammlerstand; B1 ist keine Freigabe der B2-Schutzmenge.

[`b1_inventory.sh`](b1_inventory.sh) fasst die fünf vorbereiteten B1-Prüfabschnitte zusammen. Es liest System-/Paketdaten, bereinigte APT-Quellen und lokale Kandidaten, BSP-Artefakte, Paketbeziehungen/Control-Metadaten sowie bekannte automatische Updatewege. Die einzige gezielte Dateischreibaktion ist eine neue Protokolldatei im tatsächlichen Home des aufrufenden Benutzers. `install.sh` wird nicht aufgerufen oder verändert.

Aus der Repository-Wurzel **als normaler Projektbenutzer ohne vorangestelltes sudo** ausführen:

Auf AI7020-8:

```bash
bash platform/gateway/provisioning/b1_inventory.sh AI7020-8
```

Auf AI7100-3:

```bash
bash platform/gateway/provisioning/b1_inventory.sh AI7100-3
```

Die Kennung ist ein vom Benutzer gewähltes Protokolllabel und kein automatischer Modellnachweis. `-h`/`--help` zeigt den Aufruf. Linux und vorhandenes `/usr/bin/python3` sind erforderlich; das Skript installiert keine fehlenden Programme. Ein Start als root wird vor der Protokollanlage abgewiesen.

Das Skript fragt gegebenenfalls über das Terminal nach dem sudo-Passwort und verwendet erhöhte Rechte ausschließlich für Leseabfragen. Ohne sudo oder bei fehlgeschlagener Anmeldung wird soweit möglich ohne erhöhte Leserechte erfasst und das Protokoll als unvollständig markiert. Der genaue Pfad wird auf der Konsole ausgegeben, beispielsweise:

```text
<tatsächliches Home>/b1_inventory_AI7020-8_<UTC-Zeit>_<Zufall>.txt
```

Die Datei gehört dem normalen Benutzer und wird exklusiv mit Modus `0600` neu angelegt. Weder vorhandene Dateien noch Symlinks werden überschrieben. Ein erneuter Aufruf erzeugt eine neue Datei. Es werden keine Besitzer oder Rechte vorhandener Dateien geändert.

### Umfang und Auswertung

- Ein Dateikatalog enthält Boot-/DTB-/Initrd-Dateien, Module des laufenden Releases und gezielte Boot-/Initrd-Helfer. Jeder Dateipfad erscheint einmal; gleiche bereits gelesene Inodes werden nicht erneut gehasht. SHA-256 und vorhandene Paket-/Conffile-MD5 werden gemeinsam bewertet. Das zeilenweise Modulmanifest plus Summenhash ist bewusst enthalten, um auch andere Eigenmodule als LAN743X vergleichen zu können.
- Die Paketübersicht beschränkt sich auf BSP/NVIDIA, Updater und gefundene Artefaktbesitzer. Es gibt keine zusätzlichen vollständigen `dpkg -L`-/`dpkg --verify`-Dumps. Maintainer-Skripte werden ausschließlich gehasht und auf feste Hinweiswörter geprüft, nicht ausgeführt oder als Volltext protokolliert.
- APT-Abfragen verwenden ausschließlich vorhandene lokale Listen; persistente Binärcaches sind deaktiviert. Kein `apt update`, keine Installation, kein Upgrade und keine Änderung von Holds, Quellen oder Konfigurationen.
- Private Repository-URIs, Proxy-/Zugangsdaten, Job-/Hooktexte, Bootargumente und rohe Fehlerausgaben werden nicht protokolliert. Unbekannte Quellen und Pins bleiben lokal gezielt zu prüfen. Es werden weder Hostname/MAC/Seriennummern noch vollständiger Live-Device-Tree oder EFI-Variablen abgefragt.
- `unowned_in_dpkg` beweist keine FA-Eigenentwicklung; `differs_from_package_metadata` kann eine beabsichtigte Anpassung sein. Fehlende Metadaten und Lesefehler bleiben erkennbar. Ein Dateihash beweist nicht allein, dass genau diese Datei gebootet wurde. Die Daten ersetzen keine freigegebene FA-Artefaktbaseline.

Exit `0` und `ENDE: OK` bedeuten, dass die vorgesehenen Abfragen ohne erkannte Erfassungsfehler abgeschlossen wurden. Das ist keine BSP-/Schutzfreigabe. Exit `1` bedeutet ein vorhandenes, unvollständiges Protokoll; `OFFEN`-Meldungen und nicht erfasste Bereiche prüfen, nichts automatisch reparieren. Exit `2` bezeichnet einen ungültigen Aufruf, eine fehlende Grundvoraussetzung oder eine nicht anlegbare Protokolldatei. Nach Abbruch kann ein Teilprotokoll ohne vollständigen Abschluss verbleiben.

### Lokale Prüfung vom 11.11.2026

Geprüfter Skriptstand: SHA-256 `ec3042cc48f2192bd8a8e12577eb95dda624b83d09cf65702b28cd4b381c8847`.

- Bash-Syntaxprüfung (`bash -n`) bestanden; die eingebetteten Python-Teile wurden im Test tatsächlich ausgeführt.
- 41 von 41 simulierten Fällen unter Windows/Python bestanden: beide Gerätelabels, Wiederholung mit neuer Datei, Root-/Setuid-Abweisung, Logkonflikte und Schreibfehler, fehlendes/abgewiesenes sudo, fehlende Programme, Zeitlimits und Lesefehler, veränderte Paket-/APT-Momentaufnahmen, Usrmerge, Symlinks, FIFO-Abweisung, Paket-/Conffile-Prüfsummen und Bootslot-Auswertung.
- Testdaten mit privaten Repository-URIs, Zugangsdaten, Proxy-/Hook-/Audittexten und Gerätekennungen gelangten nicht in die Protokolle. Erfassungsfehler ergaben den vorgesehenen unvollständigen Status.
- Statischer Abschlussreview ohne weitere blockierende Befunde; `install.sh` ist unverändert (SHA-256 `c9b0691de4c35d950de713ad1cfabfdb45cbad6fbb2d94f7627b78dfc8322b3c`).

Linux-Dateisystem, Programme und Privilegwechsel waren im Python-Test simuliert. Echte POSIX-Eigentümer/Rechte, sudo-Dialog, Laufzeit, Umfang und konkrete NVIDIA-/APT-Antworten sind damit nicht nachgewiesen. Es gab keine Ausführung auf einem Gateway. Das Skript verändert keine bestehende Konfiguration; ein Rückfall betrifft nur die Skriptkopie, erzeugte Protokolle bleiben erhalten.

### Kurze Hardware-Testanleitung

Johannes führt den jeweiligen Aufruf auf beiden Gateways aus. Danach den ausgegebenen Protokollpfad öffnen und prüfen: richtiges Gerätelabel, Datum/Skriptprüfsumme, fünf Abschnitte und Abschlussmarker. Mit `stat -c '%U %a %s %n' "/ausgegebener/Protokollpfad.txt"` (Pfad ersetzen) Eigentümer des Projektkontos, Modus `600` und eine gefüllte Datei bestätigen. Bei einem zweiten Lauf muss eine weitere Datei entstehen und die erste unverändert bleiben.

Beide Protokolle anschließend für den Vergleich mit der jeweiligen BSP-Referenz bereitstellen. Fehlende Programme oder Lesefehler zunächst als fehlende Nachweise behandeln. Vor B2 werden daraus die konkreten Schutzpakete und erlaubten Änderungen gesondert festgelegt; das Skript setzt selbst keine Schutzmechanismen um. Codex führt diese Hardwareprüfung nicht aus.

## B2: 15 NVIDIA-Holds freigegeben

<a id="b2-schutzprüfung-vorbereitet-aktivierung-gesperrt"></a>

`install.sh` enthält zwei abgegrenzte B2-Aufrufe. Beide enden vor dem Laborablauf; `labor` ruft keine B2-Funktion auf. Es gibt weiterhin **keinen echten APT-Installationspfad**. Paket-A-Funktionen und Laborablauf sind gegenüber SHA-256 `c9b0691de4c35d950de713ad1cfabfdb45cbad6fbb2d94f7627b78dfc8322b3c` bytegleich.

```bash
# Lesende Simulation auf beiden Gateways aus der Repo-Wurzel:
sudo bash platform/gateway/provisioning/install.sh bsp-plan hello
sudo bash platform/gateway/provisioning/install.sh bsp-plan nvidia-l4t-kernel
```

Der erste Aufruf dient nur als lesender Beispielplan, sofern `hello` in den vorhandenen lokalen APT-Listen einen Kandidaten hat. Exit `0` heißt **strukturell ausgewertete Simulation, keine Installationsfreigabe**. Der NVIDIA-Aufruf muss mit Exit `1` blockieren. Ungültige Argumente ergeben Exit `2`; fehlende Basisdaten, APT-Fehler oder unbekannte Planformate Exit `1`. Keine dieser Prüfungen richtet Container oder Verzeichnisse ein.

Die Liste der 15 installierten `nvidia-l4t-*`-Pakete aus [B1 Abschnitt 6](B1_AUSWERTUNG.md#6-b2-empfehlung-zur-gemeinsamen-entscheidung--vorschlag) wurde am **11.11.2026 als erste BSP-Schutzstufe freigegeben**. Johannes berichtet abgeschlossene B2-Hardwareprüfungen und Nachcheck auf beiden Geräten sowie bestätigte Paketversionen, Kandidaten und Abhängigkeiten. Die Liste enthält direkte Artefaktpakete plus gekoppelte Tools/Firmware/Init-/Quellen-/Konfigurations- und Headerpakete; die B1-Versionen werden weiterhin exakt geprüft. Sie ist kein vollständiger Dateischutz. Die unveränderte Plansperre ist breiter: sämtliche `nvidia-l4t*`-/JetPack-Aktionen und bekannte Kernel-/Boot-/Initramfs-Helfer werden auch als transitive Abhängigkeit blockiert. `Inst`, `Conf`, `Remv` und `Purg` werden geprüft; Aktionen und Zusammenfassung müssen zusammenpassen. Reinstallation, Downgrade und andere nicht unterstützte Ausgabeformen werden geschlossen abgewiesen.

Der Plan verwendet vorhandene Quellen/Pins und lokale Paketlisten, `--simulate --no-remove --no-upgrade --no-install-recommends` und deaktivierte Binärcaches. Keine Netzaktualisierung. `--no-upgrade` betrifft nur bereits installierte Kommandozeilenpakete, weshalb die gesamte Auflösung zusätzlich geprüft wird. Relevante APT-/Dpkg-/JSON-Hooklisten werden mittels nativer `#clear`-Konfiguration ausschließlich für diesen Prozess entfernt; keine Systemkonfiguration wird verändert. So werden auch APT-Hooks vor dem eigentlichen Simulationszweig vermieden. Ein leeres `-o Hook=` würde die Liste nicht löschen. [Jammy apt-get](https://manpages.ubuntu.com/manpages/jammy/man8/apt-get.8.html), [apt.conf](https://manpages.ubuntu.com/manpages/jammy/man5/apt.conf.5.html), [APT-2.4-Serienquellstand](https://github.com/Debian/apt/blob/2.4.8/apt-private/private-install.cc)

**Grenze und sichere Sperre:** Simulationen reservieren keine APT-/dpkg-Sperre. Kandidatenskripte, spätere Trigger und parallele Änderungen sind damit nicht bewiesen ungefährlich; die erweiterte Namenssperre ist kein vollständiger Skriptbeweis. Reale Paketinstallationen werden in diesem Stand überhaupt nicht ausgeführt. Vor der ersten realen APT-Installation bleiben insbesondere die Inhalte der APT-Pins und die zusätzliche Quelle zu klären; außerdem sind Änderungsplan, Skripte/Trigger und Rückfall zu entscheiden. Die Hold-Freigabe ersetzt dies nicht. NVIDIA beschreibt Kerneltrigger und DTB-Postinstallation mit Änderungen an Bootartefakten. [NVIDIA R36.4](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/SoftwarePackagesAndTheUpdateMechanism.html#package-dependencies)

Der Hold-Schritt wurde mit `readonly BSP_HOLDS_APPROVED=yes` freigeschaltet. **Bei dieser historischen B2-Freigabe war die einzige Codeänderung gegenüber dem vorbereiteten Stand `no` → `yes`.** Die 15 Pakete, Versionsprüfungen, übrige B2-Logik und der Labor-/Node-RED-Ablauf sind unverändert. Der bestehende Hilfetext „noch gesperrt“ und die Formulierung „vorgeschlagenen Holds“ bleiben bei dieser ausdrücklich auf die Konstante begrenzten Änderung unverändert; maßgeblich ist die Freigabekonstante. Der explizite Hold-Aufruf ergänzt nur fehlende Holds, erhält vorhandene auch außerhalb der 15er-Liste und prüft die Vereinigungsmenge. Eine Wiederholung mit vollständigen Holds schreibt nichts. Bei Teilfehlern keine automatische Rücknahme, kein pauschales `unhold`. Holds ersetzen keine Dateisperre. [apt-mark](https://manpages.ubuntu.com/manpages/jammy/man8/apt-mark.8.html)

Die Standardlösung bleibt `apt-mark` plus native APT-Simulation. Freigegeben ist die unveränderte 15er-Liste; zusätzliche Pins werden nicht geschrieben.

### Gebündelter lesender Nachcheck (durch Johannes durchgeführt)

Johannes berichtet die Durchführung auf beiden Gateways am 11.11.2026. Der Block bleibt als Referenz erhalten und zeigt nur Metadaten und lokale Kontrollpfade; keine Quell-URIs, Hooktexte oder Zugangsdaten:

```bash
sudo bash <<'B2'
set -euo pipefail
export LC_ALL=C
pkgs=(nvidia-l4t-{kernel,kernel-dtbs,kernel-oot-modules,display-kernel,initrd,bootloader,core,tools,init,configs,firmware,xusb-firmware,apt-source,kernel-headers,kernel-oot-headers})
p=/etc/nv_boot_control.conf
if [[ -f "$p" && ! -L "$p" && $(readlink -f -- "$p") == "$p" ]]; then
    stat -c 'Pfad=%n Modus=%a UID=%u GID=%g Bytes=%s' -- "$p"
    sha256sum -- "$p"
    dpkg-query -S -- "$p" 2>/dev/null || printf 'OFFEN: Dateibesitzer nicht ermittelt\n'
else printf 'OFFEN: nv_boot_control.conf fehlt oder hat abweichenden Typ/Zielpfad\n'; fi
apt-config shell PREF Dir::Etc::preferences/f PREFD Dir::Etc::preferencesparts/d \
    SOURCES Dir::Etc::sourcelist/f SOURCEPARTS Dir::Etc::sourceparts/d 2>/dev/null
apt-cache -o Dir::Cache::pkgcache= -o Dir::Cache::srcpkgcache= --no-all-versions show -- "${pkgs[@]}" 2>/dev/null |
    awk '/^(Package|Version|Pre-Depends|Depends|Breaks|Conflicts|Replaces|Provides):/ {print}'
for p in "${pkgs[@]}"; do
    for c in preinst postinst prerm postrm triggers; do
        dpkg-query --control-path "$p" "$c" 2>/dev/null || :
    done
done
B2
```

Fehlende Ausgabe ist kein Freigabenachweis. An den ermittelten Pfaden **nur lokal** die drei Pins, Quelle 13 und relevanten Control-/Triggerdateien ansehen. Zurückmelden: wirksame Paketmuster/Versions- oder Releaseauswahl/Priorität; Herkunftsklasse, Aktivierung und Vertrauensregel der Quelle; konkrete Bedingungen/Aufrufketten zu Initrd, DTB und Bootloader. Keine vollständigen privaten URLs, Origins, Tokens oder Rohskripte teilen. Die Kandidatenabhängigkeiten oben stammen aus dem Cache; Kandidatenskripte werden damit nicht gelesen. Ungeklärte Kandidaten bleiben für reale Eingriffe gesperrt. [Pinregeln](https://manpages.ubuntu.com/manpages/jammy/man5/apt_preferences.5.html)

### Lokale Prüfung des B2-Vorbereitungsstands

Geprüfter Installer: SHA-256 `8bdaa21c5013e6e2c241a50b0bf34e44de4aa1b88a5a65dcccc2cf302403dc15`, Ausgangsfassung oben `c9b0691d…`. 81 isolierte Prüfungen bestanden: Python-Syntax und 41 Planfälle, 34 Bash-Funktionsfälle, vier echte CLI-Exitfälle und eine vollständige Bash-Syntaxprüfung. Darunter zulässige Neuinstallation/Leerplan, direkte und transitive NVIDIA-Änderungen, Multiarch, bekannte Hookpakete, Conf-only, Entfernen/Purge, fehlerhafte Pläne/Zählungen, manipulierte Argumente, Basis-/Abfragefehler und die feste Hold-Sperre. Eine ausschließlich temporäre Testkopie mit freigegebenem Gate bestätigte Hold-Ergänzung, unveränderte zusätzliche Holds, Wiederholung ohne Schreibaufruf sowie erkennbare Teil-/Prüffehler.

Bash lief unter Git Bash, der Produktionsparser unter Windows/Python; System-/APT-/dpkg-Antworten, EUID für Basistests und Holdzustand waren simuliert. Der Konfigurations-FD und die festen Simulationsargumente wurden an einem Stub geprüft. **Kein echter APT-2.4.15-Lauf**, keine tatsächliche Hook-Unterdrückung auf Linux, kein Lock-/Parallelitätsnachweis und keine Aussage über reale Kandidatenskripte/Bootfähigkeit daraus. Paket-A-Funktionen und Laborbody wurden zusätzlich byteweise gegen die Ausgangsfassung verglichen. Keine Docker-/Gatewayaktionen, Installationen, realen Holds oder Git-Schreibaktionen durch Codex.

### Hold-Freigabestand und Hardwaretest

Historischer B2-Hold-Freigabestand, Installer-SHA-256: `6136b46496a5c68efc1ebf3a1f60838e004643ec790a592a5e2f59834e6098c6`. Die inverse Ersetzung der Freigabekonstante ergibt bytegenau den Vorbereitungsstand `8bdaa21c…`.

Am 11.11.2026 erneut **10/10 lokale Prüfungen bestanden**: neun Hold-Szenarien plus `bash -n` auf der bytegleichen Skriptkopie. Geprüft wurden Erstaktivierung und Wiederholung, fremde Holds, vollständige und gemischte `:arm64`-Holds, Fehler vor/nach der Hold-Abfrage, Teilmarkierung, Verlust eines bestehenden Holds und abgewiesene Baseline. Der originale Hold-Funktionsauszug und die freigegebene Konstante wurden unter Git Bash ausgeführt; Baseline und `apt-mark` waren Stubs, der Holdzustand ausschließlich temporäre Testdaten. Keine realen Paketmarkierungen oder Gatewayaktionen; das ist keine Linux-Hardwareabnahme.

**Erst nach Prüfung durch Johannes auf AI7020-8 und AI7100-3**, aus der Repository-Wurzel:

```bash
apt-mark showhold
sudo bash platform/gateway/provisioning/install.sh bsp-holds
echo "Exit: $?"
apt-mark showhold
sudo bash platform/gateway/provisioning/install.sh bsp-holds
echo "Exit: $?"
apt-mark showhold
```

Erwartet: beide Läufe Exit `0` und `B2: alle 15 vorgeschlagenen Holds bestätigt, frühere Holds erhalten.` Nach dem ersten Lauf sind die 15 NVIDIA-Pakete plus alle vorher vorhandenen Holds gesetzt; ohne frühere Holds sind es genau 15. Beim zweiten Lauf bleibt diese Menge unverändert und es erfolgt kein weiterer `apt-mark hold`-Schreibaufruf. Kein Labor-/Containerlauf und keine Paketinstallation. Diese historische Anleitung beschrieb den damals noch ausstehenden Hardwarelauf; Johannes' spätere B2-Rückmeldungen stehen oben beim Nachcheck. Ein Rückfall der Skriptkopie entfernt bereits gesetzte Holds nicht; bei Problemen keine pauschale Aufhebung bestehender Holds.

Der bisherige `AI7XX0.sh`-Stand liegt als [historische Referenz](../../../references/legacy-gateway/README.md) vor.
