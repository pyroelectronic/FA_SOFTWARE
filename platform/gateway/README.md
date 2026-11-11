# Gateway-Plattform (AI7xx0 / Jetson)

**Ziel:** Ein bereits mit dem Friedrich-BSP geflashtes Gateway gezielt für seinen Einsatz vorbereiten. Die aktive BSP-Entwicklung und das Flashen liegen im eigenen Entwicklungsrepository; native IgH-/EC100-Funktionen bleiben ein späterer getrennter Auftrag.

- `bsp/`: historische Quell-, Anpassungs- und Flashreferenzen sowie Nachweise; keine aktive BSP-Neuentwicklung durch den Installer.
- `provisioning/`: schlanke, wiederholbare Host-Konfiguration; Geheimnisse separat.
- `host-services/`: notwendige native Dienste wie IgH/EC100.

Der zentrale [Installer](provisioning/install.sh) ist für das Laborprofil teilweise implementiert und auf beiden Plattformen berichtet getestet. Die vollständige Gateway-Neustartabnahme steht aus. [Installationskonzept](provisioning/INSTALLATIONSKONZEPT.md), [Bedienung](provisioning/README.md) und [Projektstatus](../../docs/PROJEKTSTATUS.md) trennen Zielplan, aktuelle CLI und Nachweise. Die alte Installerkopie bleibt historische Referenz.
