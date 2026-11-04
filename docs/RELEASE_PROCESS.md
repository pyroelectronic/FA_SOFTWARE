# Freigabe- und Reproduktionsprozess

## Baseline-Identität
Jeder freigegebene Stand hat eine eindeutige ID (Beispiele: `GW-R1-...`, `SERVER-R1-...`, `RUNTIME-LAB-...`, `APP-...`). Eine ID wird **erst nach Prüfung** vergeben. Eine Versionszeichenfolge im Dateinamen ist noch kein Testnachweis.

Pro Stand mindestens dokumentieren: Hardware-/Carrier-Revision, Upstream-Release, eigene Patchversion, benötigte externe Artefakte samt SHA-256, verwendete Build-Umgebung, Flash-/Installationsanleitung, relevante Pakete/Images, Konfiguration ohne Secrets, Tests und Rollback.

## Ablauf
1. Referenzstand erhalten und identifizieren.
2. Neue Arbeitsversion **separat** anlegen; kleinsten Änderungssatz beschreiben.
3. Statische Prüfungen/Build mit Ergebnis dokumentieren.
4. Test auf geeigneter **Testhardware** durch Johannes mit Netzwerk/Boot/GPU/IgH usw.
5. Ergebnis und bekannte Einschränkungen dokumentieren.
6. Johannes erstellt Commit/Tag/Freigabe, erst dann als installierbar deklarieren.

## Unveränderliche Betriebsdaten
Messdaten, Node-RED-Persistenz, Datenbankvolumes, Secrets und Logs nicht als flüchtigen Containerinhalt behandeln. Backup und Restore getrennt testen. `docker compose down -v` ist kein normaler Updateweg.

## Sicherheitsupdates
BSP-/Kernel-/NVIDIA-Komponenten auf Kompatibilität prüfen; keine undokumentierten Full-Upgrades und kein unbefristetes pauschales Hold ohne Update-Plan. Sicherheitskritische Fixes sind gesondert zu bewerten.
