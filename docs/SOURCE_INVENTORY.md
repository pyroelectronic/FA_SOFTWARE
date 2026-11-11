# Input-/Referenzinventar (keine Originale im ZIP)

Diese Quellen wurden in dieser Unterhaltung zur Analyse bereitgestellt; **Originaldateien wurden nicht ins Entwicklungs-Startpaket kopiert.**

Das Inventar beschreibt den historischen Eingang. Neuere Gateway-Hardwaremeldungen stehen in [PROJEKTSTATUS.md](PROJEKTSTATUS.md), der aktuelle technische Installerplan im [Installationskonzept](../platform/gateway/provisioning/INSTALLATIONSKONZEPT.md). Eine damalige offene Livebaseline ist von den inzwischen berichteten Tests zu unterscheiden.

| Typ | Dateiname | SHA-256 | Größe |
|---|---|---|---:|
| VS-Code Quelle Teilbestand | `src.zip` | `c6c2b6d1711a830e3d59612b12b5e3aac826230fbf3a3ad635c20ef474ad0001` | 5,716 Bytes |
| Extension JS Build-Ausgabe | `out.zip` | `34d32fc0807fc492eecc7bf06c39f7cad4e8737566df0243a10488268ec8ba84` | 19,333 Bytes |
| Extension Änderungsverlauf | `CHANGELOG(1).md` | `1a88c0c76d3238731cf11d8cad3313f39dc2287c62f03dc459018bb94624cdee` | 3,158 Bytes |
| AI7XX0 Installer Referenz | `AI7XX0.sh` | `2929cbe2bae9da65799d999df5e175cabc957d64564ab1d8ce4bbaef0a7969ee` | 20,371 Bytes |
| L4T/BSP Legacy Archiv | `ai7XX0_install_config_V1.0_36.4.3_V6.1.7z` | `761266823c7fb029595a8034c1c8bdcd7e90e14ed316141ec4aac2e0b957dcfd` | 3,914,436 Bytes |
| Studenten Projektvorlagen | `Projektvorlagen.zip` | `d62b6b9b244e741dca81c4610b5613b296c391feede9d19a276c9955cbbda023` | 2,876,010 Bytes |
| Studenten Docker Archiv | `Docker.zip` | `f9e8a261c6b7e1d25b112e1754051ffa2c6c1f8f4096078dc8990f30a7820c4c` | 759,999 Bytes |

Die Prüfsummen identifizieren nur die hier vorhandenen Uploads; sie beweisen keine Betriebssicherheit. Vor Weitergabe von Legacy-Dateien Geheimnisse, Lizenzen und Versionsstände prüfen.

Für Codex fehlt noch ein **vollständiges** VS-Code-Extension-Projekt (`package.json`, `tsconfig.json`, sonstige Ressourcen/Settings) und ein belegter Ist-Stand des tatsächlich verwendeten Jetson-Gateways.

## Bereinigte Quellen im Start-Repository

- `references/legacy-gateway/AI7XX0_REFERENCE_REDACTED.txt`: nicht ausführbare, sanitisierte **Lesekopie** des historischen Installers; Original-Hash oben/Manifest.
- `references/legacy-gateway/CHANGELOG_REFERENCE.md` und `torchtest_REFERENCE.py`: kleine historische Begleitdateien.

Das Archiv mit Linux-for-Tegra-BSP-Anpassungen und die vollständige Extension verbleiben als externe Referenz. Die Lesekopie ist **kein** reproduzierbarer Installer und kein Hardware-Testnachweis.
