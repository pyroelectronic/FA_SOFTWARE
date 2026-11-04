# Changelog

## [1.3] – 2025-09-21
### Changed
- `AI7XX0_safe_upgrade.sh` **verschlankt** (unnötige Software entfernt: Brave, Firefox, Cockpit, Cockpit-App LinkExplorer).
- Node-RED Installation angepasst: läuft jetzt im Docker-Container mit Bind-Mount ins globale Projektverzeichnis (`friedrich-projects`).
- Installation von **InfluxDB2** vereinheitlicht: 
  - Standard-Setup für `AI7020` und `AI7100`.
  - Separate Buckets (`ai7020-bucket`, `ai7100-bucket`) je nach Gerät.
  - Initialisierung mit `DOCKER_INFLUXDB_INIT_MODE=setup` und vordefiniertem Admin-Token.

### Added
- Neuer globaler Projektordner **`friedrich-projects`** unter `/home/$MOSQUITTO_USER/`  
  → zentrale Projektverwaltung für die neue VS Code **Friedrich Automation IDE**.  
- Automatische Rechtevergabe an `$MOSQUITTO_USER`.

### Removed
- Browser-Installationen (Brave, Firefox).  
- Cockpit-Basisinstallation und Cockpit-App **LinkExplorer** (Administrator entscheidet über Installation).  
- Doppelte/überflüssige InfluxDB-Setup-Blöcke (vereinheitlicht).

## [1.2] – 2025-09-15
- Function -> Safe update an upgrade the OS

## [1.1] – 2025-09-21
### Geändert
- Initial Script
