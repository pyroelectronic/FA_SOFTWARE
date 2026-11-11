# Gateway-Installationskonzept und Entwicklungsfahrplan

**Stand: 11.11.2026 · Status: Übergeordnete Architektur und Entwicklungsfahrplan A–F durch Johannes freigegeben.**

Bereits beschlossene Anforderungen gelten als Vorgabe. Die Freigabe des übergeordneten Installationskonzepts umfasst Architektur und Entwicklungsfahrplan A–F; sie gibt die mit **Vorschlag** bezeichneten technischen Detailentscheidungen nicht automatisch frei. Insbesondere BSP-Schutzpakete, konkrete Netzwerkparameter, MQTT-Listener, Komponentenversionen und noch nicht implementierte CLI-Funktionen bleiben offen und werden vor ihrer Umsetzung im jeweiligen Arbeitspaket gesondert festgelegt und freigegeben. Dieses Dokument erteilt keine pauschale Installations-, Netzwerk-, BSP- oder Migrationsfreigabe. Im zugehörigen Auftrag werden ausschließlich diese Dokumentationspräzisierungen vorgenommen.

## 1. Auftrag, Quellen und belastbarer Ausgangsstand

### 1.1 Geltungsbereich

Ein zentraler Installer bereitet einen bereits mit dem Friedrich-BSP geflashten und betriebsfähigen AI7020 oder AI7100 für seinen vorgesehenen Einsatz vor. BSP-Entwicklung, Kernel, Device Trees, Bootloader und Hardwaretreiber verbleiben im eigenen BSP-Entwicklungsrepository. Die hiesigen BSP-Dateien sind Referenzmaterial. Geflasht wird vor der Softwareinstallation.

Die fertige Lösung prüft die Plattform, schützt den vorhandenen BSP-Stand, richtet erforderliche Hostvoraussetzungen und Projektpfade ein und installiert ausschließlich den ausgewählten Umfang. Sie erhält bestehende Projekte, erkennt Konflikte und unterstützt einen kontrollierten Wiederholungslauf. Ein Erfolg wird anhand der Anforderungen des gewählten Profils beurteilt.

Nicht Teil dieses Installerplans sind die Implementierung oder Vorbereitung von IgH/EtherCAT, ein Universal-SDK, eine neue OS-/JetPack-Generation, eine neue Extension, eine eigene Orchestrierung, OTA oder umfangreiche Benutzerverwaltung. Diese Abgrenzung ändert nicht das übergeordnete spätere IgH-/EC100-Integrationsziel.

### 1.2 Quellen und Autorität

Gelesen und berücksichtigt wurden:

- [AGENTS.md](../../../AGENTS.md), [ARCHITECTURE.md](../../../ARCHITECTURE.md), [Repository-README](../../../README.md), [Bedienungsanleitung](README.md), [Projektstatus](../../../docs/PROJEKTSTATUS.md), [Referenzstandregister](../../../docs/BASELINE_REGISTER.md), [Auftrag 01](../../../codex/01_GATEWAY_BESTAND.md).
- [Historischer Installer](../../../references/legacy-gateway/AI7XX0_REFERENCE_REDACTED.txt), dessen [Einordnung](../../../references/legacy-gateway/README.md), [Changelog](../../../references/legacy-gateway/CHANGELOG_REFERENCE.md) und [Torch-Test](../../../references/legacy-gateway/torchtest_REFERENCE.py). Die Lesekopie ist sanitisiert und nicht ausführbar. Ihre SHA-256 lautet `7f8d0c388cff3d7a4d061d30c5d003c84baaadd4a369f40b7ad4a2bc76c5a96d`.
- [Quelleninventar](../../../docs/SOURCE_INVENTORY.md), [offene Eingaben](../../../docs/INPUTS_OFFEN.md), [AI7020-Quellenkorrektur](../../../docs/AI7020_QUELLENKORREKTUR.md) und [Extension-Befunde](../../../docs/EXTENSION_BEFUNDE.md). Ein eigenständiger vollständiger Gateway-Bestandsbericht ist im aktuellen Repository nicht vorhanden. Auftrag und Berichtsvorlage sind keine Analyseberichte; vorliegende Teilbefunde und die dokumentierten Hardwaremeldungen werden verwendet.
- Das frühere Nutzerbriefing „Friedrich Automation Gateway Software: Bestandsanalyse und Weiterentwicklung“ und der aktuelle Auftrag „Verbindliches Gateway-Installationskonzept und Entwicklungsfahrplan“, beide als Anhänge gelesen. Die SHA-256 des aktuellen Auftrags lautet `a795e1597171949621394da8d171ae9e6edab8a6c4f782ae33f53e6496b79027`, die des früheren Briefings `fec9dcca6cc3ed6f24b783f59cf2c4f5404aa8a5b17aca0c005944272c972132`. Die früheren Nur-Lese-Arbeitsgrenzen sind historischer Auftragsumfang; der aktuelle Auftrag erlaubt diese Dokumentation.
- Am 11.11.2026 lesend geprüft: [CURRENT_STATE.md](https://github.com/pyroelectronic/FRIEDRICH-AUTOMATION/blob/main/CURRENT_STATE.md), Blob `14d8beec10ca29840ae3db9be69394f85791c595`, und [DECISIONS.md](https://github.com/pyroelectronic/FRIEDRICH-AUTOMATION/blob/main/DECISIONS.md), Blob `ba3ecea88f82c7b0e41433b0a1ce7a7589021156`, sowie [Issue #12](https://github.com/pyroelectronic/FRIEDRICH-AUTOMATION/issues/12), zuletzt aktualisiert am 05.11.2026. D-004/D-006/D-008/D-010/D-011 bleiben maßgeblich: IgH später, Bausteine aus funktionierenden Anwendungen, optionale Runtimes und zentrale Projektsteuerung. Der Installerfortschritt erfüllt nicht automatisch die IgH-/PDO-Abnahmekriterien von Issue #12. Es werden keine neuen Issues oder parallelen Aufgabenregister angelegt.

**Quellengrenzen:** Der unveränderte Originalinstaller `AI7XX0.sh`, die darin referenzierten DEB-/Wheel-Dateien und ein vollständiger reproduzierbarer Extension-Quell-/Buildstand liegen im Arbeitsrepository nicht vor. Das Inventar nennt Originalhashes; sie ersetzen keine Inhaltsprüfung. Vorhandene BSP-Anleitungen und Teilquellen belegen keinen aktuellen vollständigen Flash-/Release-Baum. Die Version 36.4.3 im alten Archivnamen bleibt eine historische Quellenangabe, keine Festlegung für die heutige R36.4.0-Basis. Der vorliegende `CHANGELOG_REFERENCE.md` nennt InfluxDB-Schritte, die in der gelesenen Installerkopie nicht enthalten sind; daraus folgt kein zusätzlicher Installationsauftrag.

### 1.3 Implementierung und Hardwaremeldungen

Die gelesene Entwicklungsfassung von [install.sh](install.sh) hat SHA-256 `c9b0691de4c35d950de713ad1cfabfdb45cbad6fbb2d94f7627b78dfc8322b3c`. Git-Ausgangspunkt des Arbeitsverzeichnisses ist `416873a3fec135e066b567c799933548665eaf5f`; bereits vorhandene uncommittete Änderungen sind dadurch nicht Teil einer neuen Releasefreigabe. Die Hardwarekopien wurden ohne eigene Skriptprüfsummen gemeldet.

| Bereich | Verifizierter oder berichteter Stand | Grenze |
|---|---|---|
| Hardware | AI7020-8: Orin Nano; AI7100-3: Orin NX; eigene FA-Carrier mit zwei Ethernetports | Physische Buchsenzuordnung offen |
| Hostbasis | Ubuntu 22.04/ARM64, L4T R36.4.0, Kernel `5.15.148-tegra`, Docker 29.1.3 laut Hardwaremeldungen | JetPack 6.1 als Projektbasis; kein Nachweis aller installierten CUDA-/NVIDIA-Pakete |
| Modellkennung | Beide Geräte melden den generischen NX-Engineering-Device-Tree-Text | Keine zuverlässige FA-Modellidentifikation allein daraus; kein BSP-Fix im Installer |
| Konto und Pfade | `friedrich`, UID/GID `1000:1000`, sechs Projektverzeichnisse mit `0750`; Schreib-/Änderungs-/Löschtests auf beiden Geräten berichtet | Andere Container-UIDs sind nicht durch diesen Hardwaretest abgedeckt |
| Node-RED | 5.0.9, ARM64-Digest, Projects, SSH-Tunnel, `FLOW1`, korrekte Projektdateien, Containerrestart und Wiederholung mit gleicher Container-ID auf beiden Geräten berichtet; vollständiger Gateway-Neustart am 11.11.2026 bestanden, Autostart/Persistenz/Eigentümer bestätigt | `healthy` zusätzlich nur für AI7020 ausdrücklich gemeldet; kein pauschaler Health-Status für AI7100 abgeleitet |
| Zusammenfassung | Auf beiden Geräten `8 vorhanden / 1 fehlt / 1 offen / 0 Probleme` | Mosquitto fehlt erwartungsgemäß; der einzelne OFFEN-Posten wird keinem unberichteten Test zugeordnet |
| Paketverwaltung | dpkg-Audit unauffällig; Holds auf beiden frisch geflashten Geräten leer berichtet | Noch kein implementierter Schutz für künftige APT-Installationen |

Die lokale Syntax-/Simulationsprüfung und die von Johannes berichteten Hardwaretests sind im [Projektstatus](../../../docs/PROJEKTSTATUS.md) und in der [Bedienungsanleitung](README.md) getrennt dokumentiert. Paket A ist nach Johannes' erfolgreicher Neustartabnahme vom 11.11.2026 auf beiden Plattformen hardwareseitig abgeschlossen. Die bisherigen Erstinstallations-, Wiederholungs- und Containerneustarttests bleiben gültig. Die vollständige Zielinstallation und die Pakete B–F sind damit nicht abgenommen; deren offene Einzelentscheidungen bleiben offen.

## 2. Ein Einstieg, klare Installationsumfänge

### 2.1 Basis, Labor, Optionen und Projekte

| Ebene | Verbindlicher Zweck | Vorgeschlagener Umfang |
|---|---|---|
| Gemeinsame Basis | Plattform-, Benutzer-, Daten- und BSP-Schutz; wiederholbarer Ablauf | Vorhandenen SSH-Zugang prüfen, Projektpfade, kleine Hostwerkzeuge; weitere Voraussetzungen nur bei Bedarf des gewählten Profils |
| Laborprofil | Basis plus vereinbarte Lehr-/Entwicklungsumgebung | Node-RED, lokaler MQTT-Broker und Diagnoseclients als Ziel; Python-Projektentwicklung. GPU-, Kamera- und Verwaltungsoberflächen bleiben Optionen |
| Optionale Komponenten | Ausschließlich für einen nachgewiesenen Anwendungsbedarf | GPU-Containerzugriff/KI-Images, Basler, Portainer; Auswahl durch das Profil, keine Pflichtinstallation aller Komponenten |
| Kunden-/Projektprofil | Basis plus konkret erforderliche Runtimes und Konfiguration | Wiederverwendung derselben Installationsschritte; kein Laborprofil als Kundenvoraussetzung, keine automatische Übernahme anonymer Laborzugänge |
| Anwendung | Fachliche Programme, Flows und konkrete Gerätekonfiguration | Eigene Versionsstände und Daten; verwendet installierte Runtimes und SDK-Bausteine |

Docker Engine ist eine gemeinsam verwendete Hostvoraussetzung für Profile mit Containern, keine Pflicht für jeden denkbaren Kunden ohne Container. Das Labor benötigt Docker bereits wegen Node-RED. NVIDIA Container Runtime wird erst für GPU-Container benötigt. Ein Profil legt Komponenten und deren notwendige Abhängigkeiten fest; es kopiert keine vollständige Installationslogik.

### 2.2 CLI: Ist und Vorschlag zur Freigabe

| Aufruf, relativ zu `platform/gateway/provisioning/` | Bedeutung | Status |
|---|---|---|
| `sudo bash install.sh labor` | Heutige Prüfungen, Projektverzeichnisse und Node-RED | Implementiert; Hardwarestand siehe Abschnitt 1.3 |
| `bash install.sh --help` / `-h` | Hilfe | Implementiert |
| `sudo ./install.sh` | Gemeinsame Basis ohne Laborsoftware | **Vorschlag**, heute ohne Argument abgewiesen |
| `sudo ./install.sh labor` | Basis plus vereinbarter Laborumfang | **Vorschlag für die spätere vollständige CLI**; heutiger Umfang ist kleiner, ausführbare Dateiauslieferung noch festzulegen |
| `sudo ./install.sh projekt <name>` | Basis plus bekanntes, versioniertes Projektprofil | **Vorschlag**, erst mit dem ersten realen Projekt umzusetzen; heute abgewiesen |

`bash install.sh ...` soll als gleichwertiger Einstieg erhalten bleiben. Kein zusätzlicher Root-Wrapper und keine zweite Installeroberfläche sind erforderlich. Die direkte Ausführung mit `./install.sh` setzt das ausführbare Bit des ausgelieferten Skripts voraus. Unbekannte Profile und fehlerhafte Argumente müssen vor Änderungen abbrechen. Projektprofile werden nur aus bekannten freigegebenen Definitionen ausgewählt; die CLI lädt keine beliebigen Shell-Dateien mit Rootrechten.

**Vorschlag für Ergebnis und Ablauf:** Exit 0 bedeutet später, dass alle für das ausgewählte Profil notwendigen Schritte erfüllt sind. Fehlende, nicht ausgewählte Optionen sind kein Fehler. Fehlende Pflichtkomponenten oder ungeklärte Schutzentscheidungen blockieren die betroffenen Änderungen und führen zu einem Fehlerstatus. Heute bedeutet Exit 0 lediglich „keine PROBLEM-Meldung“; die Hardwaremeldung mit fehlendem Mosquitto ist daher kein Beleg für den fertigen Laborumfang. Es wird kein neuer CLI-Planungsmodus auf Vorrat gebaut.

### 2.3 Einfache interne Struktur und Datenverantwortung

Vorerst bleibt die Logik in einem gut lesbaren Bash-Skript. Kleine Hilfsskripte sind erst dann sinnvoll, wenn echte Installationsschritte dadurch verständlicher werden. Keine leeren Komponentenmodule, Plugin-Engine oder zusätzliche Verwaltungssoftware. Die Schutzprüfung für paketändernde Schritte bleibt Bestandteil dieses Installers.

Installer, Runtime, SDK und Anwendung haben getrennte Aufgaben:

- Der **Installer** prüft und richtet die ausgewählten Voraussetzungen ein.
- Die **Runtime** führt Anwendungen aus: etwa ein bestehender Node-RED-Container oder ein Broker.
- Das **SDK** liefert bei Bedarf Bibliotheken, Flows, Vorlagen und Beispiele. Es wird nicht vollständig auf jedem Gateway installiert.
- Die **Anwendung** verwendet diese Bausteine mit eigener Konfiguration und Daten.

Ein neues Node-RED-Projekt verwendet zunächst die vorhandene Runtime. Ein Flowimport oder eine SDK-Vorlage erzeugt keinen neuen Container. Ein Python-Kameraprojekt erhält seine konkrete Umgebung und Kamerabibliothek; es löst keine vollständige KI-Installation aus. Mehrere Node-RED-Instanzen sind erst bei begründetem Isolationsbedarf ein eigenes Vorhaben.

## 3. Funktionskatalog und Freigabekriterien

Die folgenden Abschnitte enthalten Zielumfang, Einordnung, Umsetzung, Voraussetzungen, Entscheidungen, Ist-Stand und Abnahme. **Vorschläge** sind noch nicht implementiert oder einzeln freigegeben. Für jede spätere Paket-/Konfigurationsänderung gilt außerdem Abschnitt 4.1.

### 3.1 Betriebssystem, BSP und Paketverwaltung — gemeinsame Basis, Paket B

**Zweck und feste Vorgaben:** Nur auf der freigegebenen FA-Basis arbeiten. Keine globalen APT-Upgrades, kein ungefragter Austausch von Kernel, DTB, Bootloader, Initrd oder Hardwaretreibern und kein automatischer Reboot. Das installierte NVIDIA-Metapaket ist kein Nachweis der eigenen BSP-Dateien.

**Desktop und Headless-Betrieb:** Das historische Abschalten der grafischen Oberfläche/GDM einschließlich des Wechsels auf `multi-user.target` und des anschließenden Reboots gehört nicht zur normalen Installation. Der Installer deaktiviert den vorhandenen Desktop/GDM nicht automatisch und löst keinen automatischen Reboot aus. Ein optionaler Headless-Betrieb kann später bei konkretem Bedarf gesondert entschieden, freigegeben und getestet werden; dabei sind SSH-/Konsolenzugang und die Rückkehr zum vorherigen Desktopzustand zu prüfen.

**Umsetzungsvorschlag:** Ubuntu, Architektur, laufenden Kernel samt Modulen, L4T-Datei und Core-Paket sowie installierte NVIDIA-Komponenten erfassen. Eindeutige Hardwaremerkmale getrennt vom generischen Modelltext behandeln. Vor APT-Änderungen tatsächliche BSP-Pakete, eigene Dateien, Paketzuordnung, Versionen und Prüfsummen aufnehmen; daraus gemeinsam mit dem BSP-Verantwortlichen die konkrete Schutzmenge ableiten. Bestehende Holds erhalten, zusätzliche Sperren nur nach dieser Entscheidung setzen. Vorhandene automatische Updatewege ebenfalls erfassen und deren Behandlung freigeben, ohne pauschal Sicherheitsupdates abzuschalten. Gezielte Pakettransaktion vorab simulieren; Änderungen oder Entfernungen geschützter Komponenten ablehnen und Zustand danach erneut vergleichen. Keine pauschale Metapaketinstallation von `nvidia-jetpack`.

**Historische Mechanismen und offene Grenzen:** `safe_upgrade` setzt sieben Holds und führt trotzdem mehrfach globale Upgrades aus. Erhalten wird die Schutzabsicht, ersetzt wird der Upgrade-Ablauf durch gezielte, geprüfte Installationen. `wait_for_dpkg_lock` wartet höchstens 300 Sekunden auf genau `lock-frontend`; die Abfrage reserviert den Lock nicht und deckt nicht alle Paketmanager-Sperren ab. Vorgeschlagen ist begrenztes natives APT-Warten nach Prüfung der vorhandenen APT-Version, mit klarer Timeoutmeldung. Niemals Lockdateien löschen oder Paketprozesse beenden. Ein beschädigter dpkg-Zustand stoppt den Schritt; Reparatur wird nicht ungefragt ausgeführt. Weder Holds noch eine Simulation garantieren Schutz vor Maintainer-Skripten/Triggern. NVIDIA dokumentiert Kernel-/DTB-Postinstallationsschritte und beschreibt `nvidia-l4t-core` als Major-Versionsschutz, nicht als Schutz eigener BSP-Artefakte. [NVIDIA R36.4: Pakete und Updates](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/SoftwarePackagesAndTheUpdateMechanism.html#package-dependencies)

**Ist-Stand/Voraussetzungen:** Erkennung, dpkg-Audit und Anzeige der Holds vorhanden; kein APT-Schreibschritt und keine abgesicherte Hostpaketinstallation. Die exakten Schutzpakete, eigenen Artefakte und Paket-/Triggerabhängigkeiten sind vor Umsetzung zu bestimmen. Die Plattformprüfung darf bei fehlender eindeutiger Boardkennung keine erfundene Modellzuordnung treffen.

**Abnahme/Rückfall:** Auf beiden Plattformen erlaubte Installation, gesperrter BSP-Änderungsplan, belegter Lock, Timeout, Unterbrechung und Wiederholung prüfen. Geschützte Pakete/Dateien vor und nach dem Schritt unverändert; Hardwarezugriff und Boot weiterhin funktionsfähig. Vor Hoständerungen muss der konkrete Wiederherstellungsweg samt Originalartefakten bestehen; APT ist keine atomare Transaktion mit garantiertem Rollback. Keine Freigabe durch bloßes „apt install erfolgreich“.

### 3.2 Benutzer und Projektverzeichnisse — gemeinsame Basis, Paket A/B

**Zweck und feste Vorgaben:** Das tatsächliche Projektkonto mit UID/GID und Home verwenden. `friedrich` bleibt der gemeinsame Laborbenutzer mit normalen sudo-Rechten; administrative Experimente sind beabsichtigt. Keine neue Rollenverwaltung, keine pauschalen rekursiven Eigentümer-/Modusänderungen und kein `chmod 777`.

**Umsetzung/Entscheidungen:** Die vorhandenen sechs Verzeichnisse bleiben an Ort und Stelle:

```text
<home>/friedrich-projects/
├── workspace/
│   ├── project/
│   └── nodered/
│       └── projects/
└── nodered_runtime/
```

Neue Verzeichnisse erhalten Projekt-UID, primäre GID und `0750`. Der vorhandene zusätzliche leere Mountpunkt `nodered_runtime/projects` ist kein zweiter Projektbestand. Dateien, Links, falsche Eigentümer und fehlender Zugriff führen zu einer verständlichen Konfliktmeldung. Bestehende Inhalte werden nicht zur „Reparatur“ überschrieben.

**Ist-Stand/Voraussetzungen/Offen:** Auf beiden Geräten mit `1000:1000` und Schreib-/Änderungs-/Löschtests berichtet geprüft. UID/GID-Ermittlung ist dynamisch; die konkrete Node-RED-Imagefassung hat zusätzlich das UID-1000-Gate. Unterstützung anderer Container-UIDs ist eine offene Erweiterungsentscheidung, keine Änderung der Hostkonten. Keine automatische Aufnahme in die Docker-Gruppe.

**Abnahme/Rückfall:** Erstanlage und Wiederholung mit vorhandenen Dateien sowie Datei-, Symlink-, Eigentümer- und Zugriffsfehler lokal und auf Linux prüfen. Der Projektbenutzer und die ausgewählten Prozesse müssen an ihren Zielpfaden schreiben können. Keine Datenmigration erforderlich; bei Konflikt Pfad und Ursache melden und den Bestand erhalten.

### 3.3 Docker und Container — bedarfsgesteuerte Hostvoraussetzung, Paket B/D

**Zweck und feste Vorgaben:** Docker Engine, GPU-Runtime, Dienstcontainer, Anwendungscontainer, Images und Hostdaten getrennt behandeln. Unabhängig aktualisierbare Container mit festgelegten Versionen und Digests; kein Universalcontainer. Ein Wiederholungslauf ersetzt keine fremden oder abweichenden Container.

**Umsetzungsvorschlag:** Vorhandene lokale Engine und Bootaktivierung prüfen; Installation fehlender Hostvoraussetzungen erst nach Paket B. Paketquelle und konkrete Paketversion für einen frischen Host vorab festlegen. Keine ungeprüfte Neuinstallation oder Versionsänderung einer funktionierenden Engine. GPU-Zugriff kommt gesondert hinzu. Laufende passende Container bestätigen; Versionswechsel und Adoption alter Container benötigen Datenbackup, Vergleich und eigene Freigabe. Images sind austauschbare Artefakte, Bind-Mount-Daten ein gesonderter Bestand.

**Ist-Stand/Voraussetzungen/Offen:** Docker 29.1.3 auf beiden Geräten berichtet vorhanden; der Installer installiert Docker noch nicht. Node-RED verwendet ausschließlich den lokalen Unix-Socket. Sein Loopback-Zugang erfordert derzeit Serverversion mindestens 28. Das ist eine Mindestprüfung, keine dauerhafte Freigabe jeder zukünftigen Engineversion. Image-ID und Startkonfiguration werden unter Berücksichtigung ausgelassener Docker-29-Felder verglichen. [Docker: Portveröffentlichung](https://docs.docker.com/engine/network/port-publishing/) und [optionale Inspect-Felder](https://docs.docker.com/engine/deprecated/#emptynil-fields-in-image-config-from-inspect-api)

**Abnahme/Rückfall:** Vorhandene und frisch eingerichtete Engine getrennt prüfen; Daemon-Bootstart, ARM64-Ausführung, Wiederholung, Containerkonflikte und Erhalt persistenter Daten nachweisen. Vor Änderungen an Engine oder Image vorherigen Stand und passende Daten-/Konfigurationssicherung erhalten. Downgrade- und Datenformatkompatibilität vor einem Rückfall prüfen; kein automatisches Löschen von Images, Containern oder Volumes.

### 3.4 Node-RED — Laborstandard, für Kunden optional, Paket A/F

**Zweck und beschlossener Aufbau:** Eine persistente Runtime `mynodered` für Projekte und SDK-Flows. Festgelegtes Image:

```text
ghcr.io/node-red/node-red:5.0.9-debian@sha256:260face7ad06c0968dd130717d1f08fa1d9985e6ff20e26d66f366b9d27bc22a
```

ARM64, getrennte Mounts `nodered_runtime` → `/data` und `workspace/nodered/projects` → `/data/projects`, numerischer Projektbenutzer, `HOME=/data`, Projects-Modus und `unless-stopped`. Die veröffentlichte Hostadresse ist `127.0.0.1:1880`, Zugang über bestehenden SSH-Tunnel. Es gibt keine automatische Veröffentlichung ins Verwaltungs- oder Maschinennetz. Das offizielle Artefakt und die Behandlung der Projects-Variable sind in der [Bedienungsanleitung](README.md) belegt.

**Ist-Stand/Voraussetzungen/Offen:** Auf beiden Plattformen Installation, Editor, Projects, `FLOW1`, Dateipfad, Containerrestart und Wiederholung mit gleicher ID berichtet erfolgreich. Aktuell UID 1000 erforderlich: Das Image hat dafür den für Projects/SSH benötigten Benutzereintrag. GID und Home werden tatsächlich aufgelöst. Eine andere UID oder mehrere Instanzen verlangen eine eigene Bedarfsentscheidung. Docker-Standard-NAT/Filterung ohne direkte fremde Container-Routen bleibt Voraussetzung; Loopback-Publishing ist keine Isolation gegen lokale Administratoren oder andere Container desselben Netzes.

**Abnahme/Rückfall:** Paket A ist einschließlich des vollständigen Gateway-Neustarts auf beiden Geräten laut Johannes am 11.11.2026 bestanden und abgeschlossen. Paket F prüft zusätzlich die tatsächlichen Zugriffsgrenzen und den Extension-/SDK-Projektweg. Settings, Credentials, Projektschlüssel und Projekte zusammen sichern; `.sshkeys`, Runtime-Daten und abhängige Module nicht pauschal als Quellcode veröffentlichen. Bei einem neuen Projekt nur Inhalte kontrolliert importieren, nicht die Runtime neu anlegen. Für Versionswechsel vorheriges Image und dazugehörigen Datenstand vorhalten; die laufende Fassung bleibt bis dahin erhalten.

### 3.5 Mosquitto und MQTT — Laborziel, für Kunden bedarfsgesteuert, Paket C

**Zweck/Trennung:** Broker für Python, Node-RED und externe Geräte. `mosquitto-clients` sind Diagnoseprogramme, `paho-mqtt` ist eine Python-Bibliothek der jeweiligen Projektumgebung, MQTT-Nodes gehören zur Node-RED-Laufzeit. Diese vier Bestandteile werden nicht als ein globales Python-Paketbündel installiert.

**Offene Betriebsentscheidung mit Empfehlung:**

| Option | Nutzen und Aufwand | Risiken, Test und Rückfall |
|---|---|---|
| Nativ, historische Betriebsart gezielt verbessern — **empfohlen** | Bekannter Hostdienst, direkte Bindung an freigegebene Hostadressen; kleiner Aufbau mit systemd und gezieltem APT-Paket | Paket-B-Schutz muss stehen. Konfigurationssyntax/Version und Listener/Bootreihenfolge prüfen. Bestehende Konfiguration, Passwörter, ACLs und Daten sichern; kein Neuinitialisieren einer vorhandenen Passwortdatei |
| Docker — **Alternative** | Festes Image/Digest, eigene Runtime und unabhängiger Versionswechsel; Docker im Labor bereits vorhanden | Zusätzliche Mount-/UID-/Publish-/Daemonabhängigkeiten, externer GigE-/MQTT-Netzweg und Hostfilter gesondert prüfen. Rückfall nur mit vorherigem Image und kompatibler Datensicherung; bestehendes Hostsetup nicht parallel ungeplant ersetzen |

Die historische Kopie installiert den Broker nativ, legt mit `mosquitto_passwd -c -b` eine Passwortdatei neu an und ergänzt einen Listener ohne konkrete Bindeadresse. Die Absicht eines abgesicherten lokalen Labordiensts bleibt erhalten. Feste Passwörter, mögliche Passwortdatei-Überschreibung und pauschale Listener werden nicht übernommen. Noch ist auf den neuen Geräten kein Broker installiert; die Empfehlung ist keine Migrationsentscheidung.

**Umsetzungsvorschlag/Voraussetzungen:** Nach Betriebsformwahl eine festgelegte Brokerkonfiguration mit Persistenz, normalem authentifiziertem Zugang und definierten Topics/ACLs verwenden. Node-RED im Bridge-Container erreicht einen nativen Hostbroker nicht über sein eigenes `127.0.0.1`. Deshalb einen erreichbaren, begrenzten Hostendpunkt ausdrücklich festlegen und testen; keine Docker-Bridge-IP raten und keinen Node-RED-Container dafür ungefragt neu erstellen. Die endgültigen Endpunkte brauchen Paket C1.

**Optionale IFM-Laborausnahme:** Erst konkretes Altgerät und unterstützte Authentifizierung prüfen. Falls nötig, separaten anonymen Listener nur im freigegebenen Maschinennetz mit engen Topic-Rechten und geprüfter netzseitiger Begrenzung vorsehen. Bindung an eine Host-IP allein ist kein Nachweis der Abschottung gegen andere Netze. Keine Weiterleitung ins Hochschulnetz und keine Vererbung dieser Ausnahme ins Kundenprofil. Zugangsdaten werden separat geschützt übergeben; keine Konstanten im Skript oder Prozessargumenten. Die konkrete Mosquitto-Version bestimmt die zulässige Listener-/ACL-Syntax. [Ubuntu 22.04: mosquitto.conf](https://manpages.ubuntu.com/manpages/jammy/man5/mosquitto.conf.5.html), [Mosquitto 2.0](https://mosquitto.org/documentation/migrating-to-2-0/), [Passwortdateiwerkzeug](https://mosquitto.org/man/mosquitto_passwd-1.html)

**Abnahme/Rückfall:** Python aus seiner Umgebung und Node-RED publizieren/abonnieren über die vorgesehenen Endpunkte; Diagnoseclients bestätigen Nachrichten. Autorisierte und abgewiesene Topics, fremder Netzpfad, optionale IFM-Ausnahme, Persistenz, Boot und Wiederholung testen. Bestandsdateien bleiben erhalten; Rückfall auf gesicherte Konfiguration, Brokerstand und kompatible Daten. Die Betriebsform, Adressen, Topic-Rechte und Ausnahmeregeln sind noch nicht freigegeben.

### 3.6 Ethernet, Maschinen- und Rettungszugang — Laboranforderung, kundenbezogen, Paket C1

**Zweck/feste Rollen:** Zwei Ports: Verwaltung mit DHCP, SSH und Standardroute; Maschine mit statischer Adresse und ohne zusätzliche IPv4-/IPv6-Standardroute. Keine gerätespezifischen MAC-Konstanten in öffentlichen Dateien. Aktuell werden Interfaces, MACs, Adressen, NetworkManager-Verbindungen und Routen nur gelesen.

**Empfehlung zur Zuordnung:** Zuerst physische Buchse gegen Hardwarepfad/`ID_PATH` auf beiden Varianten und mehreren Starts verifizieren. Bei stabiler Topologie NetworkManager-Profile über `match.path` zuordnen und bestehende vorhersehbare Namen behalten. Das vermeidet eine zusätzliche Umbenennungsstufe. Falls lesbare Namen tatsächlich nötig sind, `systemd.link` mit geprüfter Pfadzuordnung zu vorgeschlagenen Rollennamen `lan0`/`lan1` erwägen. Die alte MAC-basierte udev-Lösung bleibt Referenz; sie wird nicht vor einem bestandenen Gegenversuch abgelöst. PCI-Pfade können bei anderem BSP/Carrier variieren. Weder `enP7p1s0` noch `enP8p1s0` erhält allein aus seinem Namen eine physische Rolle.

**Servicezugang als noch offener Vorschlag:** Zusätzliche Service-IP am geprüften Maschinenport, ohne Gateway und ohne Überlappung mit Hochschul-, Maschinen-, Docker- oder anderen Servicenetzen. Geräteindividuelle Zuteilung aus einem gemeinsam freigegebenen Schema; passende Service-Laptop-Adresse dokumentieren. Keine einheitliche feste Adresse für mehrere Gateways im selben Netz. Eine Zusatzadresse hilft nicht bei deaktiviertem Interface, kaputtem Profil, fehlendem Link oder ausgefallenem SSH. Lokale beziehungsweise serielle Konsole bleibt letzter Rückfallweg.

**Änderungsablauf/Voraussetzungen:** Profilbestand privat sichern, installierte NetworkManager-Version und Checkpoint-Fähigkeit prüfen, lokalen/seriellen Zugang praktisch erproben. Dann Checkpoint und zeitbegrenzten Rückfall vor der Änderung einrichten, Zugang über eine neue SSH-Verbindung bestätigen und erst danach festschreiben. Checkpoints ersetzen weder die Sicherung persistenter Profile noch einen Boot-/Restore-Test. Sie decken `.link`-/udev-/Netplan-/SSH-/Firewalländerungen nicht ab und gehen bei NetworkManager-Neustart oder Boot verloren. Insbesondere eine Umbenennung benötigt deshalb eine zuvor gesicherte Rücknahme über die Konsole. Ubuntu 22.04 dokumentiert NetworkManager-1.36-D-Bus-Checkpoints; ein bestimmter neuer `nmcli device checkpoint`-Befehl darf nicht vorausgesetzt werden. Kein Upgrade nur für dieses Hilfsmittel. [NM-Profile unter Jammy](https://manpages.ubuntu.com/manpages/jammy/man5/nm-settings-nmcli.5.html), [Checkpoint-API 1.36](https://networkmanager.dev/docs/api/1.36.0/gdbus-org.freedesktop.NetworkManager.html), [systemd.link](https://manpages.ubuntu.com/manpages/jammy/man5/systemd.link.5.html)

**Ist/Offen/Abnahme:** Buchsenzuordnung, Adressschema, Servicekonzept und Wiederherstellung sind offen. Vor Implementierung von Netzwerkänderungen ausdrücklich freigeben. Beide Ports auf beiden Varianten einschließlich Kaltstarts, fehlendem Maschinenlink, unveränderter Verwaltungsroute, falscher Maschinen-IP, Checkpoint-Rückfall, Servicezugang und Konsolenrestore prüfen. Abnahme ist erreichbares SSH nach jedem vorgesehenen Fehlerfall und Boot, nicht lediglich eine syntaktisch gültige NM-Datei.

### 3.7 Python und Entwicklungswerkzeuge — kleine Basis und Labor, Paket B/D

**Zweck/fest:** Normale Projektentwicklung über SSH und Extension; System-Python erhalten. Keine globalen großen Paketbestände und kein `sudo pip` als allgemeiner Installationsweg.

**Grundausstattung als Vorschlag:** Vorhandenes `python3` und Git/SSH-Clientwerkzeuge prüfen; bei Bedarf `python3-venv`, Pip-Werkzeuge, Zertifikate und die konkret benötigten Hostprogramme nach Paket B bereitstellen. Editor oder Compiler/Headers nur bei echtem Bedarf; aus der historischen Nano-Installation folgt keine universelle Editorpflicht. Projektbibliotheken aus festgelegten Anforderungen mit passender Pythonversion in einer venv oder im Projektcontainer installieren. SDK-Bibliotheken werden bei Verwendung versioniert eingebunden, nicht global kopiert. Eine venv isoliert Python-Pakete, nicht sämtliche Systembibliotheken. [Python 3.10: venv](https://docs.python.org/3.10/library/venv.html)

**Ist/Voraussetzungen/Offen:** Der Installer nutzt vorhandenes Python 3 für Docker-Metadaten/HTTP, installiert es aber nicht. Vollständige Werkzeugliste und Paketversionen sind vor Paket B/D je Einsatzzweck festzulegen; eine Installation jeder in der Referenz genannten Entwicklungsbibliothek ist nicht beschlossen.

**Abnahme/Rückfall:** Projekt als normaler Benutzer erstellen, ausführen und über SSH bearbeiten; Isolation zweier verschiedener Abhängigkeitsstände und reproduzierbare Neuerstellung prüfen. Keine globalen Pakete oder Fremdprojekte ändern. Vorherige venv/Projektdateien bei einer Versionsänderung bis zur Abnahme erhalten; keine pauschale Löschung bestehender Umgebungen.

### 3.8 NVIDIA, CUDA und KI — optionale Voraussetzungen und Anwendungen, Paket D

**Zweck/Trennung:** NVIDIA-Hostbasis gehört zum freigegebenen Jetson-/BSP-Stand. NVIDIA Container Runtime/GPU-Zugriff ist eine gesonderte Hostvoraussetzung für GPU-Container. PyTorch, torchvision, TensorFlow, cuDNN und cuSPARSELt gehören in die benötigte, kompatible Projektlaufzeit; nicht jedes Gateway bekommt jedes Framework.

**Umsetzungsvorschlag/Abhängigkeiten:** Vorhandene GPU-Hostpakete samt Versionen erfassen, kompatible Container-Runtime erkennen und nur bei Bedarf nach B absichern. Projektimages bevorzugen, die ausdrücklich zur freigegebenen JetPack-/L4T-/CUDA-Kombination passen; Version, Digest, Python-/Framework-/GPU-Bibliotheken als getestete Kombination festhalten. Kein neuer JetPack- oder CUDA-Hoststand als Nebeneffekt. JetPack 6.1 nennt CUDA 12.6.10 und cuDNN 9.3; das ist Releaseumfang, kein Beleg der installierten Pakete auf den beiden FA-Geräten. [NVIDIA JetPack 6.1](https://docs.nvidia.com/jetson/jetpack/6.1/release-notes/index.html)

**Historischer Befund/Offen:** Die Kopie installiert PyTorch `2.5.0a0+872d972e41`/24.08, NumPy/Cython, danach cuSPARSELt und torchvision 0.20 global. Die offizielle aktuelle Tabelle ordnet diesen PyTorch-Build JetPack 6.0 zu; er wird deshalb nicht als für FA-6.1 freigegebene Kombination fortgeschrieben. Die NVIDIA-Anleitung verlangt bei entsprechenden Builds cuSPARSELt vor PyTorch. Das erklärt Prüfbedarf, beweist keinen damaligen Laufzeitfehler. Original-Wheel/DEB und vollständiger GPU-Teststand fehlen. TensorFlow ist im gelesenen Installer nicht enthalten und bleibt reine Projektoption. [PyTorch-Kompatibilität](https://docs.nvidia.com/deeplearning/frameworks/install-pytorch-jetson-platform-release-notes/pytorch-jetson-rel.html#compatibility), [NVIDIA-Installationsvoraussetzungen](https://docs.nvidia.com/deeplearning/frameworks/install-pytorch-jetson-platform/index.html#prerequisites-and-installation)

**Abnahme/Rückfall:** Je gewählter Kombination GPU-Sichtbarkeit, tatsächliche CUDA-Ausführung eines Tensors mit numerisch überprüfbarem Ergebnis und benötigte torchvision-Operatoren prüfen. CPU-Fallback ist kein bestandener GPU-Test; der historische Torch-Test erlaubt diesen Fallback. Containerstart, Wiederholung und persistente Anwendungsdaten einschließen. Voriges Image/Umgebung und Daten erhalten. Änderungen an GPU-Hostpaketen brauchen zusätzlich den vorher festgelegten Host-Wiederherstellungsweg.

### 3.9 Basler-Kameras — optionale konkrete Kameraprojekte, Paket E

**Zweck/fest:** Eine verwendete GigE-Kamera zuverlässig aus Python ansprechen. AI7100-Kameraeinsatz begründet die Option; das Modell allein löst keine Installation aus. Kamera-Runtime, Python-Wrapper, grafische Konfiguration und weitere Herstellerwerkzeuge getrennt auswählen.

**Empfehlung/Voraussetzungen:** Zunächst ein geeignetes, festgelegtes ARM64-`pypylon`-Binär-Wheel in einer Projekt-venv mit benötigter Runtime prüfen. Eine vollständige pylon-GUI auf jedem Gateway ist nicht nötig. Basler beschreibt pylon als für Binär-Wheels empfohlen, nicht generell zwingend; Sourcebuilds benötigen das SDK. Konfiguration kann auf einem Engineering-PC erfolgen. Für eine spätere Containerlösung muss GigE-Discovery und der Netzwerkpfad einen konkreten Vorteil rechtfertigen. [Basler-pypylon](https://github.com/basler/pypylon#installation)

**Ist/Offen:** Historisch pylon 8.0.1 aus lokalem ARM64-DEB und ungepinntes pypylon im AI7100-Zweig. Das DEB liegt im Arbeitsrepository nicht vor. Konkrete Kamera, Wheel-/Runtimeversion, Lizenz-/Weitergaberechte, Bandbreite und unterstützte Features sind vor Auswahl zu klären. Keine neue Kameraumgebung implementiert oder getestet.

**Abnahme/Rückfall:** Als Projektbenutzer importieren, Kamera finden/öffnen, festgelegte Bildfolge mit erwarteter Größe/Rate erfassen sowie Timeout und Wiederanbindung prüfen. Maschinenport und Managementzugang dürfen dabei ihre Rollen behalten. Funktionierende pylon-Installationen bewahren; vorige Umgebung und gesicherte Kameraparameter als Rückfall erhalten.

### 3.10 Portainer — optionale Laboroberfläche, Paket E

**Zweck/Empfehlung:** Komfort für Unterricht und Containerverwaltung. Docker-CLI mit `ps`, `inspect` und `logs` reicht für den notwendigen Grundbetrieb. **Vorschlag:** keine Pflichtinstallation; Aufnahme erst nach bestätigtem Nutzen für den Laborablauf. Vorhandene funktionierende Instanzen werden nicht grundlos ersetzt.

**Umsetzung/Voraussetzungen/Offen:** Falls gewählt: konkrete kompatible Version/Digest, geschützter Administrationszugang, bestehendes `portainer_data` korrekt zuordnen und getrennte Geheimnisübergabe vorsehen. Docker-Socket-Zugriff verleiht weitreichende Hostkontrolle. Das historische `latest` mit veröffentlichten Ports wird nicht ungeprüft übernommen. Der dokumentierte Erstsetup-Timeout beträgt fünf Minuten; Ablauf ist kein Grund, das Datenvolume zu löschen. Das konkrete Setupverfahren muss zur ausgewählten Version passen. [Portainer: Setup-Timeout](https://docs.portainer.io/faqs/installing/your-portainer-instance-has-timed-out-for-security-purposes-error-fix)

**Ist/Abnahme/Rückfall:** Keine Installation im neuen Installer. Erstsetup, Zugriff, Timeout-Wiederanlauf, Containerrestart und Wiederholung mit gleichem Datenvolume prüfen. Keine festen Adminpasswörter/Token im Skript. Rückfall braucht vorheriges Image und passende Datenbanksicherung; ein beliebiges Downgrade ist kein zugesicherter Wiederherstellungsweg.

### 3.11 VS-Code-Extension und Projektverwaltung — Engineering-Integration, Paket F

**Zweck/fest:** Vorhandene SSH-/Push-/Pull-Funktionalität erhalten. Kein neuer Gateway-Agent und keine vollständige Extension-Neuentwicklung. Die vorhandenen Projektpfade sind der Integrationsvertrag.

**Umsetzungsvorschlag/Voraussetzungen:** Vor Integration Version und vollständigen Quell-/Buildstand der tatsächlich eingesetzten Extension bestimmen. Pythonquellen und Node-RED-Projektquellen gezielt übertragen. `nodered_runtime`, Credentials/Schlüssel, `node_modules`, venvs und generierte große Daten nicht pauschal synchronisieren. Pro Transfer führende Quelle und Konfliktverhalten bestimmen; nicht beide Richtungen automatisch als führend behandeln.

**Ist/Offen:** Historische Teilquellen nutzen SSH; [Befunde](../../../docs/EXTENSION_BEFUNDE.md) zeigen asymmetrischen Push/Pull und verlustgefährdende Replace-Schritte. Vollständiger aktueller Stand fehlt. Der Hardwaretest von `FLOW1` belegt den Node-RED-Pfad, nicht den erfolgreichen Extension-Transfer. Eine sichere Korrektur der Extension wäre bei Bedarf ein gesondert abgegrenzter Entwicklungsauftrag.

**Abnahme/Rückfall:** Mit Testprojekten Python und Node-RED übertragen, auf dem Gateway bearbeiten und zurückholen. Konflikt, Verbindungsabbruch und Wiederholung prüfen, Erfolg erst nach tatsächlicher Transferkontrolle melden. Runtime-/Credential-Bestand unverändert. Vor Transfers Sicherung der betroffenen Testdaten und bisherige Extensionversion erhalten; kein ungesicherter Replace auf wertvollen Projekten.

### 3.12 Offline-Installation, Wartung und Nachweise — späterer Auslieferungsweg, Paket B/F

**Zweck/fest:** Künftige Dateien-/USB-Bereitstellung ermöglichen, ohne jetzt OTA, Paketmanager oder Offline-Framework zu entwickeln.

**Umsetzungsvorschlag:** Bereits jetzt Installerstand, Paketquellen und konkrete Versionen, Abhängigkeiten, Image-Digests, benötigte Konfiguration ohne Geheimnisse und Artefakthashes nachvollziehbar halten. Späterer Offline-Umfang umfasst auch transitive DEBs, Repository-/Signaturvertrauen, ARM64-Images und benötigte Wheels; ein exportiertes Image allein ist keine vollständige Gatewayinstallation. Keine großen Herstellerquellen oder Binärsammlungen ins Git-Repository kopieren; Lizenzen vor Weitergabe prüfen.

**Ist/Voraussetzungen/Offen:** Node-RED-Digest festgelegt, lokale Prüfungen und Hardwaremeldungen dokumentiert; kein vollständiger Hostpaketplan und keine Offline-Lieferung. Paket-/Artefaktregister und bestehende [Release-Regeln](../../../docs/RELEASE_PROCESS.md) verwenden, kein paralleles Verwaltungsregister. Umfang und Update-/Restoreanforderung eines realen Kunden bleiben offen.

**Abnahme/Rückfall:** Zunächst Onlineinstallation aus nachvollziehbaren Ständen und Wiederherstellung testen. Eine behauptete Offlinefreigabe braucht später einen echten Versuch ohne Netz mit vollständigen Artefakten. Vorherige kompatible Artefakte und Datenbackups als Rückfall behalten. Keine unbeaufsichtigte Updatefunktion aus diesem Konzept ableiten.

## 4. Ablauf, Entwicklungspakete und Freigaben

### 4.1 Gemeinsame Abnahmebedingungen

Vor Änderungen: Profil und erforderliche Komponenten bestimmen, vorhandenen Zustand lesen, Konflikte und Schutzgrenzen prüfen, betroffene Konfiguration/Daten sichern. Nach jedem Schritt Ergebnis kontrollieren und verständlich melden. Unterbrechungen werden durch erneute Zustandsprüfung behandelt, nicht durch blindes Wiederholen aller Schreibbefehle. Ein passender Bestand bleibt bestehen; eine abweichende Installation wird nicht automatisch adoptiert, gelöscht oder ersetzt.

Jedes Paket benötigt einen identifizierbaren Installer-/Konfigurationsstand, lokale Prüfungen, reale Tests durch Johannes und dessen Freigabe. Prüfungen mit Stubs sind kein Boot-, Netzwerk- oder GPU-Nachweis. Private Geräteadressen und Zugangsdaten verbleiben außerhalb öffentlicher Dokumente. Protokolle enthalten Versionen, Testumfang, Resultat und Einschränkungen; kein neues Protokollsystem ist erforderlich. Git-Commits und Veröffentlichung übernimmt Johannes.

### 4.2 Entwicklungsfahrplan

| Paket | Ziel und Umfang | Voraussetzung / Reihenfolge | Tests und eindeutiges Abschlusskriterium | Aktueller Status |
|---|---|---|---|---|
| **A – Bestehende Basis und Node-RED abschließen** | Vorhandene Prüfungen, Projektverzeichnisse und Node-RED als funktionierenden Ausgangsstand sichern | Bestehendes Friedrich-BSP, installierte Docker-/Pythonvoraussetzungen | Auf beiden Geräten vollständiger Gateway-Neustart: automatischer Containerstart, SSH-Tunnel/Editor, erhaltenes `FLOW1` samt Nodes. Vorhandene Installations-/Wiederholungstests zuordnen; Johannes gibt diesen Stand frei | **Abgeschlossen:** Hardwareabnahme einschließlich vollständigem Gateway-Neustart auf AI7020-8 und AI7100-3 am 11.11.2026 durch Johannes bestätigt. Kein allgemeines Basisprofil ohne Argument daraus ableiten |
| **B – BSP-Schutz und Hostvoraussetzungen** | Schutzmenge und erlaubte Paketänderungen definieren; Paketmanagerfehler/Locks/Wiederanlauf; kleine Hostwerkzeuge und fehlende Docker-Voraussetzungen; Basis-/Labortrennung und freigegebene CLI umsetzen | A abgeschlossen, bestätigte BSP-Paket-/Dateibasis, Auswahl der Hostpakete und Quellen | Vor-/Nachhervergleich geschützter Artefakte auf beiden Varianten; erlaubte und blockierte Transaktion, Lock/Timeout, Unterbrechung/Wiederholung, vorhandene Daten und Hostboot prüfen. Abschluss: benötigte Hostpakete installierbar, unerlaubte BSP-Änderung abgewiesen und Rückfall praktisch verfügbar | Entwicklung fehlt; nur Vorprüfungen vorhanden |
| **C1 – Portzuordnung und Netzwerkzugang** | Hardwarepfade, DHCP-/Maschinenrolle, Adressschema, Servicezugang und Rückfall festlegen, dann gezielt umsetzen | B; physische Buchsen geprüft; lokale/serielle Wiederherstellung getestet; gesonderte Freigabe der konkreten Netzwerkänderung | Beide Varianten: Zuordnung nach Kaltstart, Standardrouten, Verwaltung trotz Maschinenfehler, Checkpoint-Rückfall und Konsolenrestore. Abschluss: ausdrücklich freigegebene Konfiguration mit nachgewiesenem Rettungsweg | Nur lesende Inventur; Rollen/Adressen/Umsetzung offen |
| **C2 – MQTT** | Broker, Diagnoseclients und vorgesehene Clientzugänge; optionale kontrollierte IFM-Ausnahme getrennt | B und Betriebsform-/Sicherheitsentscheidung; C1 vor externen Listenern. Reiner lokaler Broker-/Clienttest kann separat vorgezogen werden | Python↔Broker↔Node-RED und externe Geräte, Topicrechte/Abweisung, Persistenz, Boot und Wiederholung. Abschluss: alle ausgewählten Endpunkte samt Grenzen geprüft; optionale Ausnahme einzeln freigegeben | Broker fehlt erwartungsgemäß; native Betriebsform empfohlen, noch unentschieden |
| **D – Python und optionale GPU/KI-Grundlagen** | Reproduzierbare Projektumgebungen; bedarfsgesteuerter GPU-Containerzugriff und genau ausgewählte Frameworkkombination | B; für MQTT-Beispiele C2. NVIDIA-Kompatibilität vor Host-/Imageauswahl | Normaler Benutzer, getrennte Umgebungen, Versions-/Digestnachweis; für ausgewählte KI echte GPU-Operation und benötigte Operatoren. Abschluss je gewählter Kombination, kein pauschales „alle KI-Stacks fertig“ | Noch keine neue Python-/GPU-Installationsfunktion |
| **E – Bedarfsbezogene Zusatzsoftware** | Gewählte Basler-Unterstützung und gegebenenfalls Portainer | B und realer Kamera-/Lehrbedarf; für Basler zusätzlich Python-Teil aus D und C1 für GigE; Portainer benötigt die geprüfte Docker-Basis. Freigegebene konkrete Versionen | Kamera-Bildfolge/Fehlerfall oder Portainer-Setup/Volumeerhalt; jeweils Wiederholung und Rückfall. Abschluss nur für ausgewählte Komponenten, andere bleiben ungewählt | Historische Referenzen; keine neue Umsetzung |
| **F – Integration und Gesamtabnahme** | Vollständiges ausgewähltes Profil, Extension, SDK-Beispiel-/Anwendungsweg, Datenpflege und Wiederherstellung gemeinsam prüfen | Erforderliche Teile A–E abgenommen; vollständige aktuelle Extension für ihren Test vorhanden | Frisch geflashter AI7020 und AI7100, genauer Installerstand, Erstlauf, Re-Run, Gatewayboot, Datenzugriff, Netzrettung und Backup/Restore. Abschluss: Johannes gibt genau dieses Profil mit dokumentierten Versionen/Artefakten frei; ein nicht definiertes Kundenprofil wird nicht mitfreigegeben | Offen; wird nicht durch bisherigen Teilstand 8/1/1/0 ersetzt |

Die Reihenfolge A → B → C → D → E → F ist technisch sinnvoll. C1 und C2 bleiben getrennt abnehmbar; kamerabezogene E-Arbeiten brauchen C1, nicht zwingend einen Broker. Optionale KI- oder Portainer-Arbeiten sind kein künstlicher Blocker für ein Profil, das sie nicht benötigt. Netz- und BSP-Freigaben sind echte Gates; sie werden nicht durch einen erfolgreichen Node-RED-Test ersetzt.

## 5. Wirklich offene Entscheidungen

| Entscheidung | Empfehlung zur Freigabe | Wann entscheiden / Alternative |
|---|---|---|
| Endgültige CLI und gemeinsame Hostbasis | Kein Argument = Basis; `labor` = Basis plus Laborumfang; `projekt <name>` erst bei realem Projekt. Docker bedarfsabhängig | Gesonderte Festlegung und Freigabe in Paket B vor Umsetzung; heutige Labor-CLI bis dahin beibehalten. Ein explizites `basis` wäre eindeutig, braucht aber ein zusätzliches Wort ohne bisherigen Nutzen |
| Exakte BSP-Schutzmenge und erlaubte Hostpakete | Aus tatsächlichen FA-Dateien/Paketen, Triggern und freigegebenen Paketquellen ableiten | Vor erstem APT-Schreibschritt in B; kein historisches Holdset als vollständiger Schutz |
| Physische Rollen, dauerhafte Kennung, Adressen und Rettungsweg | Geprüfter Hardwarepfad mit NM-Profilzuordnung; Zusatz-Service-IP nur mit eindeutiger Zuteilung und Konsole | Vor C1-Netzänderung ausdrücklich freigeben. `systemd.link` nur bei begründetem Namensbedarf; MAC-Zuordnung als Bestandsalternative erhalten |
| MQTT-Betriebsform und Zugriffsregeln | Nativ, gezielt abgesichert; gesonderte kontrollierte IFM-Ausnahme nur bei realem Bedarf | Vor C2. Docker ist eine gültige Alternative nach Mount-/Netz-/Restorevergleich. Hostendpunkt für Node-RED ausdrücklich festlegen |
| Node-RED für andere UIDs / mehrere Instanzen | Gegenwärtigen getesteten Stand mit UID 1000 beibehalten | Erst bei abweichendem Kunden-/Projektbedarf Image-/Benutzerstrategie und Rückfall vergleichen; keine Hostkonto-Migration |
| Python-, KI- und Kameraversionen | Kleine Hostbasis, projektbezogene venvs beziehungsweise passende KI-Container; konkrete Versionen nach Bedarfsprüfung | B/D/E; Host-Frameworkinstallation nur bei belegtem Vorteil und eigener Kompatibilitätsabnahme |
| Portainer-Umfang | Optional; CLI genügt für den Basisbetrieb | E erst nach Unterrichts-/Betriebsnutzenentscheidung; bestehende Instanz erhalten |
| Extension-Synchronisation und erster Kunden-/Offlineumfang | Vorhandenen SSH-Weg und Datenpfade verwenden; konkreten Quell-/Buildstand und Transferregeln bestimmen | F beziehungsweise erstes reales Kundenprofil; kein Agent oder Offline-System vorziehen |

Die übergeordnete Architektur- und Fahrplanfreigabe gibt die Empfehlungen und offenen Detailentscheidungen dieser Tabelle nicht automatisch frei. Sie werden im betreffenden Arbeitspaket gesondert entschieden und vor Umsetzung freigegeben; dies gilt insbesondere für konkrete Netzwerkparameter sowie BSP-/Datenformatwechsel. Ein Vergleich mit größerem Ersatzumfang wird erst bei einem realen Problem und nachgewiesenem Nutzen erneut aufgemacht.

## 6. Abgleich mit Bestand und Dokumentation

| Ausgangsbefund vor Konsolidierung | Einordnung / Behandlung in diesem Auftrag |
|---|---|
| Root-README sprach von erst anzulegendem Repo und sofortigem ersten Analyseauftrag; Gateway-README sagte „kein neuer Installer“ | Überholt; Einstieg auf vorhandenen Installer, dieses Konzept und aktuelle Nachweise korrigiert |
| Root-/Statuspriorität „sofort IgH“ gegenüber aktuellem Installerauftrag | Prioritätsabweichung gekennzeichnet und aufgelöst: jetzt Installerkonzept, IgH bleibt gesondertes übergeordnetes Integrationsziel gemäß Issue #12 |
| Alte Offen-Listen enthielten noch keine neueren Liveberichte | Historischen Eingangsstand gekennzeichnet und aktuellen Projektstatus verlinkt; fehlende Originalartefakte bleiben fehlend |
| Provisioning-README nannte den Wiederholungslauf noch offen | Historische Testchronik erhalten; aktuelle Aussagen berücksichtigen die erfolgreichen Wiederholungsläufe und die inzwischen bestandene Paket-A-Neustartabnahme beider Geräte |
| Runtime-Labor-README „noch nicht implementiert“ | Aktuelle Teilimplementierung im zentralen `install.sh` verlinkt; keine zweite Compose-/Profilstruktur angelegt |
| Legacy: rekursive Rechte, feste Benutzer/MAC/Passwörter, globales Upgrade, öffentlicher Node-RED-Port, `latest` und Settings-sed, GDM-Abschaltung/Reboot | Historische Absicht bewahren, diese Mechanismen nicht blind übernehmen. Neue Verzeichnis-/Node-RED-Umsetzung bereits gezielt verbessert; APT/Netz/Zusatzsoftware bleiben eigene Pakete |
| Legacy: Modellzweig installiert Basler auf AI7100 und gemeinsame KI überall | In Bedarfskomponenten überführen; Hardwaremodell allein ist keine Anwendungsanforderung |
| Allgemeine Architektur erlaubt native Dienste und optionale Container | Kein Widerspruch zur konkreten Laborentscheidung Node-RED in Docker. Keine allgemeine Container- oder SDK-Pflicht ableiten |
| Changelog-Inhalte und Source-/Buildstände stimmen nicht überall überein | Lesbare Quelldatei, Berichte und Changelog getrennt kennzeichnen; keine nicht gelesenen Funktionen oder erfolgreichen Tests ergänzen |

Nur betroffene Einstiegs-/Statushinweise werden mit diesem Auftrag angepasst. Alte Quellen, BSP-Anleitungen und Installer-Code bleiben unverändert. Das Konzept enthält den technischen Teilplan, keine zweite Projektsteuerung.

## 7. Pflege und genau ein nächster Schritt

Dieses Dokument beschreibt Zielumfang, Entscheidungen und technische Paketabnahmen. [PROJEKTSTATUS.md](../../../docs/PROJEKTSTATUS.md) hält tatsächliche Implementierung und Nachweise fest. [README.md](README.md) beschreibt ausschließlich die Bedienung des aktuell verfügbaren Installers. Ändert ein freigegebener Schritt die CLI oder Voraussetzungen, werden diese drei Sichten gezielt konsistent gehalten; keine kopierten parallelen Funktionslisten.

Auf Grundlage des freigegebenen Konzepts arbeitet Codex jeweils innerhalb des ausgewählten Pakets, nachdem der konkrete Umsetzungsauftrag und die erforderlichen Detailentscheidungen freigegeben wurden. Codex prüft lokal, benennt reale Testgrenzen und dokumentiert das Ergebnis. Johannes führt Hardwaretests und Git-Schreibaktionen durch. Paket A ist nach dem vollständigen Gateway-Neustarttest auf beiden Plattformen abgeschlossen; Paket B kann nun vorbereitet werden. Seine Detailentscheidungen bleiben gesondert festzulegen. Dieser Dokumentationsschritt implementiert keine Funktionen aus B–F.

**Genau ein nächster Schritt – Vorbereitung von Paket B:** Die tatsächliche BSP-/NVIDIA-Paket- und Artefaktbasis mit Versionen, Paketzuordnung und Prüfsummen lesend zusammenstellen. Daraus den konkreten Schutzbedarf für B ableiten und die Schutzpakete sowie erlaubten Paketänderungen gesondert festlegen und freigeben. Keine APT-, Hold-, BSP- oder Installeränderung aus der Abnahme von A ableiten. Paket A bleibt der hardwareseitig abgenommene Ausgangsstand.
