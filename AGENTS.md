# AGENTS.md — Arbeitsregeln für Codex im FA_SOFTWARE-Repository

## Autorität
1. Übergeordnet: `pyroelectronic/FRIEDRICH-AUTOMATION` (`CURRENT_STATE.md`, `DECISIONS.md`, Issues); ein Widerspruch muss gemeldet werden.
2. Dieses Repository: `ARCHITECTURE.md`, Bereichs-README und der jeweils freigegebene `codex/`-Auftrag.
3. Eigenständige Produkt-Repositories: dortige `AGENTS.md`/Spezifikationen für die betreffende Produktentwicklung.
4. Historische Chatverläufe und Referenzarchive sind **kein** Ersatz für aktuelle, verifizierte Anforderungen.

## Arbeitsweise
- Genau **einen** Auftrag/einen Bereich pro Durchlauf bearbeiten; nichts beiläufig in einem anderen Bereich umbauen.
- Erst eine verifizierte Baseline feststellen; neue Arbeit auf identifizierbarer Quelle, Änderungen klein halten.
- Die Wörter `berichtet`, `statisch geprüft`, `gebaut`, `auf Hardware getestet`, `freigegeben` **nicht gleichsetzen**.
- Niemals über Dateien/Versionen spekulieren, die Codex nicht lesen konnte. Unklarheit kennzeichnen.
- Keine generischen Frameworks, neuen Protokollpflichten oder SDK-Abstraktionen ohne konkrete bestehende Verwendung.

## Innovation ausdrücklich erwünscht — ohne blinde Migration
- Vorhandene, funktionierende Lösungen sind **zu verstehen und als Referenz zu schützen**, aber **keine unantastbare Architekturvorgabe**.
- Codex **soll** bei einem konkreten Problem eine nachweisbar einfachere, robustere, sicherere oder wartbarere Lösung **aktiv vorschlagen**, auch wenn sie den bisherigen Ansatz ersetzt.
- Vorschläge als **Option** kennzeichnen und mindestens vergleichen: `Beibehalten`, `gezielt verbessern`, `ersetzen` (sofern sinnvoll). Jeweils Nutzen, Risiken, Voraussetzungen, Aufwand, Test- und Rückfallweg angeben. Keine erzwungene Dreifachanalyse für triviale Fragen.
- Entscheidungen trifft Johannes nach gemeinsamer technischer Bewertung; vor der Freigabe **keine Bestandsmigration**, keine Änderungen an produktiven Pfaden, keine stillen API-/Datenformatwechsel.
- Hypothesen und neue Ideen **dürfen in isolierten Experimenten** überprüft werden, sofern der jeweilige Auftrag dies erlaubt; Experimente sind keine freigegebenen Releases.
- Bei Unstimmigkeiten zwischen Altquelle, Dokumentation und Live-Gerät nicht pauschal 'schlecht' urteilen, sondern die Ursache und damalige Absicht ermitteln. **Kritische Sicherheits-/Datenverlustrisiken klar melden**, auch wenn eine Alt-Lösung bisher funktioniert.

## Git-Grenze
Codex darf **keine Git-Schreiboperationen** ausführen: kein `git add`, `commit`, `tag`, `push`, `checkout`, `switch`, `reset`, `restore`, `rebase` oder `cherry-pick`. `git status`/`diff`/`log` nur lesend. Johannes übernimmt Commits, Tags und Veröffentlichung.

## Änderungen an Gateway oder Server
- **Kein Flashen, Kernel-Build-/Installationsversuch, APT-/PIP-Upgrade, Neustart, Ändern von Netzwerk-/SSH-/Boot-Einstellungen, systemd-Start/Stop oder Docker-Operationen**, außer ein späterer expliziter, abgegrenzter Auftrag gibt das frei.
- Keine Änderung an Sicherheitsfunktionen/Boot-Konfiguration ohne gesonderte Risiko-/Rollback-Betrachtung.
- Nicht benötigte Pakete nicht vorsorglich installieren; vorhandene funktionierende Konfiguration nicht 'aufräumen', bevor sie dokumentiert ist.
- Keine destruktiven Befehle (insb. `rm -rf`, `docker compose down -v`, Überschreiben von Images, Löschen persistenter Daten).
- Bei Hardwaretests nur Kommandos **vorschlagen**; Johannes führt reale Tests und Freigaben aus.

## Daten und Lizenzen
- Geheimnisse und individuelle Zugangsdaten niemals in Dateien oder Ausgaben kopieren; nur Platzhalter in Beispielen.
- Externe große NVIDIA-/Forecr-/Seeed-Quellen und Build-Bäume nicht ins Git-Repository kopieren. Herkunft und SHA-256 im Artefaktregister notieren.
- Lizenzbedingungen für SDK-/Drittanbieter-Abhängigkeiten prüfen, bevor Inhalte verteilt werden.

## Prüfnachweis pro Auftrag
1. Baseline (Dateien, Versionen, Quelle, unbekannte Punkte).
2. Eindeutiger Aufgabenbereich, Befunde und umgesetzte Änderungen (falls erlaubt).
3. Tatsächlich durchgeführte Prüfungen und ihre Resultate.
4. Risiken, fehlende Tests und Rollback.
5. **Genau ein** nächster kleiner, überprüfbarer Schritt.
6. Wenn eine plausible technische Verbesserung erkennbar ist: eine **begründete Alternative** nennen; Status strikt als Vorschlag kennzeichnen und ohne Freigabe nicht umsetzen.

## Aktuelle Leitplanken
- IgH ist vorgesehener EtherCAT-Master; TwinCAT bleibt Engineering-/Referenzumgebung, SOEM nicht wieder als aktuelle Basis einführen.
- Zeitkritischer EtherCAT-Zyklus zunächst auf Host; keine blockierenden MQTT-/DB-Operationen im Zyklus.
- Node-RED, MQTT, PyTorch etc. sind optional und abhängig vom Projekt.
- Erst funktionierende Bausteine, dann SDK-Wiederverwendung.
- Für `codex/01_GATEWAY_BESTAND.md` gilt **strikt nur lesende Prüfung**.
