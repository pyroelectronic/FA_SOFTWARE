# B1-Auswertung AI7020-8 / AI7100-3

Stand 11.11.2026. Originalprotokolle vollständig eingelesen und alle Datensätze verglichen; BSP-Quellen und Paketmechanismen statisch geprüft. Keine Gerätekommandos, Pakettransaktionen oder Git-Schreibaktionen durch Codex. **B2-Schutzmenge und Schutzstrategie sind Vorschläge, keine Freigabe.** Die erfolgreiche Hardwareabnahme von Paket A bleibt gültig.

## Quellen und Nachweisgrenzen

| Originalprotokoll, jeweils 2.039 Zeilen / 397.657 Byte | SHA-256 der Originaldatei |
|---|---|
| `b1_inventory_AI7020-8_20261111T111206Z_536fa61a.txt` | `2232e22b20457859bafdd375666f068d95be6eac1bcaa857e3740c2114614e10` |
| `b1_inventory_AI7100-3_20261111T110722Z_71649660.txt` | `f01a806d39727f1d3b6a24fd7d1047e0499e9dfa2919ced8e6d1789c615f9a18` |

Beide nennen Skript-SHA-256 `ec3042cc48f2192bd8a8e12577eb95dda624b83d09cf65702b28cd4b381c8847`. Die Originale bleiben außerhalb des Repositorys. Referenz ist [FA_AI7XXX_BSP_R36.4.0](https://github.com/pyroelectronic/FA_AI7XXX_BSP_R36.4.0/tree/d5727429d70b6ab59ce331ad63d93ab488c36eaa), aktuelles `main` bei Prüfung: Commit `d5727429d70b6ab59ce331ad63d93ab488c36eaa`, Sicherung R36.4.0_V1.0.1, ausdrücklich **INCOMPLETE**. Maßgeblich ist dort Anleitung **1.3.1**; ältere hiesige Anleitungen sind andere Quellenstände.

Die 43 Einträge des Release-Manifests wurden strukturell und die hier genannten DTB-Werte gegen die Logs verglichen. Keine erneute Hashberechnung sämtlicher Repository-Binärdateien. Die Sicherung enthält kein vollständiges Kernel-/Modul-/Initrd-Release und keinen QSPI-Dump. Dokumentierte Hostbaum-Hashes sind keine eigenständig wiederholte Buildprüfung. [Releasegrenzen](https://github.com/pyroelectronic/FA_AI7XXX_BSP_R36.4.0/blob/d5727429d70b6ab59ce331ad63d93ab488c36eaa/RELEASES/R36.4.0_V1.0.1/RELEASE_INFO.md)

## 1. Tatsächlicher Bestand und Friedrich-Zuordnung

Beide Geräte: Ubuntu 22.04, `aarch64`, L4T 36.4.0, Kernel `5.15.148-tegra`; 2.057 Paketdatensätze, keine Holds, dpkg-Audit OK. Die 71 ausgewerteten Paketdatensätze samt lokalen Kandidaten/erfassten Beziehungen sind gleich. Das beweist nicht die Gleichheit sämtlicher 2.057 Paketversionen. Während der Erfassung blieb die jeweilige dpkg-Statusdatei unverändert.

Je Gerät **1.214 lesbare Dateirecords**: 81 Boot-, 28 Helfer-, 1.105 Modul-/Modulmetadateneinträge. Beide Modulmanifeste sind identisch, 332.478.061 Byte, Summen-SHA-256 `c8c69bcb9f6536c53ccda883a04d0a5bc82ad7263d0974c16b551f2516baceb0`. Das ist ein Plattenbestand, kein Nachweis sämtlicher geladenen Module.

| Bestandteil | Nachgewiesen / Einordnung |
|---|---|
| `/boot/Image` | Beide SHA-256 `5001e4b0bb0c51360f900b83c7ead5bf1f19704c42bedc93a4c4db7766b2407f`, 42.306.048 Byte. Entspricht dem im BSP-Audit dokumentierten AI7020-Eigenbuild. |
| AI7020-DTB | `kernel_tegra234-friedrich-p3767-0004.dtb`, unter `/boot/` und `/boot/dtb/` gleichinhaltig; SHA-256 `d586b32eff20447a3dd1c1d3fa761ccfdeabf915dc52002bcf5aa26c175d9e67`. Entspricht dem Release-Manifest. |
| AI7100-DTB | Entsprechender `p3767-0000`-DTB an beiden Positionen; SHA-256 `d3f2dbccda565627f6fb31cab764a81a1394e8c105ec48dfa5cd413e2ab8c84c`. Entspricht dem Release-Manifest. |
| Kernelkonfiguration / LAN743X | B1 meldet auf beiden `CONFIG_LAN743X=y`, passend zum aktuellen gesicherten defconfig. Zugleich existiert `updates/drivers/net/ethernet/microchip/lan743x.ko`, SHA-256 `58283d62806504f32f78d0400892487a79b4f0ffc6bd183e751483989f32ee5c`, ohne Paketzuordnung; `modinfo` löst auf diese Datei auf. Das beweist keine Laufzeitladung. B1 nennt die Quelle seiner Konfigurationsauswertung (`/proc/config.gz` oder Fallback) nicht. |
| Initrd | Extlinux nennt auf beiden `/boot/initrd`. AI7020: SHA-256 `daa218c82dd68a9aefb7c2daceac98c499fd3c69177a990f4bb3eb4085323184`; AI7100: `c191be51549e2c8a67c156540d6ab2b07b51f4d4ec955bf390e763647c894ff1`. Auch `initrd.img-5.15.148-tegra` plus Alias unterscheiden sich. Diese Archive sind nicht miteinander oder mit der historischen Host-Initrd gleich; ihre Inhaltsunterschiede bleiben ungeklärt. |
| Extlinux / EFI / QSPI | Extlinux-Hashes verschieden, erfasste LINUX-/INITRD-Pfade gleich. `BOOTAA64.efi` auf beiden gleich, ohne DEB-Zuordnung; Ursprung nicht im BSP-Manifest belegt. QSPI meldet 36.4.0 / GCID 37537400, Slot A, beide Slots normal. Keine Prüfsummenbasis der aktiven BCT-/QSPI-Inhalte oder Nachweis der effektiv gewählten DTB-/Overlay-Kombination. |

Das [BSP-Audit vom 09.11.](https://github.com/pyroelectronic/FA_AI7XXX_BSP_R36.4.0/blob/d5727429d70b6ab59ce331ad63d93ab488c36eaa/DOCUMENTATION/BSP_AUDIT_REPORT.md#L49-L69) beschreibt **SDK-Hostbäume**: damaliger AI7100-Kernel anders, ohne CYPRESS_M8 und ohne Friedrich-DTBs. Die heutigen Geräteprotokolle zeigen dagegen denselben Kernel/Modulbestand einschließlich `cypress_m8.ko` und passende Friedrich-DTB-Dateien. Diese unterschiedlichen Bezugsobjekte nicht vermischen. Keine Änderung von `m`/`y`, keine Bereinigung zusätzlicher Module und kein neuer Build aus diesem Befund ableiten.

Die dokumentierte Friedrich-Basis umfasst zusätzlich Carrier-DTS/USB, EEPROM-Deaktivierung, eigenes dynamisches Overlay, MB1-GPIO/Pinmux und MB2-CVB-Einstellung. Aktuelle DTS-Quellen enthalten bereits neue Friedrich-Modellnamen; die gesicherten DTB-Binärreferenzen noch den NVIDIA-Modelltext. Das passt zum bisherigen Modellbefund, ohne einen BSP-Fix zu verlangen. Die Umsetzung dieser frühen Bootanpassungen auf den heutigen Geräten ist durch B1 nicht vollständig verifiziert. [BSP-Anpassungen](https://github.com/pyroelectronic/FA_AI7XXX_BSP_R36.4.0/blob/d5727429d70b6ab59ce331ad63d93ab488c36eaa/DOCUMENTATION/BSP_CUSTOMIZATIONS.md)

## 2. Abweichungen zur Paketdatenbank

| Dateirecords je Gerät | Befund | Bewertung |
|---:|---|---|
| 921 | In-Tree-`.ko` weichen ab, Besitzer `nvidia-l4t-kernel` | Neubau/Installation über vorhandene NVIDIA-Pakete passt zu diesem Muster. Einzelne Modulhashes sind nicht gegen ein vollständiges FA-Buildmanifest belegt. |
| 102 | OOT-`.ko` weichen ab, Besitzer `nvidia-l4t-kernel-oot-modules` | Entsprechend durch dokumentierten NVIDIA-OOT-Eigenbuild plausibel; Einzelherkunft nicht vollständig bewiesen. |
| 9 | `modules.*` weichen ab | Build-/Installationsmetadaten und depmod-Indizes, nach Eigeninstallation erwartbar. |
| 2 | `/boot/Image` und `/boot/initrd` weichen ab | Image zusätzlich über Audit-Hash zugeordnet; Initrd-Regeneration dokumentiert, heutige Inhalte nicht geklärt. |
| **1.034** | **Abweichende Records insgesamt** | Kein Nachweis von 1.034 Schäden oder 1.034 eigenen Quellpatches. |
| 73 | Ohne Paketzuordnung | 63 `updates/`-Module, drei zusätzliche In-Tree-Module (`ch341`, `cypress_m8`, `iptable_raw`), ein generierter Index und sechs Bootrecords. Letztere: zwei DTB-Kopien, Extlinux, EFI-Datei, Initrd-Datei und ihr Alias. |
| 107 | Paketprüfwert stimmt | 73 NVIDIA-DTBs, 28 Helfer, drei Modulmetadaten und drei Displaymodule unter `updates/opensrc-disp/`. |

Die drei zusätzlichen In-Tree-Module entsprechen den dokumentierten defconfig-Ergänzungen. Die 63 zusätzlichen `updates/`-Module passen strukturell zur manuellen OOT-/Displayinstallation; insbesondere existieren zusätzlich zu den paketkonformen `opensrc-disp/`-Modulen drei andere `updates/nvidia*.ko`. Auswahl und Herkunft nicht pauschal gleichsetzen. `unowned_in_dpkg` bedeutet weder automatisch Friedrich-eigen noch entbehrlich. Paket-MD5-Vergleiche ersetzen keine FA-SHA-256-Baseline.

## 3. APT-Risiko, Abhängigkeiten und Skripte

45 installierte L4T-Pakete haben lokal den Kandidaten `36.4.7-20250918154033`, bei Kernelpaketen mit Präfix `5.15.148-tegra-`. Suite `r36.4` friert daher diese Basis nicht auf 36.4.0 ein. **Ein unveränderter Kernelrelease-Text wäre kein Schutzbeleg.** Es wurde keine Transaktion simuliert und kein Kandidaten-DEB/Skript ausgeführt oder vollständig gelesen.

Die installierten Metadaten belegen:

- `kernel` und `bootloader` hängen exakt von `nvidia-l4t-tools=36.4.0-20240912212859` ab; `init` und die häufigen `core`-Pre-Depends liegen dagegen im Bereich `>>36.4-0, <<36.5-0`.
- DTBs, Kernel-/OOT-Headers, OOT- und Displaymodule benötigen exakt den installierten Kernelpaketstand. `initrd` bindet exakt `xusb-firmware`, dieses wiederum `tools`.
- Ein `core`-Hold allein ist damit kein nachgewiesener Punktrelease-/Dateischutz. Die konkreten Beziehungen des Kandidaten 36.4.7 fehlen noch. Für Headers nennt das reale System `libssl3`; die allgemeine NVIDIA-Dokumentation mit `libssl1.1` darf hier nicht als Installationsvorgabe dienen.

Direkte Überschreiber sind insbesondere Kernel-, DTB-, OOT-, Display- und Initrd-Pakete. Bootloader/Tools können zusätzlich Bootartefakte betreffen. `nv_update_engine` und `nv_bootloader_payload_updater` gehören auf beiden Systemen zu `nvidia-l4t-tools` und entsprechen dessen Paketprüfwerten.

Die erfassten installierten Skriptfingerabdrücke zeigen beim Kernel `depmod`, `dpkg-trigger`, Kernelhooks und `nv_bootloader_payload_updater`; bei OOT/Display `depmod`; bei Initrd `dpkg-trigger`; beim Bootloader `/boot` und `/lib/modules`. **Kein Beleg eines Aufrufs allein durch ein Stichwort.** Insbesondere zeigt der Bootloader-postinst-Record keinen `nv_update_engine`-Treffer. NVIDIA beschreibt Kerneltrigger mit initramfs-/GRUB-Hooks und eine DTB-Neuerzeugung unter Übernahme der Bootargumente. Dadurch können auch generierte oder nicht paketzugeordnete Dateien betroffen sein. [NVIDIA R36.4 Paketmechanismus](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/SoftwarePackagesAndTheUpdateMechanism.html#package-dependencies)

Auch Ubuntu-Helfer bleiben relevant: `initramfs-tools` besitzt einen `update-initramfs`-Trigger/Postinst, `kmod` einen entsprechenden Trigger; weitere erfasste Initramfs-Hooks gehören etwa `udev`, `linux-firmware`, `busybox-initramfs` und `klibc-utils`. Reine Paketbesitzer- oder Reverse-Dependency-Listen reichen deshalb nicht als vollständige Schreibschutzmenge. Volltexte, Bedingungen und Aufrufketten installierter und angebotener Skripte sind bislang nicht abgeglichen. Eine APT-Simulation würde diese Skripte ebenfalls nicht ausführen.

## 4. Tatsächliche Updatekonfiguration

Beide `apt-daily`-Timer sind aktiv und enabled. Die zugehörigen Dienste sind zum Messzeitpunkt inactive; das ist kein Abschaltnachweis. Erfasst sind Listenintervall `1`, Download-Schalter `0`; Periodic-Enable, Unattended-Upgrade und Automatic-Reboot sind nicht gesetzt. `unattended-upgrades.service` fehlt. Damit ist regelmäßige Listenaktualisierung konfiguriert, aber weder ein laufendes automatisches BSP-Upgrade noch eine umfassende Updatesperre nachgewiesen.

PackageKit, cron und fwupd laufen; Anacron-/fwupd-Timer warten, snapd ist socketaktivierbar. Dies belegt Bereitschaft, keine bereits erfolgte Paket-/Firmwareinstallation. Die 131 übersprungenen Dateisymlinks sind keine 131 Updatejobs; `.placeholder`-Treffer sind bloße Stichwortfunde.

B1 zählt 13 Quellenrecords (zehn Ubuntu, NVIDIA common/t234, eine nicht klassifizierte Quelle) und drei Pin-Dateien. Es protokolliert absichtlich weder deren vollständige URIs noch Pinregeln. **Die unbekannte Quelle ist deshalb nicht als privat, fremd oder unsicher bewiesen.** Drei Dateien bedeuten nicht drei wirksame Regeln; APT kann Dateinamen ignorieren. Die beobachteten Kandidaten belegen jedenfalls keinen wirksamen Freeze dieser 45 Pakete auf 36.4.0. `signed-by=nicht angegeben` bedeutet nicht unsigniert. Quelle, wirksame Paketmuster/Prioritäten und weitere Updatewege bleiben vor der endgültigen Policy lokal zu klären. [APT-Pinregeln](https://manpages.ubuntu.com/manpages/jammy/man5/apt_preferences.5.html)

## 5. Ausgelassener Artefaktpfad

Jeweils eine **Fehlerart**, nicht nachweislich genau eine Datei: Die B1-Meldungen werden dedupliziert. Der Sammler nimmt `/etc/nv_boot_control.conf` explizit auf, lässt diese Datei anschließend aber nicht in `permitted_target()` zu. Für eine vorhandene reguläre Datei ist dies ein statisch nachgewiesener Erfassungsfehler. Dass sie auf beiden Geräten genau so vorliegt und sämtliche Ausschlüsse erklärt, bleibt nachzuweisen. Der Modulbaum ist laut beiden Logs vollständig; der Gesamtlauf bleibt ausdrücklich unvollständig.

Kleine gezielte Nachprüfung **durch Johannes auf beiden Gateways**, nicht durch Codex ausgeführt. Keine Dateiinhalte, Bootargumente oder fremden Linkziele ausgeben:

```bash
sudo bash <<'B1'
p=/etc/nv_boot_control.conf
if [[ ! -f "$p" || -L "$p" || $(readlink -f -- "$p" 2>/dev/null) != "$p" ]]; then
    printf 'OFFEN: bekannte Datei fehlt oder hat einen abweichenden Typ/Zielpfad.\n'
    exit 1
fi
stat -c 'Pfad=%n Modus=%a UID=%u GID=%g Bytes=%s' -- "$p" || exit 1
sha256sum -- "$p" || exit 1
dpkg-query -S -- "$p" 2>/dev/null || printf 'OFFEN: DEB-Zuordnung nicht bestimmt.\n'
B1
```

Das kann diesen konkreten Ausschluss bestätigen; weitere Ausschlüsse sind dadurch noch nicht ausgeschlossen. Kein voller neuer Inventarlauf und keine Sammlerkorrektur in diesem Auftrag.

## 6. B2-Empfehlung zur gemeinsamen Entscheidung — Vorschlag

**Gezielt verbessern:** explizite, versionsbezogene Paketschutzliste plus Prüfung der gesamten geplanten Transaktion im bestehenden Installer. Vorschlag für den NVIDIA-Kern der Schutzmenge, jeweils mit Präfix `nvidia-l4t-`:

`kernel`, `kernel-dtbs`, `kernel-oot-modules`, `display-kernel`, `initrd`, `bootloader`, `core`, `tools`, `init`, `configs`, `firmware`, `xusb-firmware`, `apt-source`, `kernel-headers`, `kernel-oot-headers`.

Die ersten sechs betreffen direkte Artefakte; die weiteren Pakete schützen Helfer, Firmware, Konfiguration, Quellenwahl und Kernel-/Headerkompatibilität. Das ist eine **vorläufige Bewertungsliste von 15 installierten Paketen, keine vollständige bewiesene Schreibermenge**. Ubuntu-Initramfs-/Kernelhook-Pakete zusätzlich als mögliche Regenerationsauslöser bewerten; sie nicht ungeprüft dauerhaft sämtlich halten.

- Persistente explizite Holds sind als erste Schutzstufe gegen reguläre APT-Änderungen sinnvoll. Ergänzende enge Versionspins erst nach Klärung vorhandener Pins/Quelle festlegen. `36.4*` schützt nicht vor 36.4.7; hohe Pinprioritäten können ungewollte Downgrades erlauben. Holds sind keine Dateisperre und verhindern nicht jeden Trigger oder direkten administrativen Eingriff. [apt-mark](https://manpages.ubuntu.com/manpages/jammy/man8/apt-mark.8.html), [apt_preferences](https://manpages.ubuntu.com/manpages/jammy/man5/apt_preferences.5.html)
- Vor späteren Paketänderungen Änderungen/Entfernungen geschützter Pakete und relevante Regenerationen prüfen; eine einfache Vorher-/Nachher-SHA-Prüfung erkennt Schäden erst nach dem Schreiben und ersetzt weder Vorabprüfung noch einen brauchbaren Rückfall.
- Abnahme von B2 braucht erlaubte und blockierte Transaktionen sowie Boot-/Funktionsnachweis und real nutzbare Wiederherstellung. Der jetzige INCOMPLETE-Sicherungsstand ist dafür noch kein vollständiger Rückfallbeleg. Ein Freeze verschiebt auch Sicherheitskorrekturen: NVIDIA veröffentlichte 36.4.7 als Sicherheitsupdate und stellt entsprechende Kernelquellenkorrekturen bereit. Dies begründet eine spätere bewusste Wartungsentscheidung, keinen automatischen Upgrade-/Buildauftrag. [NVIDIA-Sicherheitsupdate](https://forums.developer.nvidia.com/t/jetpack-releases-with-security-fixes-cve-2025-33182-cve-2025-33177/347679)

**Alternative, ebenfalls Vorschlag:** vorläufig alle 45 installierten L4T-Pakete gemeinsam einfrieren. Das vermeidet eine zu früh enge Auswahl und L4T-Teilmischungen, blockiert aber auch NVIDIA-Userspace-/Sicherheitsupdates und löst das Ubuntu-Triggerproblem nicht. Die gezielte Liste ist kleiner, verlangt dafür mehr Abhängigkeits-/Skriptprüfung. Der heutige Zustand ohne nachgewiesene Pins/Holds bleibt die Referenz, bietet aber keinen belegten Schutz. Noch keine dieser Varianten umsetzen.

**Genau ein nächster kleiner Schritt:** Johannes führt die gezielte `/etc/nv_boot_control.conf`-Nachprüfung auf beiden Gateways aus und stellt die Ausgaben bereit. Die endgültige B2-Entscheidung bleibt bis zur Klärung der genannten Quellen-/Pin-/Skriptlücken offen; kein neuer Kernel-/BSP-Entwicklungsauftrag folgt daraus.

## Durchgeführte Prüfung und Änderungen

Alle 4.078 Originalprotokollzeilen programmatisch ausgewertet, Dateirecords und übrige Abschnitte zwischen den Geräten verglichen, Zählungen aufgeschlüsselt; Referenzdateien am genannten BSP-Commit und offizielle NVIDIA-/Jammy-Dokumentation gelesen. Originale nicht verändert oder ins Repository kopiert. In diesem Auftrag ausschließlich diesen Bericht hinzugefügt; bestehende uncommittete Änderungen stammen aus dem vorherigen Auftrag. `install.sh` weiterhin SHA-256 `c9b0691de4c35d950de713ad1cfabfdb45cbad6fbb2d94f7627b78dfc8322b3c`. Keine Schutzmechanismen implementiert.
