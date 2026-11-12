# Arbeitsstand und Fokus (2026-11-12)

## Gateway-Provisionierung

Die Bestandsanalyse ist abgeschlossen. Johannes hat den ersten lesenden Stand von [`install.sh`](../platform/gateway/provisioning/install.sh) auf je einem AI7020 und AI7100 getestet. Die folgenden Ergebnisse stammen aus seiner Rückmeldung vom 10.11.2026 und beziehen sich auf den Ist-Check. Der Hash der ausgeführten Skriptkopien wurde nicht mitgeliefert.

| Testgerät | Hardware | Ergebnis |
|---|---|---|
| AI7020 | Jetson Orin Nano | 5 vorhanden, 5 fehlen, 2 offen, 0 Probleme |
| AI7100 | Jetson Orin NX | 5 vorhanden, 5 fehlen, 2 offen, 0 Probleme |

- **System und Konto.** Auf beiden Gateways wurden Ubuntu 22.04 (ARM64), Kernel `5.15.148-tegra`, Jetson Linux R36.4.0 und Docker 29.1.3 erkannt. `dpkg --audit` war unauffällig. Das Konto `friedrich` hatte auf beiden Geräten UID und GID 1000.
- **Modellkennung.** Beide Device Trees meldeten `NVIDIA Jetson Orin NX Engineering Reference Developer Kit`. Beim AI7020 weicht dieser Text von der verbauten Orin-Nano-Hardware ab. Der Modelltext eignet sich damit nicht zur eindeutigen Unterscheidung der beiden Gateway-Modelle.
- **Paketschutz.** `apt-mark showhold` war auf beiden frisch geflashten Geräten leer. Vor späteren Paketinstallationen muss der Schutz der angepassten Kernel-, Device-Tree- und übrigen BSP-Komponenten geprüft sein.
- **Netzwerk.** Je Gerät hatte eine Schnittstelle Link, DHCP und die IPv4-Standardroute. Die zweite hatte keinen Link. Laut Entwickler stimmten die MAC-Adressen des getesteten AI7100 mit der historischen Referenz überein. Die physische Buchsenzuordnung und der Hardwaretest für Wartungs-IP und Netzkonfiguration stehen aus.
- **Ausgangszustand der Dienste und Projektpfade.** Mosquitto, Node-RED und die Projektverzeichnisse waren laut Entwickler beim lesenden Ist-Check auf den frischen Systemen noch nicht eingerichtet. Der Containerbestand blieb bei der konservativen Docker-Abfrage offen.

**Entwicklungsstand der Verzeichnisanlage.** Der Installer legt fehlende Pfade mit UID/GID des Projektkontos und Modus `0750` an. Im isolierten Windows-Test-Home wurden Erstanlage, Wiederholung mit vorhandenen Dateien, Datei- und Linkkonflikte sowie Wiederanlauf nach einem Anlagefehler geprüft. Die Linux-Eigentümer- und Modusprüfung sowie der Privilegwechsel wurden simuliert. Die anschließende Bash-Syntaxprüfung war erfolgreich.

**Hardwaretest der Verzeichnisanlage, von Johannes am 10.11.2026 berichtet.** Auf AI7020 und AI7100 wurden jeweils alle sechs vorgesehenen Verzeichnisse mit UID/GID `1000:1000` und Modus `0750` angelegt. In den drei Projekt-/Runtime-Zielverzeichnissen waren Anlegen, Ändern und Löschen von Testdateien als Projektbenutzer erfolgreich. Johannes meldete keine Fehler. Der damals noch offene Wiederholungslauf unter Linux ist inzwischen durch den nachfolgend berichteten Node-RED-Hardwaretest auf beiden Plattformen bestätigt.

**Node-RED im Laborprofil.** Der aktuelle Implementierungsauftrag ergänzt `mynodered` mit dem festgelegten ARM64-Debian-Image Node-RED `5.0.9`. Voraussetzung sind Docker Server ab Version 28, ein aktiver und für den Bootstart aktivierter Docker-Dienst sowie Projektkonto-UID 1000. Die ermittelte primäre GID wird übernommen. Runtime und Projekte behalten ihre getrennten Bind-Mounts. Projects wird vor dem Start aktiviert. Der Editor ist ausdrücklich für SSH-Portweiterleitung über die Hostbindung `127.0.0.1:1880` vorgesehen. Vorhandene Container und Laufzeitdaten werden vor einer Wiederverwendung geprüft. Konfiguration, genaue Image-Referenz und Quellen stehen in der [Provisionierungsanleitung](../platform/gateway/provisioning/README.md).

**Prüfstand der Node-RED-Erweiterung.** Bash-Syntax und Hilfe sind geprüft. Unter Windows bestanden am 10.11.2026 44 Fälle eines isolierten Testharness mit simuliertem Docker sowie drei tatsächliche lokale HTTP-Prüfungen. Die damaligen Docker-Stubs bildeten fehlende optionale Inspect-Felder nicht ab. Johannes berichtet am 11.11.2026 funktionierenden Node-RED-Betrieb auf AI7020; `FLOW1` samt Nodes blieb nach manuellem Container-Restart erhalten. Der zweite Installerlauf scheiterte an der Bestandsabfrage für `.Config.Cmd`.

**Korrektur am 11.11.2026.** Ausschließlich der Start-Metadatenvergleich der vorhandenen Docker-Installation wurde korrigiert. Ausgelassene/leere optionale Felder werden als Standardwerte behandelt; echte Konfigurationsabweichungen bleiben Konflikte. Bash-Syntaxprüfung, 14 gezielte simulierte Fälle des Bestandszweigs und 829 direkte JSON-Fixture-Prüfungen bestanden. Skript-Prüfsumme, Ursache und Grenzen stehen im [Korrekturprotokoll](../platform/gateway/provisioning/README.md#korrektur-der-docker-bestandsprüfung-11112026). Codex hat keine Container oder Projektdaten auf einem Gateway verändert. Der anschließend von Johannes berichtete Hardwaretest bestätigt den korrigierten Wiederholungslauf auf beiden Plattformen.

**Node-RED-Hardwaretest, von Johannes am 11.11.2026 berichtet.** Die folgenden Ergebnisse wurden auf beiden echten Gateways erfolgreich geprüft. Prüfsummen der auf den Geräten ausgeführten Skriptkopien wurden nicht mitgeliefert.

| Testgerät | Hardware | Node-RED | Installer-Ergebnis |
|---|---|---|---|
| AI7020-8 | Jetson Orin Nano | 5.0.9 | 8 vorhanden, 1 fehlt, 1 offen, 0 Probleme |
| AI7100-3 | Jetson Orin NX | 5.0.9 | 8 vorhanden, 1 fehlt, 1 offen, 0 Probleme |

- Installation von Node-RED 5.0.9 sowie Zugang über SSH-Tunnel und Editor erfolgreich.
- Projects-Modus funktionsfähig; Testprojekt `FLOW1` mit seinen Nodes angelegt und Projektdateien im vorgesehenen Verzeichnis vorhanden.
- Containerneustart erfolgreich; Projekt und Nodes bleiben erhalten.
- Wiederholter Installerlauf ohne Fehler; vorhandener Container erkannt und Container-ID unverändert.

Mosquitto fehlt erwartungsgemäß, da es noch nicht installiert wurde. Laut Johannes sind die genannten Node-RED-Hardwaretests auf beiden Plattformen bestanden. Die zunächst noch ausstehende vollständige Gateway-Neustartabnahme ist mit der folgenden Rückmeldung abgeschlossen.

**Paket A abgeschlossen – Hardwareabnahme am 11.11.2026 durch Johannes.** Der vollständige Linux-Neustart wurde auf beiden Gateways erfolgreich durchgeführt und von Johannes als Abschluss von Paket A gemeldet.

| Testgerät | Hardware | Vollständiger Gateway-Neustart und Funktionsprüfung |
|---|---|---|
| AI7020-8 | Jetson Orin Nano | Bestanden; Docker meldet für `mynodered` zusätzlich ausdrücklich `healthy` |
| AI7100-3 | Jetson Orin NX | Bestanden; keine gesonderte Docker-Health-Meldung übermittelt |

Für beide Plattformen bestätigt:

- Docker und Node-RED starten automatisch; `mynodered` läuft ohne manuellen Start.
- `FLOW1`, `flows.json` und die übrigen Projektdateien bleiben erhalten.
- Die Dateieigentümer sind weiterhin `friedrich`.
- Node-RED funktioniert nach dem vollständigen Linux-Neustart weiterhin.

Die zuvor bestandenen Erstinstallations-, Wiederholungs- und Containerneustarttests bleiben gültig. Paket A ist damit hardwareseitig erfolgreich abgenommen und abgeschlossen. Die zusätzliche `healthy`-Meldung wird ausschließlich dem AI7020 zugeschrieben. Diese Abnahme erweitert weder den Funktionsumfang auf B–F noch die Freigabe der ausdrücklich offenen Einzelentscheidungen.

**B1 – Hardwareinventare ausgewertet.** Johannes führte [`b1_inventory.sh`](../platform/gateway/provisioning/b1_inventory.sh) am 11.11.2026 auf beiden Gateways aus. Die Originale wurden vollständig gegen die aktuelle BSP-Sicherung abgeglichen; Befunde, Hashes und Grenzen stehen in [B1_AUSWERTUNG.md](../platform/gateway/provisioning/B1_AUSWERTUNG.md). Identische Kernel-/Modulbestände, passende Friedrich-DTBs und 45 L4T-Upgrade-Kandidaten sind belegt. Pins, Quelle 13, Skriptketten und der Pfadausschluss bleiben gezielt zu klären; keine vollständige BSP-/Restore-Freigabe daraus ableiten.

Lokal am 11.11.2026: Bash-Syntaxprüfung und 41 simulierte Python-Prüffälle bestanden; statischer Abschlussreview ohne weitere blockierende Befunde. Linux-Rechte, sudo und Systemantworten waren simuliert, keine Gatewayausführung. Skriptprüfsumme, Testumfang und Grenzen stehen in der Provisionierungsanleitung. Das ist keine B1-Hardwareabnahme oder B2-Freigabe.

**B2 – Historischer Vorbereitungsstand vor der späteren Holdfreigabe.** Der Installer bot zunächst eine reine `bsp-plan`-Simulation und einen fest gesperrten `bsp-holds`-Schritt. Die damalige 15er-Liste war Vorschlag; die Plansperre erfasst zusätzlich weitere L4T-/Boot-/Regenerationspakete. Es gibt keinen APT-Installationspfad. Paket-A-Funktionen und Laborablauf blieben bytegleich zur abgenommenen Ausgangsfassung. Die spätere Freigabe der 15 Holds und Johannes' B2-Rückmeldungen stehen in der [Provisionierungsanleitung](../platform/gateway/provisioning/README.md#b2-schutzprüfung-vorbereitet-aktivierung-gesperrt).

Lokal: 81 isolierte Prüfungen bestanden (Python-Syntax und 41 Planfälle, 34 Bash-Funktionen, vier CLI-Exitfälle, Bash-Syntax). APT, Paketstatus, Holdzustand und Basistest-EUID waren simuliert; keine Linux-/Gatewayabnahme oder reale Hold-Aktivierung. Installer-SHA-256 `8bdaa21c5013e6e2c241a50b0bf34e44de4aa1b88a5a65dcccc2cf302403dc15`.

**C1 – Vereinfachte automatische MAC-Bindung beider Profile, Stand 12.11.2026.** Nur `c1-install` und der lesende `c1-status` bleiben. Beide vorhandenen Ethernetprofile werden eindeutig nach Hardware/Profilbestand gewählt; nur permanente MAC setzen und `connection.interface-name`/`match.interface-name` leeren. UUIDs, Autoconnect und alle IP-/DHCP-/Gateway-/DNS-/Routen-/IPv6-Einstellungen bleiben erhalten, LAN2 normal IP-fähig. Kein normales Up/Down/Reapply, Konfigurationsreload oder Unmanaged-Delta; unklare/widersprüchliche Zuordnung blockiert.

Vor erster Änderung einmalige root-private Sicherung beider Original-Keyfiles unter `/var/lib/friedrich/c1/profile-backup` mit exakten Manifestpfaden/Hashes/Metadaten; keine Überschreibung. Kein automatischer Rückfall bei Teilfehlern. Manueller Restore beider Originaldateien mit Manifest-UID/GID/Modus und gezieltem `nmcli connection load`, ohne globale Netz-/USB-Änderungen. Neue Rollen-/Transaktionszustände entfallen. CLI-Exit `0` korrekt/fertig, `1` fehlend/Fehler; Status legt keine Dateien/Locks an. [Hardwarebefehle und manueller Restore](../platform/gateway/provisioning/C1_NETZWERK.md).

Letzter bekannter alter Hardwaretoken: `fdc6522353f89699`, Status **unbekannt**, von Codex nicht auf dem Gerät gelesen. Johannes führt zuerst den eingefrorenen Rückfallhelper über USB/Konsole aus; Pending/offene oder inkonsistente Altzustände und alte LAN2-Unmanaged-Datei blockieren den neuen Lauf. Keine Backups/Zustände pauschal löschen. Der frühere AI7100-Profilabbruch und der spätere Altversuch sind keine abgeschlossene C1-Abnahme.

Johannes berichtet USB-Ping/-SSH und Kaltstart ohne LAN1 auf beiden Geräten erfolgreich; NVIDIA-Service/Bridge/IP/Gadget bleiben unverändert. Am 12.11.2026 bestanden **31 gezielte Tests** (13 Erkennung/Profilwahl/Quellen/Altzustand, 18 Installation/Backup/Wiederholung), Python-AST, Bash-Syntax, Hilfetext und `git diff --check`; echte Dateien, simulierte Linux-/NM-/Hardwaregrenzen. Alte Transaktions-/SSH-Tests entfernt/ersetzt. Helfer 290 Zeilen, SHA-256 `c16c9a3b5ea02f1aa4c4ab05e1492e296a2a2a4974a6eff58ce0a8bf9b79b852`; Installer `ec09120a618d7a6b31a27fd771d748742fed842f48c7c0c31900c1bcf0629275`. [Prüfnachweis und Grenzen](../platform/gateway/provisioning/C1_NETZWERK.md#prüfnachweis-und-abnahme). Hardwareabnahme offen. `C1_IN_LAB_APPROVED=no` bleibt bis zur Aktivierungs-/Neustartabnahme beider Geräte; später derselbe Bindungscode im Labor. Codex führt keine Gatewayaktionen aus; Paket A/Node-RED/B2 bleiben erhalten.

**C2-Übergang:** Nativer Mosquitto-Broker bevorzugt, Umsetzung nur als eigener Auftrag. Vor echter APT-Installation BSP-Schutz, Quellen, Pinning und konkrete Transaktion prüfen; Brokerzugriff, Authentifizierung, Node-RED-Docker-Netzwerk und Listener gesondert behandeln. Kein MQTT in diesem C1-Auftrag.

**Genau ein nächster Schritt.** Johannes führt nach gegebenenfalls nötiger Altbereinigung über USB/Konsole den beschriebenen AI7100-C1-Test mit Wiederholung und manuellem Neustart durch; erst bei Erfolg folgt AI7020.

## Aktueller Installerauftrag

Das [Installationskonzept](../platform/gateway/provisioning/INSTALLATIONSKONZEPT.md) wurde am 11.11.2026 nach zwei Dokumentationspräzisierungen von Johannes auf übergeordneter Ebene freigegeben: Architektur und Entwicklungsfahrplan A–F gelten als Rahmen. Als Vorschlag gekennzeichnete Details werden im jeweiligen Paket gesondert festgelegt und freigegeben. Die normale Installation deaktiviert Desktop/GDM nicht automatisch und führt keinen automatischen Reboot aus; ein optionaler Headless-Betrieb braucht später eine gesonderte Entscheidung und Tests. Paket A ist abgeschlossen, B1 ausgewertet; die spätere 15er-Holdfreigabe ist in der Provisionierungs-README dokumentiert. C1 ist als einfache automatische MAC-Bindung beider vorhandenen Profile mit Einmalbackup und manuellem Restore implementiert; die Hardwareabnahme ist offen. Johannes führt den kontrollierten Test aus; Codex führt keine Gatewayaktionen aus. Die normale Laborintegration bleibt bis zur Abnahme beider Geräte gesperrt. Keine reale APT-Installationsfunktion und keine C2–F-Implementierung in diesem Auftrag. Gatewaykonfigurationen bleiben durch Codex unverändert.

## Übergeordnetes Integrationsziel, separater Auftrag

Der spätere IgH-/EC100-Datenpfad nach [Issue #12](https://github.com/pyroelectronic/FRIEDRICH-AUTOMATION/issues/12) bleibt maßgeblich (`codex/02_IGH_EC100.md`). C1 bindet nur die vorhandenen Profile per MAC; LAN2 bleibt normal IP-fähig. IgH-Master und EtherCAT-Datenpfad werden nicht installiert oder konfiguriert. Der Installer-Teilstand erfüllt die dortige Gesamtabnahme noch nicht.

## Danach, noch nicht aktiv

- Installerumfang und Extension-Integration werden ausschließlich im Installationskonzept geplant; hier keine zweite Aufgabenliste dazu.
- [ ] Studentenvorlagen in Module/Examples/Templates überführen.
- [ ] AI8200-Server-Baseline definieren.
- [ ] Kundenspezifische Sicherheit, Restore und langfristige Upgrade-Strategie.

**Nicht heute:** JetPack-Migration, gesamtes SDK bauen, Git-Reorganisation vorhandener Produkt-Repos, Live-Flash ohne Recovery.

Das zentrale Management-Repo mit Issues bleibt **einzige Aufgabenquelle**. Diese Datei ist nur ein technischer Wegweiser; keine doppelte Tagesplanung.
