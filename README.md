# FA_SOFTWARE — zentraler technischer Arbeitsstand

**Stand:** 2026-11-04 · **Status:** beschlossene Arbeitsstruktur; keine Software-/Hardwarefreigabe.  
**Geplantes privates Repository:** `pyroelectronic/FA_SOFTWARE` (noch anzulegen).  
**Projektsteuerung:** [`pyroelectronic/FRIEDRICH-AUTOMATION`](https://github.com/pyroelectronic/FRIEDRICH-AUTOMATION), insbesondere [Issue #12](https://github.com/pyroelectronic/FRIEDRICH-AUTOMATION/issues/12).

## START HIER

1. Ordner `FA_SOFTWARE/` in ein **neues privates** Git-Repository übernehmen. Keine Originalarchive, Credentials, kompilierten NVIDIA-Bäume oder Binärimages hinzufügen.
2. Codex dieses Repository öffnen lassen. Zuerst `AGENTS.md` und `ARCHITECTURE.md` lesen.
3. Als **ersten Auftrag** `codex/01_GATEWAY_BESTAND.md` geben: lesende Analyse der Gateway-Basis und des Installationsskripts; keine Flash-/Installationsaktionen. Eine **bereinigte, ausdrücklich nicht ausführbare Referenzkopie** des historischen Installers liegt unter `references/legacy-gateway/`.
4. Fehlende Referenzquellen **separat** und mit Zugriffsschutz bereitstellen; `docs/INPUTS_OFFEN.md` nutzen. Die Quellen bleiben auch nach der Analyse als historische Baselines erhalten.
5. Nach dem Bericht **genau einen kleinen Umsetzungsschritt** vereinbaren, bauen, lokal testen, Teststand nachweisen; Git-Commit/Tag erledigt Johannes.

**Sofortiger technischer Hauptstrang:** IgH → EC100 OP → reale PDO-Werte → kleiner Dienst → Anzeige/Server, entsprechend Issue #12. Die Bestandsaufnahme des OS ist ein vorbereitender Teil und darf den Datenpfad nicht durch einen vollständigen BSP-Neubau blockieren.

## Ordner und Zuständigkeiten

| Ordner | Zweck |
|---|---|
| `platform/gateway/` | Jetson Linux / BSP, Treiber, Flashen, Host-Provisionierung, native IgH-Integration |
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

Weiterlesen: `ARCHITECTURE.md`, `docs/BASELINE_REGISTER.md`, `docs/INPUTS_OFFEN.md` und `codex/01_GATEWAY_BESTAND.md`.
