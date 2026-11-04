# Gateway-Plattform (AI7xx0 / Jetson)

**Ziel:** Basis-OS reproduzierbar flashen und konfigurieren, Hardwarezugriff verifizieren, danach native IgH-/EC100-Funktionen bereitstellen. Kein implizites Installieren der gesamten KI-/Laborsoftware.

- `bsp/`: Quellrelease, eigene Kernel-/Treiber-/Pinmux-/Boot-Anpassungen; Flash (GUI/CLI), Nachweise.
- `provisioning/`: schlanke, wiederholbare Host-Konfiguration; Geheimnisse separat.
- `host-services/`: notwendige native Dienste wie IgH/EC100.

Aktueller Legacy-Stand nur in `docs/BASELINE_REGISTER.md` verzeichnet; noch **kein** neuer Installer und keine getestete Release-Baseline hier enthalten. Erst `codex/01_GATEWAY_BESTAND.md` ausführen.
