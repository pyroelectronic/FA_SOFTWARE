# Noch benötigte Eingaben (kein Blocker für die Struktur)

Die bisherige Analyse basiert auf **Teilquellen**. Nicht vorliegende Dateien dürfen nicht erfunden werden.

| Priorität | Benötigt | Wofür? | Schon bekannt |
|---|---|---|---|
| 1 | Tatsächlich verwendete Jetson-/Carrier-Board-Version, laufendes L4T-/JetPack-Release, Kernelversion, Version des LAN7430-Treibers | Unterscheidung von Datei-/Build-/Live-Baseline | Archivname `ai7XX0_install_config_V1.0_36.4.3_V6.1.7z`, jedoch nicht als Live-Stand verifiziert |
| 1 | Vollständiger Linux_for_Tegra-Buildbaum **oder besser** originaler NVIDIA-Release + eigene Patches/Konfigurationen und Build-/Flash-Protokoll | Reproduktion des Flash-Stands | Teilarchiv, Markdown-Bauanleitungen |
| 1 | Vollständige Installer-Quellen samt lokaler `.deb`/`.whl`-Abhängigkeitsliste (nicht unbedingt die großen Binaries) | Runtime-/APT-/Python-Prüfung | Original `AI7XX0.sh` wurde bereitgestellt, enthält historische Zugangsdaten; **sanitisierte Lesekopie im Repo** |
| 1 | Ausgabe von read-only Geräteprüfungen und erfolgreichem IgH-/EC100-Test | Issue #12 | bislang nicht nachgewiesen |
| 2 | Vollständiges VS-Code-Extension-Projekt mit `package.json`, `tsconfig.json`, Ressourcen sowie verfügbarem Teststand | Extension bewerten und bauen | `src.zip`, `out.zip`, Changelog 0.4.2 sind nur Teile |
| 2 | Aktive Node-RED-Projekt-Konfiguration, `.git`-/Flow-Pfade, zwei Synchronisations-Szenarien (Push/Pull) | Single source of truth für Flows | Projekt-/Workspace-Pfade bekannt, Verhalten noch zu verifizieren |
| 3 | Stand AI8200 Ubuntu, GPU-Treiber und Server-Profile | Eigene Server-Baseline | Zielarchitektur bekannt |
| 3 | Originalstudenten-Referenz mit Lizenz/Herkunft und Prüfstatus | SDK-Sichtung | `Projektvorlagen.zip`, `Docker.zip` |

## Schon jetzt möglich

- Struktur in privatem Repository bereitstellen.
- Codex die **vorhandene sanitisierte Installer-Referenz** bereits nur lesend untersuchen lassen; echte BSP-/Live-Aussagen erst nach Übergabe der zugehörigen Quellen treffen.
- Den nächsten minimalen IgH-/EC100-Schritt nach Issue #12 abgrenzen, ohne kompletten BSP-Neubau.

## Bei Originaldateien beachten

- Originale zuerst außerhalb des Repositories sichern (Hash + sicherer Ablageort).
- Nicht alle mehrere Gigabyte großen NVIDIA-Bäume ungeprüft zu Git hinzufügen.
- Secrets in alten Skripten vor Import isolieren und künftig durch Konfiguration/Provisionierung ersetzen; nicht den historischen Beweisstand überschreiben.
