# FA_SOFTWARE — zentraler technischer Arbeitsstand

**Stand:** 2026-11-11 · **Status:** Paket A des Gateway-Installers auf beiden Plattformen hardwareseitig abgenommen; weiterer Installerumfang in Entwicklung.

**Arbeitsrepository:** `pyroelectronic/FA_SOFTWARE`.

**Projektsteuerung:** [`pyroelectronic/FRIEDRICH-AUTOMATION`](https://github.com/pyroelectronic/FRIEDRICH-AUTOMATION), insbesondere [Issue #12](https://github.com/pyroelectronic/FRIEDRICH-AUTOMATION/issues/12).

## START HIER

1. Zuerst `AGENTS.md` und `ARCHITECTURE.md` lesen.
2. Für Zielumfang, Profile und Pakete A–F das [Gateway-Installationskonzept](platform/gateway/provisioning/INSTALLATIONSKONZEPT.md) lesen. Übergeordnete Architektur und Fahrplan sind freigegeben; ausdrücklich offene technische Detailentscheidungen werden im jeweiligen Paket gesondert festgelegt und freigegeben.
3. Den tatsächlichen Stand in [PROJEKTSTATUS.md](docs/PROJEKTSTATUS.md) und die aktuelle Bedienung in der [Provisionierungsanleitung](platform/gateway/provisioning/README.md) prüfen.
4. Historische Analysegrundlagen bleiben unter `codex/01_GATEWAY_BESTAND.md` und `references/legacy-gateway/` erhalten. Fehlende Originale separat geschützt bereitstellen; keine Credentials, Originalarchive oder großen Buildbäume hinzufügen.
5. Je einen gesondert freigegebenen Umsetzungsauftrag innerhalb des ausgewählten Pakets bearbeiten und lokal prüfen; erforderliche Detailentscheidungen vorher festlegen. Johannes führt Hardwaretests, Git-Commits und Veröffentlichung durch.

**Aktueller Stand:** Das übergeordnete Installationskonzept ist freigegeben. Johannes hat Paket A am 11.11.2026 mit dem vollständigen Gateway-Neustarttest auf beiden Plattformen erfolgreich abgeschlossen. Paket B – BSP-Schutz und Hostvoraussetzungen – kann nun vorbereitet werden; seine offenen Detailentscheidungen bleiben gesondert freizugeben. Der spätere IgH-/EC100-Datenpfad bleibt das übergeordnete Integrationsziel von Issue #12 und wird in dieser Installerphase nicht implementiert oder vorbereitet. Das Friedrich-BSP wird separat entwickelt und vor der Softwareinstallation geflasht.

## Ordner und Zuständigkeiten

| Ordner | Zweck |
|---|---|
| `platform/gateway/` | BSP-/Flash-Referenzen, Host-Provisionierung, später getrennte native Dienste; aktive BSP-Entwicklung im eigenen Repository |
| `platform/server/` | Später definierter AI8200/x86_64-Basisstand |
| `runtime/` | Optionale, getestete Dienste und Laufzeitprofile, Docker-/Compose-Rezepte |
| `sdk/` | Bewährte Module, Bibliotheken, Beispiele, Projektvorlagen |
| `devtools/` | FA VS-Code-Extension und andere Entwicklungswerkzeuge |
| `applications/` | Labor-, Demonstrator- und Kundenanwendungen (bei Bedarf separate Repos) |
| `deploy/` | Gemeinsame Deployment-, Versions-, Backup- und Recovery-Regeln |
| `docs/` | Architektur, Baselines, externe Artefakte und offene Eingaben |
| `codex/` | Kleine, abgegrenzte technische Aufträge und Berichtsvorlage |
| `references/` | Sanitisiertes, **nicht ausführbares** Lesematerial zum historischen Gateway-Installer; Originale bleiben separat |

Diese Ordner sind **logische Grenzen** und noch keine Pflicht, Komponenten bereits zu installieren. Ein funktionierendes Altprojekt wird nicht ohne eigenes Migrations-/Testvorhaben hierher verschoben.

## Verbindliche Grundsätze

- **Reproduzierbarkeit statt Perfektion:** Quellbasis + eigene Änderungen + Versionsstände + Build/Flash/Installationsschritte + Testnachweise + Rollback.
- **Quelle der Wahrheit:** Management-Repo für Gesamtentscheidungen und Issues; dieses Repository für technische Softwareimplementierung; produktspezifische Repos haben für ihre eigenen Spezifikationen Vorrang.
- **Baselines bleiben erhalten:** Funktionierende Stände niemals in-place überschreiben; neue Versionen werden abgeleitet.
- **Keine große Universalinstallation:** Betriebssystem und notwendige Host-Dienste bilden die Basis; Node-RED, Mosquitto, Python-KI, Datenbanken und Web-Oberflächen werden nach Bedarf installiert.
- **Keine Dockerpflicht:** IgH/harte Zyklusaufgaben zunächst nativ, Anwendungen können geeignete Container verwenden; Echtzeit erst nach Messung beurteilen.
- **Keine automatische Git-Schreibaktion durch Codex.** `AGENTS.md` gilt für alle Aufträge.
- **Innovation ohne Aktionismus:** Der bestehende Ansatz ist prüfbare Baseline, keine Innovationsbremse. Codex darf und soll bessere Lösungen vorschlagen; Umsetzung und Migration erst nach expliziter Entscheidung.

## Offene technische Entscheidungen, nicht heute zu lösen

- Vollständige Extension analysieren, SSH gegenüber eigenem Agenten/Remote-Workspace abwägen; vorerst bewährten SSH-Weg behalten.
- Node-RED-Projektverzeichnisse und Push/Pull-Mechanik auf eine sichere Source-of-Truth-Regel bringen.
- Neues JetPack/Kernel-Release nur als eigene, isolierte Baseline evaluieren.
- Hardware-Sicherheit wie Secure Boot, Rootfs-Schutz und Kundenzertifikate pro späterem Anforderungsprofil planen, nicht als sofortige Standardpflicht vortäuschen.

Weiterlesen: [Installationskonzept](platform/gateway/provisioning/INSTALLATIONSKONZEPT.md), `ARCHITECTURE.md`, `docs/BASELINE_REGISTER.md` und `docs/INPUTS_OFFEN.md`.
