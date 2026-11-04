# Referenzstandregister — noch keine Freigabe

| ID | Plattform | Nachweis/Quelle | Status |
|---|---|---|---|
| `GW-LEGACY-2026-11` | AI7020/AI7100, Jetson | `AI7XX0.sh`, `ai7XX0_install_config_V1.0_36.4.3_V6.1.7z`, frühere NVIDIA-Buildordner | **Referenzmaterial, Version/Hardware noch zu verifizieren; sanitisierte Installer-Lesekopie im Repository** |
| `EXT-REF-0.4.2` | VS-Code-Extension | `src.zip`, `out.zip`, `CHANGELOG(1).md` | **Teilquellen, kein vollständiges Build-/Releasepaket** |
| `SDK-STUDENT` | Projektbeispiele | `Projektvorlagen.zip`, `Docker.zip` | **Referenzimplementierungen, nicht freigegeben als SDK** |

**Beachtung:** 36.4.3 im Archivnamen und 6.1 im selben Namen sind nicht automatisch eine bestätigte offizielle JetPack-/Jetson-Linux-Kombination. Tatsächlich laufenden Stand und Build-Basis am Gerät/Build-Host prüfen. Keine automatische Festlegung auf JetPack 7.

## Für jede neue Freigabe erfassen
- Hardware, Carrierboard, Jetson-Modul, Bootmedium, Netzwerkinterfaces
- Jetson Linux, JetPack, Kernel, NVIDIA-Runtime, CUDA, Container Runtime
- BSP-/Patch-Commit, Build-Werkzeuge, Konfigurationsdateien, Flashweg (GUI/CLI)
- Paket-/Image-Stände mit Hashes (nicht `latest`)
- Prüfprotokoll (Boot, LAN7430, SSH, NVIDIA-GPU, IgH/EC100, Neustart, Logs)
- Backup/Rollback und erlaubte Updatewege

Keine Tests als bestanden kennzeichnen, die nur dokumentiert oder vom Nutzer behauptet wurden, ohne zugehöriges nachvollziehbares Testprotokoll.
