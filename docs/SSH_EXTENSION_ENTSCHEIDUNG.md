# Engineering-Zugriff — vorläufige Entscheidung

**Entscheidung:** Die bestehende Friedrich-Automation-VS-Code-Extension wird als funktionierender Ansatz vorläufig weiterverwendet. SSH/Remote-SSH/SCP ist ein angemessener technischer Grundmechanismus; eine dauerhafte Client-Server-Agentenarchitektur ist **nicht** beschlossen.

## Warum nicht sofort neu?
- Bekannte Geräteverwaltung und Arbeitsverzeichnisse funktionieren bereits in der Laborpraxis.
- Der vollständige Extension-Quellstand ist noch nicht übergeben.
- Ein zusätzlicher Gateway-Agent erzeugt neue Angriffsfläche, Update- und Wartungsanforderungen.

## Gezielte spätere Bewertung
1. Vollständigen Source/Buildstand verifizieren.
2. Projektspeicher, Node-RED-Projects und aktive Flow-Dateien bestimmen.
3. Push/Pull/Replace auf Testdateien prüfen, insbesondere Abbruch mitten im Transfer und Konflikte.
4. Optionen vergleichen: SSH+SCP, SSH+rsync/staging, Remote-SSH-basierte Arbeit, optional später Management-API.
5. Kleinstmögliche robuste Lösung real implementieren; Testnachweise vor Erweiterung.

**Vorläufiger Schutz:** Keine verlustgefährdenden Replace-Operationen auf produktiven Projekten; Quellstand, Konfiguration und Laufzeitdaten getrennt sichern.
