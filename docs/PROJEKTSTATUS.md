# Arbeitsstand und Fokus (2026-11-11)

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

**Genau ein nächster Schritt.** Paket B – BSP-Schutz und Hostvoraussetzungen – lesend vorbereiten: die tatsächlich installierten BSP-/NVIDIA-Pakete und zugehörigen eigenen Artefakte mit Versionen und Prüfsummen als Grundlage der Schutzentscheidung zusammenstellen. Konkrete Schutzpakete und erlaubte Paketänderungen werden anschließend innerhalb B gesondert festgelegt und freigegeben. In diesem Dokumentationsschritt wurden keine Installer-Funktionen, Pakete oder Gatewayzustände verändert.

## Aktueller Installerauftrag

Das [Installationskonzept](../platform/gateway/provisioning/INSTALLATIONSKONZEPT.md) wurde am 11.11.2026 nach zwei Dokumentationspräzisierungen von Johannes auf übergeordneter Ebene freigegeben: Architektur und Entwicklungsfahrplan A–F gelten als Rahmen. Als Vorschlag gekennzeichnete Details, insbesondere BSP-Schutzpakete, konkrete Netzwerkparameter, MQTT-Listener, Komponentenversionen und noch nicht implementierte CLI-Funktionen, bleiben offen und werden im jeweiligen Paket gesondert festgelegt und freigegeben. Die normale Installation deaktiviert Desktop/GDM nicht automatisch und führt keinen automatischen Reboot aus; ein optionaler Headless-Betrieb braucht später eine gesonderte Entscheidung und Tests. Paket A ist nach der berichteten Neustartabnahme auf beiden Plattformen abgeschlossen; damit kann B vorbereitet werden. B–F sind weiterhin nicht implementiert. Dieser Schritt dokumentiert ausschließlich den Abschluss; Installer-Code und Gatewayzustand bleiben unverändert.

## Übergeordnetes Integrationsziel, separater Auftrag

Der spätere IgH-/EC100-Datenpfad nach [Issue #12](https://github.com/pyroelectronic/FRIEDRICH-AUTOMATION/issues/12) bleibt maßgeblich (`codex/02_IGH_EC100.md`). IgH und EtherCAT werden in der aktuellen Installerphase nicht implementiert oder vorbereitet. Der Installer-Teilstand erfüllt die dortige Gesamtabnahme noch nicht.

## Danach, noch nicht aktiv

- Installerumfang und Extension-Integration werden ausschließlich im Installationskonzept geplant; hier keine zweite Aufgabenliste dazu.
- [ ] Studentenvorlagen in Module/Examples/Templates überführen.
- [ ] AI8200-Server-Baseline definieren.
- [ ] Kundenspezifische Sicherheit, Restore und langfristige Upgrade-Strategie.

**Nicht heute:** JetPack-Migration, gesamtes SDK bauen, Git-Reorganisation vorhandener Produkt-Repos, Live-Flash ohne Recovery.

Das zentrale Management-Repo mit Issues bleibt **einzige Aufgabenquelle**. Diese Datei ist nur ein technischer Wegweiser; keine doppelte Tagesplanung.
