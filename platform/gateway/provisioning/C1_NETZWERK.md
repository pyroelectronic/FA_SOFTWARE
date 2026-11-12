# C1 – Beide vorhandenen Ethernetprofile dauerhaft per MAC binden

Stand 12.11.2026. `c1-install` ordnet die beiden vorhandenen normalen Ethernetprofile eindeutig den permanenten Hardware-MACs zu. LAN1 ist Verwaltung, LAN2 bleibt normal IP-fähig. C1 konfiguriert weder LAN2 für EtherCAT noch USB, Firewall, Docker oder IP-Adressen. Paket A/Node-RED/B2 bleiben erhalten.

## Umfang und Grenzen

Der vorhandene Python-Stdlib-Helper erkennt je einen physischen `r8168`- und `lan743x`-Port über Treiber und `ethtool -P`. Das Profil muss eindeutig per MAC, aktuellem Interfacenamen oder bestehender aktiver Zuordnung passen. Mehrdeutige/widersprüchliche Profile oder konkurrierende Autoprofile blockieren; keine festen `Wired connection`-Namen und kein neues Profil auf Verdacht.

Nur diese gespeicherten Felder werden geändert:

- `802-3-ethernet.mac-address`: permanente MAC des zugehörigen Ports.
- `connection.interface-name` und `match.interface-name`: leeren.

Beide UUIDs, Autoconnect, verwendete/geklonte MAC und sämtliche IPv4-/IPv6-/DHCP-/Gateway-/DNS-/Routeneinstellungen bleiben erhalten; statisches IPv4 und fehlende Default sind zulässig. `match.path`, `match.driver` und `match.kernel-command-line` bleiben unberührt. Kein normales Up/Down/Reapply oder Konfigurationsreload, keine Unmanaged-Regel und keine neue Rollen-/Transaktionsregistry.

`c1-install` endet mit Exit `0`, wenn beide Bindungen korrekt sind, auch bei unverändertem Wiederholungslauf; Fehler ergeben Exit `1`. `c1-status` prüft nur lesend: Exit `0` für korrekte Bindungen, `1` bei fehlender Bindung/Fehler; keine Verzeichnisse, Locks oder Backups anlegen. Es gibt keine neue Bestätigungsphase oder automatische Rücknahme bei Teilfehlern.

## Falls ein Altzustand die Installation blockiert

Der letzte Hardwareversuch verwendete den alten Transaktionsstand `fdc6522353f89699`. Sein tatsächlicher Status ist **unbekannt**; Codex hat ihn nicht auf dem Gateway gelesen. Offene oder inkonsistente Altzustände blockieren den neuen Aufruf. Ist dieser bekannte Altzustand die Ursache, führt Johannes über USB oder eine echte Konsole den zugehörigen eingefrorenen Helper aus:

```bash
sudo /usr/bin/python3 -I -B /var/lib/friedrich/c1/fdc6522353f89699/worker.py rollback-manual fdc6522353f89699
```

Ausgabe und Exit prüfen, weitere Fehler nicht ignorieren. Danach muss der alte Pending-Marker weg und der zugehörige Zustand terminal sein. Der neue Helper blockiert weiterhin bei Pending, offenen/unvollständigen/widersprüchlichen Altzuständen oder vorhandener alter LAN2-Unmanaged-Datei; er räumt diese nicht selbst auf. Bei Blockade den gemeldeten Altzustand mit dessen Helper/Sicherung untersuchen. Keine Zustandsdateien, Sicherungen oder Konfigurationen pauschal löschen. Ein alter bereits bestätigter Callback ist im Vorgänger ein No-op; daraus folgt kein bekannter Status dieses Hardwareversuchs.

## Einmalbackup und manueller Rückfall

Vor dem ersten ändernden Lauf werden beide gespeicherten Original-Keyfiles unter `/etc/NetworkManager/system-connections` gesichert. Es sind zwei reguläre persistente, root-private Dateien erforderlich. Sicherungsort:

```text
/var/lib/friedrich/c1/profile-backup/manifest.json
/var/lib/friedrich/c1/profile-backup/profile-1.nmconnection
/var/lib/friedrich/c1/profile-backup/profile-2.nmconnection
```

Verzeichnis root-eigen/`0700`, Sicherungsdateien root-eigen/`0600`. Das Manifest enthält pro Profil Rolle, UUID, MAC, exakten Originalpfad (`path`), Sicherungsdatei (`file`), SHA-256, UID, GID und ursprünglichen Modus als Oktaltext, etwa `0600`. Ein vorhandenes Backup wird vor weiteren Änderungen auf Identität/Pfade und Hashes geprüft und nie überschrieben. Ein bereits korrekter No-op legt kein neues Backup an. Private Dateien nicht teilen oder ins Repository kopieren.

Bei Teilfehler oder Abbruch gibt es **keinen automatischen Rollback**. Beide Originale über funktionierendes USB-SSH oder Konsole gezielt wiederherstellen. Zuerst lokal Manifest und Prüfsummen ansehen:

```bash
sudo cat /var/lib/friedrich/c1/profile-backup/manifest.json
sudo sha256sum /var/lib/friedrich/c1/profile-backup/profile-1.nmconnection /var/lib/friedrich/c1/profile-backup/profile-2.nmconnection
```

Hashwerte mit `sha256` vergleichen. Die folgenden Platzhalter exakt aus dem jeweiligen Manifest-Eintrag ersetzen, den Modus im dortigen Oktalformat belassen:

```bash
sudo install -o '<UID_1>' -g '<GID_1>' -m '<MODE_1>' /var/lib/friedrich/c1/profile-backup/profile-1.nmconnection '<ORIGINALPFAD_1_AUS_MANIFEST>'
sudo install -o '<UID_2>' -g '<GID_2>' -m '<MODE_2>' /var/lib/friedrich/c1/profile-backup/profile-2.nmconnection '<ORIGINALPFAD_2_AUS_MANIFEST>'
sudo nmcli connection load '<ORIGINALPFAD_1_AUS_MANIFEST>' '<ORIGINALPFAD_2_AUS_MANIFEST>'
```

Keine globalen Restores, USB-Änderungen oder Up/Down-Befehle. Das Laden stellt die gespeicherten Profile bereit; ihre Wirkung bei zukünftiger Aktivierung und die tatsächliche Erreichbarkeit getrennt prüfen. Bei beschädigtem Backup oder fehlendem Linux/USB/SSH ist dieser Weg nicht ausreichend. USB ist keine Boot-/Debug-Konsole.

## Kontrollierter Hardwaretest durch Johannes

Johannes berichtet USB-Ping, -SSH und Kaltstart ohne LAN1 auf beiden Geräten erfolgreich; Dienst `nv-l4t-usb-device-mode.service`, `l4tbr0` und `192.168.55.1/24` bleiben unverändert. Das ist keine C1-Abnahme. Der frühere AI7100-Abbruch wegen Profilmehrdeutigkeit betraf zwei namensgebundene Normalprofile und statisches LAN1 ohne Gateway; private IP-/MAC-Werte bleiben lokal.

AI7100-3 einzeln über USB testen, bei einer Altzustandsblockade zunächst wie oben vorgehen. Aus der Repository-Wurzel:

```bash
sudo bash platform/gateway/provisioning/install.sh c1-install
sudo bash platform/gateway/provisioning/install.sh c1-status
```

Erwartet jeweils Exit `0`. Die vorhandenen beiden Profil-UUIDs lokal ermitteln und vor/nach C1 sowie nach Boot vergleichen:

```bash
nmcli -f UUID,TYPE,DEVICE connection show
LAN1_UUID='<VORHANDENE_LAN1_UUID>'
LAN2_UUID='<VORHANDENE_LAN2_UUID>'
for PROFILE_UUID in "$LAN1_UUID" "$LAN2_UUID"; do
    nmcli -f connection.uuid,connection.interface-name,connection.autoconnect,802-3-ethernet.mac-address,802-3-ethernet.cloned-mac-address,match,ipv4,ipv6 connection show uuid "$PROFILE_UUID"
done
ip -br address
ip -4 route show default
ip -6 route show default
```

Nur die drei genannten Bindungsfelder dürfen sich ändern; alle übrigen Werte/UUIDs bleiben erhalten. Leere Default-Ausgabe ist kein Fehler. Neue normale USB-/LAN1-SSH-Verbindungen zur bestehenden LAN1-IPv4 testen, statisch oder DHCP. LAN2 bleibt im normalen Netz nutzbar; Node-RED-Tunnel, `FLOW1` und Dockerfunktionen prüfen. Erneuter `c1-install` muss Exit `0` ohne neue Profile/Backupänderung liefern.

Danach startet Johannes manuell neu und wiederholt denselben C1-Aufruf und die Lese-/Erreichbarkeitsprüfungen:

```bash
sudo reboot
# Nach erneuter Anmeldung in der Repository-Wurzel:
sudo bash platform/gateway/provisioning/install.sh c1-install
sudo bash platform/gateway/provisioning/install.sh c1-status
```

Erst bei erfolgreichem AI7100-Test folgt AI7020-8. Codex führt keine Gatewayaktionen aus. `C1_IN_LAB_APPROVED=no` bleibt bis zur Hardware-/Neustartabnahme beider Geräte gesetzt; später verwendet der Laborpfad denselben Bindungscode über diesen Schalter.

## Prüfnachweis und Abnahme

Am 12.11.2026 **31 gezielte Tests bestanden**: 13 für Erkennung/Profilwahl/native Quellen/Altzustände und 18 für Installation, unveränderte Konfiguration, Originalsicherung und Wiederholung. Die alten Transaktions-/SSH-/Checkpointtests wurden ersetzt beziehungsweise entfernt.

```bash
python -B -m unittest discover -s platform/gateway/provisioning/tests -p 'test_c1*.py' -q
```

Geprüft sind eindeutige Treiber/permanente MACs, Namenswechsel, Profilkonflikte, beide UUIDs und exakt drei Schreibfelder, erhaltene IP-/DNS-/Gateway-/IPv6-/Routen-/Autoconnect-/sonstige Matchwerte, No-op ohne neue Dateien, Status ohne Lock/Verzeichnisanlage, persistente Quellen auch beim No-op, vollständige Backups vor dem ersten Modify, unveränderte Wiederverwendung und blockierende defekte Sicherungen. Ein Fehler nach dem zweiten Modify wird als Teiländerung mit manuellem Rückfall gemeldet. Offene/ungültige Altzustände und die alte Unmanaged-Datei blockieren vor Profiländerungen.

Echte Python-Abläufe und temporäre Dateien wurden ausgeführt; Linux-Rechte, NM/D-Bus und Hardwareantworten waren simuliert. Zusätzlich bestanden Python-AST, `bash -n install.sh`, Hilfetext mit Exit `0`, `git diff --check` und Dokumentlinkprüfung. Entfernt man ausschließlich die C1-Ergänzungen aus dem Installer, ergibt sich bytegenau die frühere Basis `6136b46496a5c68efc1ebf3a1f60838e004643ec790a592a5e2f59834e6098c6`: Paket A/Node-RED/B2 blieben erhalten.

Aktuelle SHA-256:

- `c1_network.py` (290 Zeilen): `c16c9a3b5ea02f1aa4c4ab05e1492e296a2a2a4974a6eff58ce0a8bf9b79b852`
- `install.sh`: `ec09120a618d7a6b31a27fd771d748742fed842f48c7c0c31900c1bcf0629275`

Ausgangsstand war der transaktionale Helfer `eab07674dcb049c1c4572aa7dd0d7bb0e86aea41bb43763386416d15fa594e94` mit Installer `65e1425a5ddb4b93da32dac03e411f260600530fba2f10dee83be6c72943983b`. Frühere große Testzahlen belegen diesen vereinfachten Stand nicht. Keine Gateway-/Git-Schreibaktionen; C1-Hardwareabnahme bleibt bis zu Wiederholung und Neustartprüfung auf beiden Geräten offen.

**Genau ein nächster Schritt:** Johannes führt den AI7100-C1-Test mit Wiederholung und manuellem Neustart durch, bei Altzustandsblockade zuerst mit der beschriebenen Bereinigung; erst bei Erfolg folgt AI7020.
