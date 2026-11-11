# Codex-Auftrag 05 – Konsolidierte BSP-/Carrier-Board-Prüfung R36.4.0

**Status:** Technische Bestandsprüfung, ausschließlich lesend. **Bereich:** `platform/gateway/bsp/`.  
**Ziel:** Prüfen, ob die *tatsächlich vorgenommenen* FA-Änderungen für das eigene Jetson-Orin-NX-Carrier-Board in sich stimmig sind. Potenzielle Verbesserungen gezielt benennen, den bewährten Stand aber nicht ohne Grund verändern. **Kein Rebuild-Projekt und keine neue Architektur.**

## 1. Verbindliche Projektregeln und Quellen

1. Zuerst `AGENTS.md`, `ARCHITECTURE.md` und die Bereichs-READMEs lesen. Die jeweils aktuellen Management-Vorgaben in `pyroelectronic/FRIEDRICH-AUTOMATION` gehen bei Widersprüchen vor.
2. Historische Anleitung: `platform/gateway/bsp/r36.4.0/references/Kernel_dtb_rootfs_Building_r36.4.txt` (aus dem bereits gelieferten BSP-Ergänzungspaket).
3. Referenzarchiv **`ORGINAL.zip`** mit ursprünglichen und geänderten Dateien, lokal bereitgestellt etwa unter `local-assets/bsp-r36.4.0/ORGINAL.zip` (das Verzeichnis ist laut `.gitignore` nicht für Git bestimmt). Nur prüfen, falls im Codex-Arbeitsbereich tatsächlich zugänglich. Das Wort `ORGINAL` im Dateinamen ist **kein Nachweis** für die Übereinstimmung mit dem offiziellen NVIDIA-Upstream.
4. Primärdokumentation: NVIDIA **Jetson Linux R36.4.0**:
   - https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/Kernel/KernelCustomization.html
   - https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/HR/JetsonModuleAdaptationAndBringUp/JetsonOrinNxNanoSeries.html
   - https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/RootFileSystem.html
   - https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/FlashingSupport.html
5. Ergänzend nur kurz das Vorgehensprinzip von Forecr und Seeed vergleichen (Board-/Versionsbezug kontrollieren):
   - https://www.forecr.io/blogs/installation/jetpack-6-x-installation-for-dsboard-agxmax
   - https://wiki.seeedstudio.com/reComputer_A608_Flash_System/
6. Kein aktuelles Live-Gerät und keine weiteren Uploads voraussetzen. Nicht zugängliche Dateien und nicht belegte Zusammenhänge ausdrücklich als offen kennzeichnen.

## 2. Vom Entwickler berichtete Hardware-Erfahrungen – als Kontext, nicht als formaler Testbeleg

- Selbst entwickeltes **Friedrich-Automation-Carrier-Board** für Jetson Orin NX, ausgehend vom NVIDIA-Developer-Kit-Schaltplan, jedoch mit bewusst abweichender Peripherie.
- **LAN7430:** `CONFIG_LAN743X=y` führte bei früheren Tests zu Erkennungs-/Funktionsproblemen; `CONFIG_LAN743X=m` hat praktisch funktioniert. Die in der ursprünglichen Anleitung genannte `=y`-Variante ist daher **nicht** automatisch der letzte funktionierende Stand.
- **BG95:** Eigene Treiberänderungen wurden versucht; die Integration funktionierte nach Entfernen/Deaktivieren von **ModemManager**. Den damaligen Ursache-Wirkungs-Zusammenhang nicht ohne Beleg verallgemeinern.
- **USB:** Das eigene Board hat einen einfachen USB-**Host**-Anschluss und nicht die vollständige USB-/Type-C-Hardware des Entwicklerboards. Device-Tree-Einstellungen wurden entsprechend angepasst.
- **CSI-Kameras:** Entsprechende CSI-Kamera-Hardware ist auf dem eigenen Board nicht vorgesehen; Kamera-Overlays/Knoten wurden teilweise deaktiviert.
- **Pinmux:** Konfiguration wurde mit NVIDIAs Pinmux-Spreadsheet erzeugt/angepasst; die daraus tatsächlich verwendeten generierten Dateien bzw. das Spreadsheet sind ggf. nicht im Archiv.
- **RootFS:** NVIDIA *minimal* und *basic* wurden praktisch erprobt, verursachten damals erheblichen Aufwand mit fehlenden Paketen, unter anderem Qt. Verwendet wurde deshalb bewusst ein **angepasstes Desktop-RootFS**, dessen Paketliste verkleinert wurde. Der grafische Desktop kann später im Betrieb deaktiviert werden.
- **Bewährter Ablauf:** Original-BSP/Toolchain/Quellen in separatem Entwicklungsverzeichnis → eigene Kernel-/DTB-/RootFS-Anpassungen und Build → manuelle Übergabe ausgewählter Artefakte in einen **getrennten NVIDIA-SDK-Manager-Flash-Baum** → Flashen per GUI oder CLI. Historisch in der Praxis genutzt, aber noch nicht als vollständig automatisierte Release-Kette nachgewiesen.

## 3. Nur diese fünf Themen technisch prüfen

| Thema | Konkrete Prüffrage | Ergebnisgrenze |
|---|---|---|
| **LAN743X** | Welche `defconfig`-Varianten existieren wirklich? Welche Option steht in der bearbeiteten Datei und wie ist Modulbau/-installation dokumentiert? Könnte der Unterschied `m` vs. `y` durch Quellen/Konfiguration/Initialisierungsreihenfolge erklärt werden? | **Keine Ursache erfinden.** Falls statisch nicht belegbar: `m` als berichteter Funktionsstand; Ursache offen. |
| **USB-Host / Type-C** | Sind die tatsächlich veränderten aktiven DTS/DTSI-/Overlay-Dateien konsistent mit einem einfachen USB-Host-Port ohne entsprechende Developer-Kit-Type-C-Hardware? Prüfe bei vorhandenen Dateien insbesondere Rolle, Controller, PHY/Ports, VBUS, Parent-/Child-Status und verwendete Overlays. | Ohne Schaltplan/effektiven DTB kein abschließender Hardwarebeleg. |
| **CSI-Kameras / I²C-Mux** | Welche Knoten wurden verändert/deaktiviert, und haben die Änderungen in der verwendeten DTB-/Overlay-Kette überhaupt Wirkung? Sind unbeabsichtigt gemeinsam genutzte I²C- oder andere Ressourcen betroffen? | Kein automatisches Entfernen „ungenutzter“ NVIDIA-Knoten. |
| **BG95 / ModemManager** | Welche Kerneloptionen/Userspace-Pakete sind verändert? Ist die Entfernung von ModemManager mit der berichteten Nutzungsart vereinbar, ohne notwendige Dienste zu verlieren? | Keine neue Modemtreiberentwicklung. |
| **Pinmux, RootFS, Build-Übergabe** | Sind vorhandene Pinmux-/GPIO-/Padvoltage-Dateien, `defconfig`, Desktop-Paketliste, MB2/BCT-EEPROM-Hinweise und Build-Artefakte nachvollziehbar? Welche Original-/Modifiziert-Paare sind belegbar? Welche Übergabeschritte zwischen Entwicklungs- und SDK-Manager-Baum sind fehleranfällig? | Nichts pauschal auf minimal/basic umstellen, kein universeller Installer. |

Prüfe bei Dateivergleichen **exakte Pfade, Versionskontext und Dateiinhalte**; unterschieden werden: NVIDIA-Upstream, vom Nutzer gesicherte `ORGINAL_`-Fassung, bearbeitete Fassung und nur in der Dokumentation behauptete Änderung. Auch `defconfig` ist nicht automatisch die effektive Kernel-`.config`. Bei DTBs zwischen Quelltextänderung, tatsächlich eingebundener Datei und geflashtem Artefakt unterscheiden.

## 4. Grenzen: keine neue Großbaustelle

- **Keine Änderungen, Patches, Neuorganisation, Git-Schreibaktionen, Installation, Builds, Flash-Vorgänge oder Live-Geräteabfragen.** Auch keine automatischen Upgrades.
- Keine systematische Reverse-Engineering-Suche nach der historischen `LAN743X=y`-Ursache, wenn sie aus den vorliegenden Dateien nicht begründbar ist.
- Nicht bearbeiten: Secure Boot, Produktionsflashing, RootFS-Redundanz, OTA, JetPack-Upgrade, Container-/SDK-Runtime oder VS-Code-Extension. Als spätere Themen maximal benennen.
- **Kein unnötiges Sammeln zusätzlicher Hardware-/Systeminformationen.** Fehlt etwas für einen spezifischen Nachweis, benenne ausschließlich die erforderliche Datei bzw. einen gezielten späteren Test.
- Der für das Projekt verbindliche IgH-/EC100-Datenpfad aus Management-Issue #12 wird durch diese Prüfung **nicht** ersetzt oder erweitert.

## 5. Ausgabe (kompakt, im Chat; keine Dateien schreiben)

1. **Kurzurteil** in maximal fünf Sätzen: Ist das Verfahren grundsätzlich schlüssig? Wo liegt das reale Risiko?
2. **Prüftabelle** mit genau fünf Zeilen gemäß Abschnitt 3: Befund mit Datei/Zeile, Status `belegt` / `vom Entwickler getestet (berichtet)` / `plausibel` / `offen`, Risiko und Bewertung `beibehalten` / `gezielt verbessern` / `später`.
3. **Maximal drei konkrete Verbesserungsvorschläge**, jeweils Nutzen, Aufwand und wie sich die Änderung später isoliert testen ließe. Ein Verbesserungsvorschlag darf auch lauten: „Nichts ändern, nur dokumentieren“.
4. **Maximal drei gezielte fehlende Quellen**, die für den wichtigsten offenen Punkt wirklich relevant wären (z. B. Pinmux-Ausgabe, aktiv verwendete DTB-/MB2-Konfiguration, original/modifiziertes `defconfig`-Paar); keine pauschale Forderung nach dem kompletten Linux-Build-Verzeichnis.
5. **Genau ein kleinster nächster Arbeitsschritt**, idealerweise ohne Testgerät und ohne Änderung an funktionierenden Dateien.

**Leitentscheidung:** Der funktionierende Zustand ist unsere Referenz. Codex soll Zusammenhänge erkennen und bessere, wartbarere Varianten vorschlagen, aber **keine Fehlersuche um ihrer selbst willen** beginnen.
