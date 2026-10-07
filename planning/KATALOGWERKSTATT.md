# Katalogwerkstatt · erste Ausbaustufe

Start: `Level-Werkzeug.cmd`. Die Werkstatt ist ausschließlich im Godot-PC-Werkzeug erreichbar; exportierte Spieler können sie nicht starten. `tools/build_player.py` erstellt APKs ohne Werkstattmodule, private Beispiele, Tests und Werkzeuge.

1. **Öffnen → Katalogmotiv auswählen**: Suche nach Motivname oder Sammlung, Auswahl und Öffnen. Auch die neun Einstiegsmotive sind enthalten.
2. Pfeile, Farben und Flächen wie gewohnt bearbeiten. **Bilddaten** enthält Abschlusstext, Textart und optionale Quellen.
3. **Speichern** aktualisiert das ursprüngliche Rätsel, den Katalogtitel, die Zuordnung und den Abschlusstext. Dateiname und Reihenfolge bleiben erhalten. **Öffnen → Kopie speichern** exportiert stattdessen eine separate Datei.
4. Auf dem Handy werden Änderungen erst mit einer neu gebauten APK sichtbar.

Vor dem Schreiben werden gültige vollständige Füllung und Lösbarkeit geprüft. Änderungen eines anderen Editorfensters verhindern das Überschreiben. Alle betroffenen Originaldateien liegen in `work/catalog-backups/`. Bei einem gemeldeten Schreibfehler werden vorherige Dateien zurückgeschrieben. Die Sicherungen sind vom Spielerexport ausgeschlossen.

`collections/editor_overrides.json` schützt bearbeitete Motive vor automatischem Neugenerieren, Umfärben und dem Zurücksetzen ihrer Texte. Reine Farb- und Textänderungen behalten die Kompatibilität vorhandener Spielstände; Änderungen der Pfeilgeometrie erfordern einen neuen Rätselstart.

Noch ausstehend: Löschen mit Papierkorb und Wiederherstellung, Verschieben zwischen Sammlungen, bebilderte Katalogverwaltung sowie eine komfortable Oberfläche für Sicherungswiederherstellung. Die aktuelle Dateisicherung ersetzt noch kein dauerhaftes Transaktionsjournal für einen Stromausfall während mehrerer Schreiboperationen.
