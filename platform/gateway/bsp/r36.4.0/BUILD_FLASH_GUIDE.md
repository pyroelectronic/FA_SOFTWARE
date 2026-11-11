# FA Gateway – Jetson Linux R36.4.0: BSP-Build und Flash-Vorbereitung

**Projekt:** Friedrich Automation / **AI7020 (Jetson Orin Nano 4 GB)** – dokumentierter historischer Referenzfall, eigenes Carrier-Board  
**Dokumentstand:** 04.11.2026 – redaktionell korrigierter Arbeitsstand nach Quellen- und Konsolenabgleich  
**Geltungsbereich:** Die Prüfung bezieht sich auf AI7020; die Konfiguration darf nicht ungeprüft auf AI7100/Orin NX übertragen werden.  
**NVIDIA-Referenz:** Jetson Linux **R36.4.0**, JetPack **6.1**  
**Status:** Historisch hardwareerprobt nach Entwicklerbericht; ein Konsolenmitschnitt belegt einzelne Build-/Installationsschritte. Die **konsolidierte** Schrittfolge dieses Guides wurde **nicht** erneut vollständig gebaut oder auf Hardware abgenommen. **Keine Produktionsfreigabe.**

> **Zweck:** Das bisherige manuelle, funktionierende Verfahren klar, schrittweise und reproduzierbar beschreiben. **Nicht** den gesamten Linux-Build automatisieren oder die Konfiguration ohne Grund austauschen. Diese Datei beschreibt den **BSP-/Flash-Prozess**, nicht das separate `AI7XX0.sh`-Installationsskript für die Software nach dem Flashen.

## 1. Festgelegte Vorgehensweise

Die bisherige Trennung wird beibehalten:

```text
Offizielle NVIDIA-Artefakte R36.4.0 + Toolchain
              |
              v
FA-Entwicklungsverzeichnis (BSP-/Quellbaum)
  - Kernelkonfiguration, Device Tree, BCT, Pinmux
  - angepasste Desktop-Paketliste
  - Kernel / Module / DTBs / Desktop-RootFS bauen
              |
       definierte Übernahme
              v
SDK-Manager-Flashverzeichnis (separater Linux_for_Tegra-Baum)
  - freigegebene Image-/DTB-/BCT-/Modul-Artefakte
  - RootFS + NVIDIA-Binärintegration + Initramfs
              |
              v
NVIDIA SDK Manager (GUI) / alternativ dokumentierter CLI-Flash
              |
              v
AI7020-Gateway: Boot und Hardware-Funktionstest
              |
              v
Separater Schritt: Gateway-Provisionierung (historischer AI7XX0.sh, eigenständig zu prüfen)
```

**Wichtig:** Eine erfolgreiche Entwicklungskonfiguration ist nicht automatisch eine reproduzierbar erzeugte Release-Version. Dazu gehören die genaue Quellenversion, die angewendeten Änderungen und die Übergabe der Artefakte.

## 2. Hardware- und Entwicklungsentscheidungen

| Komponente | Derzeitiger Referenzstand | Einordnung |
|---|---|---|
| Basis | **AI7020 / Jetson Orin Nano 4 GB**, eigenes FA-Carrier-Board | Maßgebliche `AI7020_install_config`-Quelle; eine spätere AI7100-/Orin-NX-Variante muss eigenständig zugeordnet werden. |
| Jetson Linux | R36.4.0 als dokumentierter **Build-Ausgangsstand** | Tatsächlich installierte Release-Version nicht durch diese Datei bewiesen; andere Archivnamen (`36.4.3_V6.1`) sind separat zu klären. |
| RootFS | Ubuntu Jammy **Desktop**, angepasste Paketliste | Bewusste Entscheidung nach erfolglosen/aufwendigen Tests mit Minimal und Basic. GUI kann nach Installation deaktiviert werden. |
| Ethernet | `CONFIG_LAN743X=m` | Von Johannes auf Hardware als funktionierend berichtet. `=y` bereitete damals Probleme; Ursache nicht abschließend geklärt. Die ältere Anleitung mit `=y` ist insoweit überholt. |
| BG95 | USB-Serial/QMI/PPP-Konfiguration; **kein ModemManager** im erprobten Betrieb | Nach Entwicklerbericht funktionierend. Keine allgemeine Aussage, dass ModemManager grundsätzlich inkompatibel ist. |
| USB | Einfacher Host-Port, keine vollständige Developer-Kit-Type-C-/Hub-Beschaltung | Abbildung im wirksamen Device Tree muss zur FA-Schaltung passen. |
| CSI-Kamera | Ungenutzte Developer-Kit-Kamera-Elemente deaktiviert | Keine Pflicht, ein neues Overlay-Konzept einzuführen; nur wirksame DTB/DTBO-Konfigurationen sind entscheidend. |
| Pinmux | NVIDIA-Pinmux-Spreadsheets / daraus generierte Dateien | Die konkret verwendeten Excel- und `.dtsi`-Dateien müssen dem Build zugeordnet werden. |
| Flash | SDK Manager GUI, historisch auch CLI erprobt | GUI bleibt zulässiger freigegebener Weg. |

### Bekannte Vergleichsdateien aus `ORGINAL.zip`

Die archivierten `ORGINAL_...`-Dateien sind **lokale gesicherte Vergleichsfassungen**; eine Bytegleichheit mit offiziellen NVIDIA-Upstream-Dateien ist damit nicht bewiesen. Als Ausgangspunkte für den gezielten Vergleich sind vorhanden:

- `defconfig` / `ORGINAL_defconfig` (darunter `CONFIG_LAN743X=m`, BG95-nahe Optionen)
- `nvubuntu-jammy-desktop-aarch64-packages` / entsprechende `ORGINAL_...`-Datei (angepasste Desktop-Pakete)
- `tegra234-p3768-0000.dtsi` / gesicherte Fassung (USB-Port)
- `tegra234-p3768-0000+p3767-xxxx-nv-common.dtsi` / gesicherte Fassung (u. a. FUSB301)
- geänderte Kameradateien im Unterordner `overlay/`

**Noch nicht vollständig im Vergleichsarchiv nachgewiesen:** verwendete Board-/Flash-`.conf`, MB1-Pinmux-/GPIO-/Padvoltage-Dateien, MB2-EEPROM-BCT, tatsächlich gewählte DTB/DTBO und das vollständige Ergebnis-RootFS. Diese sind keine Blockade für das Lesen dieser Anleitung, werden aber für eine **vollständige Wiederholbarkeit** benötigt.

## 3. Vorbereitung und Quellen

### Beleglage und Abweichung zur historischen Ausführungsreihenfolge

**Historische Hauptquelle:** `AI7020_install_config` (Version 1.2.0) zusammen mit `Copy of the console from AI7020_install_config`. Die ältere `Kernel dtb and rootfs Building r36.4.txt` und das nachgelagerte `AI7XX0.sh` sind zusätzliche, aber **nicht maßgebliche** Quellen für diesen konkreten AI7020-BSP-Build.

- Die historische Anleitung sieht vor, Kernel-/In-Tree- und NVIDIA-OOT-Module zuerst zu installieren, danach `apply_binaries.sh` auszuführen und anschließend eigene Kernel-/Modulartefakte **erneut** zu installieren, weil NVIDIA-Pakete sie überschreiben können.
- Der vorhandene Mitschnitt zeigt den Bau und die erste Modulinstallation sowie `apply_binaries.sh`, einschließlich einer dort ausgeführten **Initrd-Aktualisierung**. Er endet jedoch **vor** der in der Anleitung vorgesehenen erneuten Installation. Der abschließende historische RootFS-/Initrd-Stand ist dadurch nicht vollständig protokolliert.
- **Dieser Guide ordnet** `apply_binaries.sh` bewusst **vor** den abschließenden eigenen Kernel- und Modulinstallationen ein. Das ist eine **konsolidierte, technisch plausible Soll-Reihenfolge**, keine wortgetreue Wiedergabe des historischen Logs. Ein identischer Ergebnisstand ist bisher nicht durch einen Neudurchlauf nachgewiesen.


### 3.1 Versionen nicht mischen

Für **diesen** historischen Stand wird Jetson Linux **R36.4.0** als gemeinsame Basis verwendet. Verzeichnisnamen und Archive mit abweichenden Versionsnummern werden nicht stillschweigend gleichgesetzt. Vor einem zukünftigen Build sind Release, Quellen, Toolchain, SDK-Manager-Baum und die geplante Board-/Flash-Konfiguration zuzuordnen.

Benötigte Komponenten:

1. Offizielles **Jetson Linux Driver Package (BSP)** für die vorgesehene Version.
2. Zum selben Release gehörende **Kernel-/NVIDIA-Out-of-Tree-Quellen**, bei manueller Beschaffung einschließlich der jeweiligen Quellarchive.
3. Von NVIDIA dokumentierte **aarch64-Bootlin-Toolchain**.
4. Passender Flash-Baum des NVIDIA SDK Manager (separat von der Entwicklungsumgebung).
5. Gesicherte FA-Anpassungen (Konfigurationsdateien, Device Trees/BCT und RootFS-Paketliste).

**Anmerkung:** Das Archiv `Jetson_Linux_R36.4.0_aarch64.tbz2` ist das **Driver Package**, nicht bereits automatisch das vollständige Kernel-Quellarchiv. NVIDIA unterscheidet BSP und `public_sources.tbz2` bzw. eine Quellen-Synchronisation. Originalquellen können passend zum Release über `source_sync.sh` oder über die Quellenarchive bezogen werden.

### 3.2 Host-Voraussetzungen

NVIDIA nennt unter anderem `git-core`, `build-essential` und `bc` als Kernel-Build-Voraussetzungen sowie die passende Toolchain. Je nach Quellstand sind zusätzliche Pakete (`flex`, `bison`, `libssl-dev` usw.) erforderlich. **Kein pauschales `apt-get dist-upgrade` als Voraussetzung ausführen:** Das ist kein notwendiger Build-Schritt und kann die Hostumgebung unbeabsichtigt verändern.

**Wichtiger Hinweis zu Linux Mint:** Für `nv_build_samplefs.sh` nennt NVIDIA Ubuntu 22.04 als unterstützten Host. Auf einem anderen Host kann der in der NVIDIA-Anleitung beschriebene Ubuntu-22.04-Container zum **RootFS-Erstellen** genutzt werden. Dies ist nicht gleichbedeutend mit „das gesamte Gateway in Docker bauen“.

### 3.3 Eindeutige Arbeitsverzeichnisse

Die folgenden Variablen sind **nur ein Lesebeispiel** für die Dokumentation; Pfade erst nach Prüfung am Linux-Rechner einsetzen:

```bash
# Beispielwerte ersetzen; NICHT ungeprüft als Installationsskript ausführen.
BUILD_L4T="/PFAD/ZUM/FA_BUILD/Linux_for_Tegra"
FLASH_L4T="/PFAD/ZUM/NVIDIA_SDK_MANAGER/Linux_for_Tegra"
TOOLCHAIN_BIN="/PFAD/ZUR/BOOTLIN_TOOLCHAIN/bin"
# CROSS_COMPILE zeigt auf ein Präfix, nicht auf eine ausführbare Datei:
CROSS_COMPILE="${TOOLCHAIN_BIN}/aarch64-buildroot-linux-gnu-"
```

**Regel:** `BUILD_L4T` enthält die bearbeiteten Quellen/Build-Ergebnisse, `FLASH_L4T` ist das separate, kontrollierte Ziel für Flash-Artefakte. Vor jeder Kopieraktion den vollständigen Quell- und Zielpfad dokumentieren. Vorhandene Dateien niemals ohne Sicherung überschreiben.

## 4. Board-Anpassungen vor dem Build

### 4.1 Kernelkonfiguration und LAN7430

- Die aktuelle Vergleichsfassung enthält `CONFIG_LAN743X=m` – **beibehalten**.
- Bei `=m` wird der Treiber als Kernelmodul gebaut; das Modul muss passend zum Kernel im RootFS landen und später geladen bzw. automatisch erkannt werden können.
- `=y` bindet den Treiber fest ein. **Warum das in den früheren Tests scheiterte, ist anhand der vorliegenden Dateien nicht beweisbar.** Nicht ohne neue Anforderung auf `=y` zurückstellen.
- `defconfig` ist die gewünschte Konfigurationsquelle. Nach der Konfiguration muss später die **effektiv generierte Kernel-`.config`** geprüft werden, weil Abhängigkeiten Einstellungen beeinflussen können.

### 4.2 BG95

Die USB-Serial-/QMI-/PPP-Optionen und die bewährte Betriebsweise ohne ModemManager bleiben Referenz. Ob ein Paket entfernt werden muss, hängt später vom tatsächlich eingesetzten Modem-Dienst und Installationsprofil ab; dies ist keine universelle Regel für jedes Gateway.

### 4.3 USB-Host und CSI-Kameras

Die bisherige FA-Schaltung hat einen einfachen USB-Host-Port; der Developer-Kit-Type-C-Controller und nicht vorhandene Kamera-Hardware sollen nicht künstlich aktiviert werden.

Die R36.4-Anleitung von NVIDIA beschreibt hierfür die relevanten `xusb_padctl`-/xHCI-Zuordnungen, USB-Host-Modi, USB2/USB3-Paarung und den möglichen Wegfall von FUSB301-/Type-C-Endpunkten. **Nur die geänderte Quelldatei zu betrachten genügt nicht:** Entscheidend ist, ob sie in die gewählte und tatsächlich geflashte DTB-Konfiguration eingeht.

Die bereits vorhandenen Kamera-`overlay/`-Quelldateien bedeuten **nicht**, dass zusätzlich ein Overlay installiert wurde. Es werden weder neue DTBOs noch ein Overlay-Mechanismus als Pflicht eingeführt.

### 4.4 Pinmux und Boot-Konfiguration

Die per NVIDIA-Spreadsheet generierten `pinmux.dtsi`, `gpio.dtsi` und `padvoltage.dtsi` sind board-spezifische Eingaben. NVIDIA verweist auf ihre Einbindung über die Board-/Flash-Konfiguration; die richtigen Zielverzeichnisse können je Dateityp variieren. Die genauen Dateien und die zugehörige Board-Konfiguration vor dem nächsten Build nachtragen.

**Nur wenn das Carrier-Board keinen eigenen EEPROM besitzt** und die bestehende Hardwarekonfiguration dies erfordert, ist die von NVIDIA beschriebene Änderung in `tegra234-mb2-bct-misc-p3767-0000.dts` relevant:

```diff
- cvb_eeprom_read_size = <0x100>
+ cvb_eeprom_read_size = <0x0>
```

Keine pauschale Übernahme auf andere Boards.

## 5. Build- und Übernahmereihenfolge (bewährtes Prinzip, präzisiert)

Die Reihenfolge fasst die Schritte aus der historischen Anleitung und den NVIDIA-Kapiteln für **R36.4** zusammen. Sie ist ein **manuelles Runbook**, kein unmittelbar ausführbares Skript. Ein neuer Gesamtdurchlauf ist hiermit noch nicht getestet.

### Schritt A – Ausgangsstand sichern

- Entwicklungs- und SDK-Manager-/Flash-Baum eindeutig kennzeichnen.
- Originaldateien sowie FA-Änderungsdateien vergleichen und sichern.
- Konkrete Board-/Flash-Auswahl und RootFS-Zielmedium (z. B. NVMe) festhalten.
- Vor Überschreibungen eine **separate Kopie** der bisherigen funktionsfähigen Flash-Dateien behalten.

**Prüfpunkt:** Die zwei Verzeichnisse und das zugrunde liegende NVIDIA-Release sind eindeutig.

### Schritt B – Angepasstes Desktop-RootFS erstellen

Im BSP-Baum die gesicherte FA-Paketliste für Desktop zugrunde legen:

```bash
cd "${BUILD_L4T}/tools/samplefs"
sudo ./nv_build_samplefs.sh --abi aarch64 --distro ubuntu --flavor desktop --version jammy
```

Das NVIDIA-Tool erzeugt das Sample-RootFS-Archiv (typisch `sample_fs.tbz2`). Die Ausgabe prüfen, ehe im separaten Flash-Baum Dateien ersetzt werden.

**Prüfpunkt:** RootFS-Erzeugung erfolgreich; benutzte Paketliste und Archivpfad dokumentiert. Der Desktop-Basisstand bleibt bewusst gewählt.

### Schritt C – RootFS in die Flash-Umgebung übernehmen

Die spätere Flash-Umgebung vorbereiten und das erzeugte Archiv in **deren** `rootfs/` entpacken. Das folgende Muster benötigt geprüfte, absolute Pfade und ein dafür vorbereitetes Zielverzeichnis:

```bash
# Beispiel: <ROOTFS_ARCHIV> vorher mit tatsächlicher Datei ersetzen
sudo tar xpf "<ROOTFS_ARCHIV>" -C "${FLASH_L4T}/rootfs"
cd "${FLASH_L4T}"
sudo ./apply_binaries.sh
```

`apply_binaries.sh` integriert die NVIDIA-spezifischen Bestandteile des Jetson-Linux-RootFS. **Im historischen Konsolenprotokoll wurden dabei auch NVIDIA-Kernel-/OOT-Pakete installiert und die Initrd aktualisiert.** Daher können zuvor installierte eigene Kernel-/Moduldateien überlagert werden. Im hier beschriebenen konsolidierten Ablauf erfolgt die NVIDIA-Integration bewusst **vor** der abschließenden Installation der eigenen Artefakte. Wird `apply_binaries.sh` später erneut aufgerufen, ist deren Zustand danach erneut zu prüfen und gegebenenfalls wiederherzustellen.

**Prüfpunkt:** Nur das geplante Flash-RootFS wurde bearbeitet; NVIDIA-Integration ohne Fehler abgeschlossen.

### Schritt D – Kernel und In-Tree-Module bauen

Im **Build-Baum** mit der funktionierenden FA-Konfiguration (`LAN743X=m`) arbeiten:

```bash
cd "${BUILD_L4T}/source"
export CROSS_COMPILE="${TOOLCHAIN_BIN}/aarch64-buildroot-linux-gnu-"
make -C kernel
```

Für die Installation der gebauten In-Tree-Module in das **Flash-RootFS** beschreibt NVIDIA:

```bash
export INSTALL_MOD_PATH="${FLASH_L4T}/rootfs/"
sudo -E make install -C kernel
```

Das erzeugte `kernel/kernel-jammy-src/arch/arm64/boot/Image` wurde laut historischer Hauptquelle an **zwei Ziele desselben Flash-Baums** übertragen:

- `${FLASH_L4T}/kernel/Image`
- `${FLASH_L4T}/rootfs/boot/Image`

Für den konsolidierten Ablauf vor der Übernahme die vorhandenen Zieldateien sichern, beide Zielpfade und ihre Prüfsummen dokumentieren. Die Kernelversion muss zu den installierten Modulen und zum verwendeten Bootpfad passen. Ein abweichender späterer Flash-/UEFI-Bootpfad ist ausdrücklich separat zu prüfen.

**Prüfpunkt:** Build erfolgreich; `CONFIG_LAN743X=m` in der effektiven Konfiguration bestätigt; passendes Modul im RootFS vorhanden. Der historische Konsolenmitschnitt belegt den Bau von `lan743x.ko` als Modul für `5.15.148-tegra` sowie zwei Ablagen:

- `lib/modules/5.15.148-tegra/kernel/drivers/net/ethernet/microchip/lan743x.ko` – aus der Kernel-/In-Tree-Installation
- `lib/modules/5.15.148-tegra/updates/drivers/net/ethernet/microchip/lan743x.ko` – aus der NVIDIA-OOT-Installation

Diese zwei Ablagen sind **nicht automatisch eine fehlerhafte Doppelinstallation** und werden nicht pauschal bereinigt. Ihre Binärgleichheit und die beim Boot tatsächlich geladene Variante sind aus dem Mitschnitt nicht nachgewiesen. Für den späteren Release-Check sind der endgültige Modulindex und die Dateiherkunft relevant.

### Schritt E – NVIDIA-Out-of-Tree-Module und Initramfs

NVIDIA beschreibt im Quellbaum zusätzlich:

```bash
cd "${BUILD_L4T}/source"
export CROSS_COMPILE="${TOOLCHAIN_BIN}/aarch64-buildroot-linux-gnu-"
export KERNEL_HEADERS="$PWD/kernel/kernel-jammy-src"
make modules
export INSTALL_MOD_PATH="${FLASH_L4T}/rootfs/"
sudo -E make modules_install
```

Nach abgeschlossener Übernahme der Kernelmodule und -dateien **in der Flash-Umgebung** die NVIDIA-Initramfs-Aktualisierung prüfen und, soweit für den verwendeten Bootpfad erforderlich, gemäß NVIDIA-Anleitung durchführen:

```bash
cd "${FLASH_L4T}"
sudo ./tools/l4t_update_initrd.sh
```

**Prüfpunkt:** Kein Vermischen unterschiedlicher Kernel-/Modulversionen; verwendetes Initramfs dokumentiert. **Historisch belegt** ist die Initrd-Aktualisierung während `apply_binaries.sh`. **Nicht im Konsolenmitschnitt belegt** sind die anschließend in `AI7020_install_config` vorgesehenen erneuten Eigenmodul-Installationen und der endgültige Initrd-/RootFS-Stand. Im konsolidierten Guide ist ein abschließender Initrd-Schritt ausdrücklich vorgesehen, aber noch nicht neu getestet.

### Schritt F – Device Trees bauen und übernehmen

Im Entwicklungsbaum:

```bash
cd "${BUILD_L4T}/source"
export CROSS_COMPILE="${TOOLCHAIN_BIN}/aarch64-buildroot-linux-gnu-"
export KERNEL_HEADERS="$PWD/kernel/kernel-jammy-src"
make dtbs
```

NVIDIA beschreibt die Übergabe der erzeugten DTB-Dateien nach `Linux_for_Tegra/kernel/dtb/`. In unserem Zwei-Baum-Verfahren ist das der **Flash-Baum**. Statt pauschal sämtliche alten Dateien zu überschreiben, die für das konkrete Board ausgewählten Ziel-Dateien und deren Quellen festhalten.

**Prüfpunkt:** Die gewählte Board-Konfiguration verweist auf die zur FA-Schaltung passenden DTB-Dateien. **Ein zusätzliches DTBO-Overlay ist nicht vorausgesetzt.**

### Schritt G – Pinmux, BCT, Board-Konfiguration einordnen

Vor dem Flashen prüfen, ob die in Schritt 4 genannten generierten Dateien und MB1-/MB2-/Board-Einstellungen in der Flash-Umgebung wirklich dem FA-Stand entsprechen. Das betrifft insbesondere:

- Pinmux-/GPIO-/Padvoltage-Eingaben und die gewählte Board-`.conf`;
- EEPROM-Konfiguration (nur falls kein Carrier-EEPROM vorhanden);
- Kernel-DTB und gegebenenfalls absichtlich benutzte DTBOs;
- RootFS-Zielmedium und Flash-Partitionierung.

**Prüfpunkt:** Nicht nur Dateinamen, sondern **die aktive Auswahl** ist dokumentiert. Eine unveränderte Developer-Kit-Board-Konfiguration ist keine allgemein gültige Beschreibung deines abweichenden Carrier-Boards.

### Schritt H – Freigegebene Flash-Eingaben sichern und SDK Manager verwenden

Vor dem Flashen eine kleine Dateiliste mit Hashes der **tatsächlich verwendeten** Eingaben anlegen (siehe Abschnitt 6). Ein Update oder erneuter Download durch SDK Manager kann die vorbereiteten Verzeichnisse beeinflussen: Vor jedem Flash prüfen, ob die eigenen Anpassungen noch vorhanden sind.

Das Flashen erfolgt zunächst wie historisch erprobt **über NVIDIA SDK Manager GUI**. Alternativ kann der dazugehörige, für Board und Speicherziel verifizierte NVIDIA-CLI-Befehl dokumentiert werden; **kein generischer Flash-Befehl wird hier als sicherer Befehl für dein eigenes Carrier-Board ausgegeben**.

**Prüfpunkt:** Flash-Protokoll, Board-/Speicher-Auswahl und Image-Version zuordnen.

### Schritt I – Minimale Funktionsprüfung und Abgrenzung

Nach erfolgreichem Boot einen kurzen Nachweis für die im BSP verankerten Funktionen führen: Boot, Netzwerk über LAN7430, USB-Host, gegebenenfalls BG95, das beabsichtigte Kameraverhalten und Kernel-/Modul-Konsistenz. Vorhandene historische Hardwaretests sind als solche zu dokumentieren; dieser Abschnitt verlangt **nicht**, dass jetzt alle Tests erneut durchgeführt werden.

**Danach erst:** `platform/gateway/provisioning` bzw. die überarbeitete Gateway-Softwareinstallation. IgH/EC100 ist ein eigener Integrationsbaustein, kein Grund, diesen BSP-Prozess neu zu bauen.

## 6. Kleines Artefaktmanifest statt großem Automatisierungssystem

Für einen vorbereiteten Flash-Stand reicht zunächst eine lesbare Tabelle:

| Eintrag | Beispiel / einzutragende Information |
|---|---|
| Referenz | `FA-AI7020-BSP-R36.4.0-<laufende-kennung>` |
| NVIDIA-Ausgangsbasis | R36.4.0 + exakte Downloads / Prüfsummen |
| Toolchain | Version / Binärpräfix |
| Board-/Flash-Konfiguration | tatsächlicher Name der benutzten `.conf` |
| FA-Änderungen | Kernelkonfiguration; USB/DTS; Pinmux; BCT; Desktop-Paketliste |
| Kernel / Module / Initramfs | Versionskennung, Quelldateien, SHA-256 der übergebenen Artefakte |
| DTB/DTBO | exakt ausgewählte Dateinamen, SHA-256; `keine` bei nicht verwendeten Overlays |
| RootFS | benutzte Paketliste, Sample-Archiv und Hash |
| Flash | SDK Manager GUI / CLI, Gerätevariante, Zielmedium, Protokoll |
| Praxistests | *historisch berichtet* / *neu geprüft* / *offen* |

Hashes lassen sich bei Bedarf **lesend** mit `sha256sum <datei>` ermitteln. Das ist eine einfache Absicherung gegen unbeabsichtigtes Mischen von Ständen, kein neues Tool-Projekt.

## 7. Bewusst außerhalb dieses Arbeitsschritts

- Migration auf JetPack 7 oder ein neues Kernel-Release.
- Vollautomatischer „Ein-Knopf-Build“ und Produktions-Massenflash.
- Secure Boot, signierte Images, RootFS-A/B, Overlayroot und OTA-Updater.
- Umstellung auf Minimal-/Basic-RootFS.
- Eigenes Overlay-/DTBO-Konzept allein zur „Verschönerung“ der Struktur.
- Umstrukturierung von `AI7XX0.sh`, PyTorch, Node-RED oder dem SDK.

Diese Themen bleiben möglich, aber werden erst bei einem konkreten Anlass oder separaten Auftrag bearbeitet.

## 8. Zielgerichtet offene Angaben (kein pauschaler Audit-Auftrag)

Die Anleitung ist als **konsolidierte Dokumentation** nutzbar. Um sie später als **exakte Schritt-für-Schritt-Reproduktion** freizugeben, fehlen bislang nur konkret zuzuordnende Dateien oder Werte:

1. Tatsächlich verwendete FA-Board-/Flash-`.conf` und Speicherziel-Auswahl.
2. Zum historischen Stand gehörige Pinmux-/GPIO-/Padvoltage-Dateien und gegebenenfalls die MB2-BCT-Datei.
3. Die für den Flash vorbereiteten Image-, Modul-, DTB-/DTBO- und Initramfs-Dateien bzw. eine eindeutige Übertragungsliste.
4. Festlegung, welcher beobachtete Erfolg zur entsprechenden Buildfassung gehört (beispielsweise LAN7430 `m`, USB-Host, BG95).

Nicht alle Details müssen sofort nachermittelt werden. Diese Angaben werden dann ergänzt, wenn du den nächsten Build-/Flash-Stand tatsächlich reproduzieren möchtest.

## 9. Quellen und Abgrenzung

**Nutzerunterlagen:** `AI7020_install_config` (V1.2.0, historische Hauptquelle); `Copy of the console from AI7020_install_config` (Konsolenmitschnitt); `Kernel dtb and rootfs Building r36.4.txt` (ältere Anleitung); `ORGINAL.zip` (Dateipaare); berichtete erfolgreiche Hardwaretests und manuelle Übergabe in den SDK Manager. Eigene Hardwaretests wurden **nicht** durch dieses Dokument ersetzt. Der historische Mitschnitt ist kein vollständiger Nachweis aller nachfolgenden Wiederinstallationsschritte.

**Offizielle NVIDIA-Dokumentation für R36.4:**

- [Kernel Customization](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/Kernel/KernelCustomization.html) – Quellenbeschaffung, Kernel, In-Tree-/Out-of-Tree-Module, Initramfs und DTBs.
- [Root File System](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/RootFileSystem.html) – Desktop-SampleFS und Host-Voraussetzungen.
- [Jetson Orin NX/Nano: Module Adaptation and Bring-Up](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/HR/JetsonModuleAdaptationAndBringUp/JetsonOrinNxNanoSeries.html) – Pinmux, EEPROM, USB, Board-Konfiguration und Overlays.
- [Flashing Support](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/FlashingSupport.html) – SDK-/CLI-Flashmechanismen.

**Bewertung:** Die wesentlichen Verfahren sind von NVIDIA dokumentiert. Ob die individuelle FA-Dateikombination vollständig korrekt ist und exakt den bislang funktionierenden Stand erzeugt, bleibt bis zur gezielten Zuordnung und einem späteren Reproduktionslauf offen.

**Dokumentänderungen dieses Stands (rein redaktionell):** AI7020/Orin Nano 4 GB eindeutig zugeordnet; Hauptquelle und Mitschnitt eingebunden; historische und konsolidierte Befehlsfolge voneinander getrennt; Wirkung von `apply_binaries.sh` und belegter Initrd-Lauf präzisiert; beide `Image`-Zielpfade dokumentiert; die zwei belegten Modulpfade samt Herkunft erläutert. Keine Originalskripte, Kernelquellen oder Hardwarekonfigurationen verändert.
