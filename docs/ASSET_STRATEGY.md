# Große Dateien und Referenz-Builds

## Warum getrennt?
NVIDIA BSP-Downloads, entpackte `Linux_for_Tegra`-Bäume, Kernel-Builds, Docker-Images, CUDA-Wheels und Flash-Images können mehrere Gigabyte umfassen. Vollständige Arbeitsverzeichnisse sind **kein sinnvoller Git-Quellbestand**.

## Vorgehen
- Originalarchive an einem separaten, gesicherten Speicherort verwahren (z. B. NAS/Backup-Laufwerk, interne Artefaktablage). **Nicht** nur als lokale ungesicherte Kopie.
- Jedes externe Artefakt besitzt einen Manifest-Eintrag: ID, Dateiname, Hersteller/Herkunft, Lizenz/Verteilung, Release, SHA-256, Ablageort (ohne Geheimnisse), Bezug zur freigegebenen Baseline.
- Im Git-Repo liegen eigene Patches, Build-/Flash-Skripte, Konfigurationen, Versionslisten und Tests. Externe Lieferpakete werden zur Reproduktion nachgeladen bzw. aus interner Ablage bereitgestellt.
- Kernel-/Treiberänderungen möglichst als Patch zu einem **exakt festgelegten Upstream-Release**, nicht als Komplettkopie von Gigabyte-Quellbäumen.
- Binärimages bei Bedarf separat versionieren und sichern; nicht automatisch nach Git LFS ausweichen. LFS ist nur nach bewusstem Abwägen von Hosting, Zugriffsrechten und Größe sinnvoll.
- Für Kunden-Auslieferung separat Build-Artefakte, SBOM/Komponentenliste, Sicherungen, Wiederherstellungsweg und Hashes bereitstellen.

## Sicherheit
Das hochgeladene AI7XX0-Installationsskript enthält feste MQTT-Zugangsdaten; Originale nicht ungeprüft veröffentlichen. Vor externer Verwendung Credentials austauschen und mit Variablen/Provisioning-Mechanismus arbeiten. Drittanbieter-Dateien nur im Rahmen ihrer Lizenzen verteilen.
