# Auftrag 01 — Gateway BSP und Installation: Baseline-Feststellung

## Ziel (nur lesend)
Die **aktuell bekannte** Jetson-Basis beschreiben, damit wir künftig eine funktionierende Installation reproduzierbar bauen können, ohne den Live-Stand zu verändern.

## Eingaben
- `AI7XX0.sh` (historischer Installer), `CHANGELOG.md`.
- Archiv `ai7XX0_install_config_V1.0_36.4.3_V6.1.7z` mit BSP-/Flash-Dokumentation.
- `torchtest.py` als Beispiel für GPU-Test (Test im Auftrag nicht ausführen).
- Bei Verfügbarkeit: originale Linux_for_Tegra-Builddateien, eigene Patches, Build-/Flash-Logs, reine read-only Ist-Systeminformationen.
- Index `docs/SOURCE_INVENTORY.md` / `docs/BASELINE_REGISTER.md` / `docs/INPUTS_OFFEN.md`.

**Wichtig:** Im Start-Repository liegt unter `references/legacy-gateway/` eine **sanitisierte Lesekopie** von `AI7XX0.sh` und zugehöriger kleiner Referenzdateien, **nicht** der bytegleiche Originalstand oder das BSP-Archiv. Fehlen vollständige Quellen am Codex-Arbeitsplatz, nicht raten und keine Ersatzbasis herunterladen; fehlende Quellen melden. Keine Zugangsdaten aus Originalen wiedergeben.

## Aufgaben
1. Datei für Datei kartieren: was gehört zu Upstream-NVIDIA, was ist selbst angepasst, was ist Drittanbieter, was ist nur Bericht/Anleitung?
2. Abhängigkeiten und Reihenfolge: Original-Release → Kernel-/LAN7430-Änderungen → Flash (SDK Manager/CLI) → Host-Installer → Dienste/Docker → Prüfschritte.
3. Versionsdifferenzen (Archivname `36.4.3_V6.1`, Inhalte/README, tatsächlich laufendes Release) **ausweisen**, nicht still korrigieren.
4. Installer klassifizieren: zwingende Host-Funktion, optionales Laborprofil, projektabhängige Anwendung; insbesondere IgH, Docker, PyTorch, Mosquitto, Node-RED, Pylon, `pip`, globale Updates.
5. Risiken priorisieren: secret-bearing Skript, unpinned Images, apt upgrades/holds, nicht idempotente Schritte, System-/Reboot-/Netzwerkänderungen, Restore.
6. Maximal **einen** nächsten Mini-Umsetzungsschritt mit Test-/Rollbackkriterium vorschlagen. **Keinen** neuen Installer schreiben, bevor Basis und Ziel klar sind.
7. Wo eine konkrete bessere technische Lösung sichtbar wird: **Beibehalten / minimal verbessern / ersetzen** kurz abwägen. Unverifizierte Hypothesen markieren; keine eigenmächtige Migration.

## Verboten
Quell- oder Git-Änderung, APT/PIP/Docker-Anpassung, `sudo`, Flash, Kernelbuild, Service-Start/Stop, Reboot, Delete, externe Zugriffe mit Credentials.

## Ergebnis
Ein **Bericht** mit: verifizierten Fakten / Unbekanntem / Pipeline-Skizze / Top-5-Risiken / begründeten Verbesserungsoptionen / minimalem nächsten Schritt. Report optional als neue Markdown-Datei **nur nach ausdrücklicher Freigabe**, sonst Chat-Ausgabe. Verwende `codex/BERICHTSVORLAGE.md`.
