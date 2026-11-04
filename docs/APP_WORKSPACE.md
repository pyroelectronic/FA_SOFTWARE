# FA-Anwendungsworkspace — aktuellen Zustand prüfen, nicht ungeprüft migrieren

Der übergebene **Teilquellstand** `src/extension.ts` erzeugt aktuell im VS-Code-Workspace:

```text
<workspace-root>/
  devices.json
  <geraet>/
    project/
      apps/ ai/ config/ data/ devices/ drivers/ logs/ scripts/ tests/
    nodered/
```

Remote nutzt die Extension laut Teilquelle `/home/<sshUser>/friedrich-projects/workspace/` mit `project/` und `nodered/` als Geschwisterverzeichnissen. Push überträgt nur `project/`, Pull dagegen beide.

**Achtung:** Der zuletzt gezeigte Explorer-Screenshot stellt einen Ordner `nodered/project/` dar. Das ist nicht identisch mit der oben beschriebenen Struktur der Teilquelle. Ob es eine andere Extension-Version, einen manuell eingerichteten Workspace oder nur einen anderen Ansichts-/Root-Pfad betrifft, ist **noch ungeklärt**. Nicht stillschweigend vereinheitlichen.

Für Node-RED gibt es zusätzlich den Container-/Datenpfad `/data` und den Project-Modus. Zuerst muss anhand der vollständigen Extension und der aktiven Node-RED-Konfiguration geprüft werden, wo die **führende** Projekt- und Flow-Quelle liegt und wie Änderungen gesichert werden.

`data/`, `logs/` und Node-RED-Persistenz sind nicht mit Git-Quellcode gleichzusetzen; sichere Backup-/Sync-Regeln sind vor jeder Migration nötig.
