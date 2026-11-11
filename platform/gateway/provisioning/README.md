# Host-Provisionierung

Zielumfang, Profile, offene Entscheidungen und Entwicklungspakete stehen im [Installationskonzept](INSTALLATIONSKONZEPT.md). Die übergeordnete Architektur und der Fahrplan A–F sind freigegeben; Vorschlagsdetails werden im jeweiligen Paket gesondert festgelegt und freigegeben. Diese README beschreibt die verfügbare Implementierung; tatsächliche Hardwaremeldungen stehen im [Projektstatus](../../../docs/PROJEKTSTATUS.md#gateway-provisionierung).

[`install.sh`](install.sh) prüft die Laborbasis, legt fehlende Projekt- und Laufzeitverzeichnisse unter dem ermittelten Benutzer-Home an und richtet den Node-RED-Container ein. Neue Verzeichnisse erhalten die UID und primäre GID des Projektkontos sowie den Modus `0750`. Bei `sudo` läuft die Verzeichnisanlage mit den Rechten des Projektkontos über `setpriv`.

Der Installer prüft vorhandene Pfade auf Typ, Eigentümer und Zugriff, bevor er Verzeichnisse anlegt. Konflikte werden mit dem betroffenen Pfad gemeldet. Die Hardwareergebnisse und der jeweilige Prüfstand stehen im [technischen Projektstand](../../../docs/PROJEKTSTATUS.md#gateway-provisionierung).

Aufruf aus der Repository-Wurzel auf dem Gateway

```bash
sudo bash platform/gateway/provisioning/install.sh labor
```

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

In der ersten Rückmeldung vom 11.11.2026 berichtete Johannes auf AI7020 einen funktionierenden Node-RED-Betrieb und erhaltenes `FLOW1` nach Containerrestart. Der zweite Installerlauf scheiterte damals beim Zugriff auf `.Config.Cmd`. Nach der folgenden Korrektur wurden die Wiederholung und unveränderte Container-ID auf beiden Plattformen erfolgreich berichtet; der vollständige Gateway-Neustart bleibt offen.

Ursache: Docker 29 lässt leere optionale Image-Config-Felder wie `Cmd`, `Entrypoint` und `WorkingDir` in der Inspect-Antwort weg. Die bisherige Vorlage verlangte diese Felder unmittelbar. Die beiden Abfragen lesen jetzt die Pflicht-ID und die gesamte `Config` als JSON. Der gemeinsame Vergleich behandelt fehlende, `null` und leere Standardwerte gleich; nichtleere Startbefehle, deren Reihenfolge, Arbeitsverzeichnis und Image-ID werden weiterhin strikt verglichen. Ungültige Metadaten führen zum Abbruch. [Offizielle Docker-Dokumentation](https://docs.docker.com/engine/deprecated/#emptynil-fields-in-image-config-from-inspect-api).

Geprüfter korrigierter Installer: SHA-256 `c9b0691de4c35d950de713ad1cfabfdb45cbad6fbb2d94f7627b78dfc8322b3c`.

- Bash-Syntaxprüfung erfolgreich.
- 14 gezielte Fälle unter Git Bash/Python mit simulierten Docker- und HTTP-Antworten bestanden: fehlendes `Cmd`, leere optionale Felder, Sonderzeichen, echte Konfigurationsabweichungen sowie Abfrage- und JSON-Fehler. Die vorhandenen Prüfungen für Benutzer, Mounts und Portbindung wurden ebenfalls auf Abweisung geprüft.
- Dabei ausschließlich lesende Docker-Aufrufe zugelassen; bestehende Runtime-/Projekt-Testdateien und Verzeichnisse blieben unverändert. Keine Anlage oder Änderung eines Containers, kein Start, Restart oder Pull.
- Der unverändert extrahierte JSON-Vergleich bestand zusätzlich 829 Fixture-Fälle, darunter 729 Kombinationen fehlender/`null`/leerer Werte, echte Unterschiede, Sonderzeichen sowie ungültige Typen und Metadaten.

Die früheren Stubs lieferten fertige Vergleichsstrings und bildeten die ausgelassenen Config-Felder nicht ab. Die neuen Prüfungen führen den tatsächlichen JSON-Vergleich mit diesen Feldausprägungen aus. Docker-API, Linux-Rechte und das echte Gateway waren in dieser lokalen Prüfung simuliert. Die anschließenden erfolgreichen Hardwaremeldungen beider Plattformen sind im [Projektstatus](../../../docs/PROJEKTSTATUS.md#gateway-provisionierung) dokumentiert. Der Rückfall der Korrektur betrifft nur die Skriptkopie; Containerkonfiguration und beide Datenverzeichnisse bleiben erhalten.

Aktuell verbleibt für Paket A die vollständige Gateway-Neustartabnahme auf beiden Plattformen. Der jeweils nächste Schritt wird im [Projektstatus](../../../docs/PROJEKTSTATUS.md#gateway-provisionierung) geführt; der weitere technische Rahmen steht ausschließlich im [Installationskonzept](INSTALLATIONSKONZEPT.md).

Der bisherige `AI7XX0.sh`-Stand liegt als [historische Referenz](../../../references/legacy-gateway/README.md) vor.
