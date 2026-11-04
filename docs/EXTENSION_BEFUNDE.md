# VS-Code-Extension — vorläufiger Befund aus den übergebenen Teilquellen

Quellen: `src.zip` (enthält `src/extension.ts` und einfachen Beispieltest), `out.zip` (kompilierter JS-Output) sowie `CHANGELOG(1).md` (bis 0.4.2).

**Gutes Fundament:** Geräteverwaltung, SSH-Terminal, Remote-SSH, Portainer/Node-RED öffnen, Push/Pull, Projektordneranlage. Keine Neuentwicklung ohne Grund.

## Kritische Punkte zur Prüfung
1. **Push/Pull sind asymmetrisch**: Push kopiert nur `project/`; Pull kopiert Remote-`workspace/` einschließlich `nodered/`. Kein automatischer Projektabgleich der Node-RED-Flows.
2. **Node-RED-Quellstand unklar**: Installer nutzt `/home/<user>/friedrich-projects/nodered_runtime:/data`, daneben `/home/<user>/friedrich-projects/workspace/nodered/projects:/data/projects`. In der Extension ist der lokale `nodered/`-Ordner nicht Bestandteil des Push. Ob `/data/projects` zum tatsächlich aktiven Node-RED-Projektmodus passt, muss durch Live-Konfiguration geklärt werden.
3. **Destruktives Ersetzen**: Push-Option 'Remote ersetzen' sendet `rm -rf` vor SCP; Pull-Option 'Lokal ersetzen' entfernt Verzeichnis vor dem Transfer. Es gibt keinen nachgewiesenen zweiphasigen, atomaren Austausch und keine erfolgreiche Transferprüfung. Risiko: Datenverlust bei Verbindungsfehlern.
4. **Statusmeldungen**: Terminalkommandos werden abgeschickt und 'gestartet' gemeldet; das ist noch keine Transferbestätigung.
5. **Sicherheit/Robustheit**: Pfad-/Shell-Quoting bei SSH/SCP aus Benutzereingaben; Konflikte mit Daten/Logs; Lösch- und Mergeverhalten; SSH-Hostkey-Verifikation und Reset müssen bewusst geprüft werden.
6. **Tests**: übergebener `extension.test.ts` ist ein allgemeiner Beispielsuite-Test, keine funktionale Synchronisationsprüfung.
7. **Teilquellen**: Es fehlen mindestens `package.json`, `tsconfig.json`, Assets/Views und ggf. weitere Projektdateien. `out/` ist **Build-Ausgabe**, nicht die Quellbasis.

**Noch offen:** Der letzte Explorer-Screenshot zeigt `nodered/project/`, die Teilquelle legt `project/` und `nodered/` als Geschwister an. Vor irgendeiner Migration Workspace-Root und tatsächlich genutzte Version klären. Siehe `docs/APP_WORKSPACE.md`.

## Sofortige Folgerung
Fürs Erste **keinen ungetesteten Push/Pull-Replace auf wertvollen Projekten** ausführen. Extension nicht ungeprüft in neuen Ordner umziehen. Erst Version, vollständiges Repo und aktiven Node-RED-Projektpfad verifizieren; dann sichere Transferlogik in separatem kleinen Auftrag.
