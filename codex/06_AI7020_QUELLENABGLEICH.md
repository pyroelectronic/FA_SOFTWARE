# Codex – Auftrag 06: AI7020-BSP-Quellenstand korrigieren (zunächst nur lesen)

**Ausgangslage:** Nach der bisherigen Prüfung ist die tatsächlich ausführlichere Arbeitsanleitung `AI7020_install_config` (Version 1.2.0) samt Konsolenmitschnitt aufgetaucht. Sie beschreibt den AI7020-BSP-/Flash-Ablauf. Die vorherige Analyse des älteren `AI7XX0.sh` betrifft eine **andere Phase** (Provisionierung nach Flash), nicht dieselbe Datei.

## Quellen

1. `AGENTS.md`, `ARCHITECTURE.md` und `docs/AI7020_QUELLENKORREKTUR.md`.
2. `platform/gateway/bsp/r36.4.0/references/AI7020_install_config_REFERENCE_REDACTED.txt` (sanitisierte Lesefassung).
3. Wenn verfügbar: `local-assets/gateway/AI7020_build_console.txt` (unveränderter historischer Konsolenmitschnitt, nicht in Git).
4. Das bereits vorhandene `platform/gateway/bsp/r36.4.0/BUILD_FLASH_GUIDE.md`, den bisherigen Auftrag 05 und die älteren historischen Quellen. Keine stillschweigende Gleichsetzung verschiedener AI7XX0-Modelle.

## Ziel (begrenzt)

- Trenne sauber **BSP-Build / Flash-Vorbereitung** und **Gateway-Software-Provisionierung nach dem Flash**.
- Ordne die dokumentierte Hardware dem **AI7020 / Orin Nano 4GB** zu und vergleiche dies mit dem vorläufigen generischen Orin-NX-Leitfaden. Keine Hardwareeigenschaften raten.
- Stelle die tatsächlich dokumentierte historische Reihenfolge aus Anleitung und Konsole gegenüber: RootFS, Kernel/.config, In-Tree-Module, OOT-Module, DTB, `apply_binaries.sh`, BCT/Pinmux, Kopieren, SDK Manager/CLI.
- Prüfe die Widersprüche **`CONFIG_LAN743X=y` in der Anleitung gegen das gebaute `lan743x.ko`**, die mehrfachen Installationsorte, die mögliche Überlagerung von Kernelmodulen durch `apply_binaries.sh` und den abweichenden Benutzernamen im Beispielkommando.
- Prüfe, welche Teile des Konsolenlogs tatsächlich einen Erfolg beweisen und welche Schritte (DTB, Flash, Boot, Funktion) dadurch nicht nachgewiesen sind.
- Liefere konkrete **Änderungsvorschläge** für `BUILD_FLASH_GUIDE.md` und das Quellen-/Baseline-Register, aber überschreibe sie noch nicht.
- Formuliere **genau einen kleinen nächsten Umsetzungsschritt**, der ohne Live-Gateway und ohne vollständigen BSP-Neubau möglich ist.

## Arbeitsregeln

- Nur lesender Abgleich: keine Änderungen, Builds, Paketinstallationen oder Flashvorgänge; **keine Git-Schreibaktionen**.
- Dokumentierte Entwickler-Hardwaretests respektieren, aber als berichtet kennzeichnen.
- Keine generische Empfehlung zur Umstellung auf `minimal`/`basic`, JetPack 7, Overlays oder ein neues Framework ohne nachgewiesenen Vorteil.
- Bessere technische Wege vorschlagen **dürfen**, aber mit Ursache, Nutzen, Aufwand, Test und Rückfallweg.
- Zugangsdaten und private Pfade nicht unnötig im Bericht wiederholen; niemals Zugangsdaten in neue Dateien übernehmen.
- Falls das lokale Konsolenlog fehlt, offen benennen und keine Logbefunde erfinden.

## Ergebnis

Ein kompakter Soll-/Ist-Abgleich (tatsächlich belegt / vom Entwickler berichtet / offen) und ein klarer Vorschlag, welche minimalen Dokumentkorrekturen wir als Nächstes freigeben sollten.
