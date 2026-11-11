# ARCHITECTURE — Softwareplattform Friedrich Automation

**Status:** Zielordnung / Entwicklungskonzept, kein bereits integrierter Release.

Für den Gateway-Installer konkretisiert das [Installationskonzept](platform/gateway/provisioning/INSTALLATIONSKONZEPT.md) Zielumfang, Profile und Freigabegates. Seine übergeordnete Architektur und der Fahrplan A–F sind freigegeben; ausdrücklich offene technische Detailentscheidungen bleiben gesondert zu entscheiden. Das Friedrich-BSP wird im eigenen Entwicklungsrepository gebaut und geflasht. `platform/gateway/bsp/` enthält hier Referenzen und Nachweise; der Installer beginnt auf dem betriebsfähigen geflashten Gateway.

## Schichten

```text
Entwicklung: FA VS-Code-Extension (SSH / Projekte / Sync)       [devtools/]
                  |                                    
   Konkrete Labor-/Kunden-Anwendung (+ Deployment)              [applications/]
                  |                 ^
       wiederverwendbare Module/Templates                       [sdk/]
                  |                 |
  Optionale Runtime-Profile: Node-RED, MQTT, Datenbank, KI      [runtime/]
                  |                 |
  Native Gateway-Dienste: IgH / EC100-Reader / Device Layer     [platform/gateway/]
                  |
  Jetson Linux / Kernel / LAN7430 / NVIDIA Runtime             [platform/gateway/]
```

`deploy/` definiert übergreifende Auslieferungs-/Rollback-Regeln. Gleiche Prinzipien gelten für `platform/server/`, dort jedoch mit eigener x86_64-/Ubuntu-Baseline statt L4T. **Die Pfeile sind Abhängigkeiten, keine Installationspflicht.**

## Fünf Verantwortungsbereiche

1. **BSP/Plattform:** exakt identifiziertes NVIDIA-/Ubuntu-Release, Board/Carrier, Kernel-/Treiber-/Flashänderungen, Boot, Netzwerk und Sicherheit.
2. **Runtime:** notwendige Systemlaufzeiten und optionale Container-Stacks. Image ist nicht gleich Container, Container ist nicht gleich Betriebssystem. Definierte Versionen und Speicherpfade.
3. **SDK:** erprobte Python/C/C++/Rust-Bausteine, Treiberadapter, Node-RED-Flows, Beispiele, Templates. SDK-Code wird nicht automatisch auf jedes Gateway installiert.
4. **Engineering:** VS-Code-Extension mit Geräteverwaltung und sicheren, kontrollierten Projekttransfers. Betrieb darf von der Extension unabhängig bleiben.
5. **Anwendungen/Deployment:** ausführbare Anwendung, Konfiguration, Tests, Service-/Compose-Dateien, persistente Daten, Logs, Backup/Recovery.

## Host vs. Container

- Linux-Kernel, LAN7430-Treiber, Flashprozess und IgH-Kernelkomponenten gehören zum Host-Basissystem.
- Zyklischer IgH-Anwenderdienst zunächst nativ; ein späterer Containerbetrieb setzt realen Jitter-/Latenztest und Rechte-/Netzwerkprüfung voraus.
- Node-RED, Mosquitto, InfluxDB, Python-Anwendungen, KI und Webserver können je nach Einsatz nativ oder containerisiert laufen.
- NVIDIA-Treiber/Kernelkomponenten sind hostgebunden; CUDA-/PyTorch-/TensorFlow-Userspace-Komponenten können in **passende** Container, aber nicht unabhängig von der Hostkompatibilität.
- Laborprofil und Kundenprofil sollen auf derselben freigegebenen Basis **möglich** sein; eine tatsächliche Gleichheit ist erst nach einem reproduzierbaren Test belegt.

## Versionierte Entwicklung

- `Referenz` = historischer, behaupteter oder nachgewiesener alter Stand, unverändert sichern.
- `Entwicklung` = separat abgeleiteter Stand, mit Prüfbericht.
- `Freigabe` = exakt bestimmter Quell-/Artefaktstand + dokumentierte Boot-/Funktions-/Neustart-/Wiederherstellungsprüfung.
- Neue JetPack-/Ubuntu-Version ist **ein neues Freigabevorhaben**, kein ungeprüftes Upgrade.
- Fehler in bestehenden Ständen: Ursache erfassen, kleinste Korrektur testen, keine stillen Voll-Upgrades.

## Synchronisation

- Die Extension nutzt vorläufig SSH als bewährten Transport; es existiert noch kein Nachweis, dass ein eigener Gateway-Agent einfacher und sicherer ist.
- Node-RED-Projekte besitzen eigenen Speicher-/Git-Kontext; genaue Pfade und führende Git-Quelle anhand kompletter Extension/Live-Konfiguration festlegen.
- Keine unkontrollierte bidirektionale Überschreibung, kein 'remote ersetzen' ohne Backup, Transferprüfung und Recovery.

## Verbesserungen und Architekturwechsel
Die Einteilung ist eine **Arbeitsstruktur, keine technische Sackgasse**. Ein Austausch von SSH, einer Runtime, einer Geräte-API oder einer BSP-Variante ist möglich, wenn eine konkrete Verbesserung mit Prototyp, Migration, Risiko und Rückfallweg nachgewiesen wird. Der laufende Gateway-Stand wird dafür nicht still verändert. Kritische Risiken werden ausdrücklich und zeitnah gemeldet.

## Bewusst nicht Teil des ersten Auftrags

Universal-SDK, neue OS-Generation, vollständige Sicherheits-Härtung, Overlayroot/Secure Boot, Containerisierung des IgH-Zyklus, vollständige Extension-Neuentwicklung.
