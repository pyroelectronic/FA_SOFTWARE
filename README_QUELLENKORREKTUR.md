# FA_SOFTWARE – Ergänzung AI7020, 04.11.2026

Diese ZIP ergänzt ein vorhandenes FA_SOFTWARE-Repository. Sie **ersetzt weder den alten Installer noch das BSP-Handbuch automatisch**.

1. Inhalt des Unterordners `FA_SOFTWARE/` in die bestehende Repository-Wurzel übernehmen.
2. Die Originaldatei `Copy of the console from AI7020_install_config` **lokal** unter `local-assets/gateway/AI7020_build_console.txt` bereitstellen; dieser Ordner ist von Git ausgeschlossen.
3. Nur die sanitisierte Referenz und die Markdown-Dokumente committen. Die unsanitisierte Original-`AI7020_install_config` enthält einen Klartext-Passwortparameter und gehört nicht ungeprüft nach Git.
4. Mit `codex/06_AI7020_QUELLENABGLEICH.md` lesend starten. Danach entscheiden, ob die bisherigen Handbuchstellen angepasst werden.

**Wichtig:** Die neue Datei beschreibt den AI7020-BSP-/Flash-Ablauf; `AI7XX0.sh` ist eine getrennte, nachgelagerte Softwareinstallation. Die jeweils aktuellste Fassung davon ist noch nicht abschließend zugeordnet.
