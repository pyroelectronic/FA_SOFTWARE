# FA Gateway – Quellenkorrektur: AI7020-BSP-Build/Flash (04.11.2026)

**Status:** Ergänzung zum Arbeitsstand; statische Dateiprüfung und historischer Konsolenmitschnitt, **kein neuer Build/Flash/Hardwaretest**.

## 1. Zwei unterschiedliche Installationsphasen nicht verwechseln

1. `AI7020_install_config`, Header `ONLY FOR AI7020 SYSTEMS`, Version 1.2.0: **manuelle BSP-/RootFS-/Kernel-/Flash-Arbeitsanleitung**, kein automatisch ausführbares Shell-Installationsskript. Beschreibt Kernelkonfiguration, ROOTFS, Image/Module, DTBs, `apply_binaries.sh`, BCT/Pinmux und Flash mit SDK Manager oder CLI.
2. `AI7XX0.sh`, Header Version 1.3 (älteres vom Nutzer eingereichtes Dokument): **separates nachgelagertes Gateway-Software-Provisionierungsskript**. Der neue Build-Leitfaden referenziert in Schritt 5 am Ende ebenfalls `AI7XX0.sh`, was nicht beweist, dass die zuvor hochgeladene Version 1.3 die aktuelle/ausgeführte Fassung ist. Den Stand getrennt klären; alte Analyse von `AI7XX0.sh` nicht als Audit des neuen BSP-Ablaufs ausgeben.
3. `Copy of the console from AI7020_install_config`: **historische Konsole vom Build-Host**, mit nachgewiesenen Kernel-/Modul- und `apply_binaries.sh`-Ausgaben. Sie zeigt **keinen vollständig dokumentierten Flashvorgang** und keinen Live-Boot/Hardwaretest.

**Geräte-/Release-Abgrenzung:** Das neue Dokument ist ausdrücklich **AI7020**, nutzt Pfade `JetPack_6.1_Linux_JETSON_ORIN_NANO_4GB`, R36.4.0 und einen CLI-Aufruf mit `jetson-orin-nano-devkit`. Das zuvor entworfene generische `BUILD_FLASH_GUIDE.md` beschreibt hingegen überwiegend das Orin-NX-/AI7XX0-Szenario. Beide Stände dürfen nicht ungeprüft als identisch behandelt werden. Welches FA-Carrier-Board und welche Board-Konfiguration im CLI-/GUI-Flash tatsächlich aktiv waren, ist damit noch nicht belegt.

## 2. Direkt belegbare Konsolenbefunde

| Befund | Beleg im eingereichten Konsolenmitschnitt | Grenzen |
|---|---|---|
| Kernel `5.15.148-tegra` | Modulinstallationen unter `/lib/modules/5.15.148-tegra`; NVIDIA-R36.4.0-Paketkennung im `apply_binaries.sh`-Protokoll | Kein Live-`uname` des geflashten Geräts |
| `lan743x.ko` gebaut | Zeile 116 (`LD [M]`) | Belegt `m` für **diesen Build**, nicht Ursache von früherem `=y`-Problem |
| `lan743x.ko` in RootFS installiert | Zeilen 1081–1082 (Kernelmodul), 2427 und 2434 (zusätzlich `updates/.../lan743x.ko`) | Zwei Kopien/Pfade vorhanden: effektive Ladepriorität und finaler RootFS-Stand nicht allein belegt |
| Kernel-/In-Tree-Module | Zeile 2004: „installed successfully“ | Keine Aussage über geflashte Installation |
| NVIDIA-OOT-Module | Ab Zeile 2272 `make modules_install`, umfangreiche INSTALL/SIGN-Ausgaben | Einzelne endgültige Modulwahl nicht überprüft |
| NVIDIA-Binärintegration | Ab Zeile 2659 `sudo ./apply_binaries.sh`, Zeile 2886 „completed“, Zeile 2889 „Success!“ | Nach `apply_binaries.sh` kein erneuter Flash-/Hardwaretest gezeigt |

In der Log-Datei sind keine offensichtlichen `FAILED`-/Fehlerabschlussmeldungen enthalten; das ist **kein** vollständiger Funktionstest.

## 3. Widersprüche und konkrete Dokumentationsfragen

- **LAN743X:** Die neue AI7020-Anleitung behauptet in Zeilen 81–90 ausdrücklich, `CONFIG_LAN743X=y` sei zwingend. Die Konsole zeigt `lan743x.ko` als Modul (Zeile 116). Die bereits zuvor eingereichten Vergleichsdateien und Nutzererfahrungen deuten auf `m` als funktionierenden Stand. **Nicht stillschweigend umschreiben:** als historischen Widerspruch markieren und im Leitfaden sauber auflösen.
- **Installationsreihenfolge:** Im Konsolenmitschnitt wurden Kernel-/In-Tree-Module und OOT-Module ins Flash-RootFS installiert, **danach** wurde `apply_binaries.sh` ausgeführt. Die AI7020-Anleitung warnt selbst (Zeile 182) vor möglichem Überschreiben und sieht ggf. erneute Modulinstallation vor (Zeile 196). Prüfen, welche Reihenfolge für die Zukunft eindeutig und sicher dokumentiert werden soll; die tatsächliche historische Reihenfolge darf nicht als automatisch identisch mit einem Soll-Ablauf dargestellt werden.
- **DTBs, Pinmux, BCT:** In der AI7020-Anleitung beschrieben (Zeilen 169–220); im bereitgestellten Konsolenmitschnitt kein vollständiger, eigenständiger Nachweis für die endgültige gewählte/übertragene Board-Konfiguration. Keine erfundenen `DTB_FILE`-/Overlay-Werte ergänzen.
- **Zielgerät / Benutzername:** Die Anleitung nennt AI7020 / Nano 4GB, aber der beispielhafte `l4t_create_default_user.sh`-Befehl benennt einen `ai7100-...`-Benutzer. **Nur klären, ob historischer Beispielwert oder tatsächlich ausgeführt.** In der Version fürs Repository wurde das darin enthaltene Klartextpasswort entfernt.
- **Befehlsart:** Die Datei enthält ausführbare Shell-Befehle, ist aber **keine ausführbare Shell-Datei**. Unter keinen Umständen als komplettes Skript starten.
- **Bereits bestehendes BSP-Handbuch:** `platform/gateway/bsp/r36.4.0/BUILD_FLASH_GUIDE.md` aus einem früheren Arbeitsstand ist ein **Entwurf vor Eingang dieser neuen, genaueren Quellen**. Neue Quellen haben für die Rekonstruktion des historischen Ablaufs Vorrang; mögliche Korrekturen erst vorschlagen, danach mit dem Entwickler entscheiden.

## 4. Daten und Ablage

- Sanitisierte lesbare Kopie für Git: `platform/gateway/bsp/r36.4.0/references/AI7020_install_config_REFERENCE_REDACTED.txt`.
- Historischen Konsolenmitschnitt **lokal** für Codex bereitstellen: `local-assets/gateway/AI7020_build_console.txt` (`local-assets/` ist durch `.gitignore` ausgeschlossen). Nicht erforderlich, die große Rohkonsole im Git-Hauptstand abzulegen.
- Älteres `AI7XX0.sh` vorerst nur als Legacy-Provisionierungsreferenz einordnen; keine Annahme, dass dies die tatsächlich verwendete neueste Runtime-Installation ist.
- Originaldateien nicht überschreiben; Passwörter/Schlüssel nicht in Git übernehmen.

### Prüfsummen der Nutzeruploads (Quelle, kein Release-Hash)

- `AI7020_install_config` SHA-256: `101f19ec7d09ff44191403301268f674e0e8b7d05c85b00e33594fc3b893d07d`
- `Copy of the console from AI7020_install_config` SHA-256: `feb0dfb0ef0a9c22f5042ee75d03c0ba591b8b8260e22e164cc00e6834df0114`

## 5. Nächste Entscheidung

Zuerst die Quellenzuordnung im vorhandenen BSP-Handbuch korrigieren – **keine neue BSP-Entwicklung**. Danach erst entscheiden, ob (und welche) Automatisierung an der erprobten Entwicklungs-/Flash-Kette sinnvoll ist. Die schon geplante IgH-/EC100-Integration bleibt eigenständiger Hauptstrang (Management-Issue #12).
