# Gateway BSP – Jetson Linux R36.4.0 (historischer Referenzstand)

## Zweck

Hier wird **zunächst nur** der bereits erprobte manuelle Build- und Flash-Ablauf untersucht. Eine vollständige, reproduzierbare und hardwaregeprüfte Baseline ist noch nicht freigegeben.

## Quellen

- `references/Kernel_dtb_rootfs_Building_r36.4.txt`: historische Arbeitsanleitung, **kein ausführbares Skript** und keine automatisch verifizierte Build-Vorschrift.
- NVIDIA Jetson Linux R36.4: https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/Kernel/KernelCustomization.html
- NVIDIA RootFS: https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/RootFileSystem.html
- NVIDIA Flashing: https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/FlashingSupport.html

Die NVIDIA-Originalpakete, Build-Bäume, Toolchain und fertige Images liegen außerhalb des Git-Repositories. Für künftige Builds müssen konkrete Release-Tags, Patches, Konfigurationen, SHA-256 und Ergebnisse erfasst werden. Die tatsächlichen Unterschiede zwischen Original- und FA-Dateien sind noch nicht vollständig bereitgestellt oder geprüft.

## Grenze

Keine Änderungen an Originalquellen, keinem laufenden Gateway, keinem SDK-Manager-Verzeichnis. Kein Build/Flash ohne separaten freigegebenen Auftrag. Sichere Bootkette, RootFS-Redundanz und Produktionsflashing sind spätere Themen.

Arbeitsauftrag: `codex/05_GATEWAY_BSP_ABGLEICH.md`.
