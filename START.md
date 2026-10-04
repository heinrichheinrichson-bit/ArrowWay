# ArrowWay starten

Auf diesem PC kannst du auch einfach `ArrowWay.cmd` doppelklicken.

1. Godot 4 Standard öffnen (die vorhandene Version 4.7.2 funktioniert).
2. Im Projektmanager **Importieren** wählen und `project.godot` aus diesem Ordner auswählen.
3. Das Projekt öffnen und **F5** drücken.

## Spielen

Tippe oder klicke auf einen farbigen Pfad. Nur wenn die Richtung seiner Spitze frei ist, kann er entkommen. Blockierte Pfade federn kurz zurück und blinken rot. Neu geöffnete Wege leuchten kurz stärker in ihrer eigenen Farbe. **Hinweis** lässt einen freien Pfad weiß leuchten. Sobald alle Pfade entfernt sind, erscheint **Nächstes Puzzle**. Freigeschaltete Levels bleiben lokal gespeichert. Die kurzen Klänge kannst du oben mit **Ton: An/Aus** abschalten; diese Einstellung bleibt ebenfalls gespeichert.

**Alle Levels** öffnet die Motivübersicht. Dort siehst du deinen Fortschritt und kannst freigeschaltete Puzzles wählen. **Weiter spielen** bringt dich zum laufenden Puzzle zurück, ohne es neu zu starten. Gesperrte Puzzles werden der Reihe nach freigeschaltet; geschaffte Puzzles bleiben markiert. Nach dem letzten Level kommst du wieder zur Übersicht.

## Level-Werkzeug starten

Das Werkzeug ist für die Erstellung unserer Levels gedacht. Es gehört nicht zur Spieleroberfläche.

Unter Windows `Level-Werkzeug.cmd` doppelklicken. Alternativ Godot mit `--path . -- --editor-tool` starten. Spiel und Werkzeug können in getrennten Fenstern laufen. Das Werkzeug öffnet jetzt automatisch die **Motivwerkstatt** für Bildimport und Flächenbearbeitung. **Bild & Flächen** öffnet sie später erneut. Die Anleitung steht in [MOTIVWERKSTATT.md](MOTIVWERKSTATT.md); unter `examples/` liegen Hausumrisse, eine transparente Palme und eine gelbe Sonne zum Ausprobieren. **Farben & Verläufe · Vorschläge** erzeugt Schattierungen aus einer Grundfarbe; Nach dem Füllen einen Pfeil direkt anklicken und oben sein Farbfeld ändern. **Verläufe …** bietet Schattierungen für diesen Pfeil; Pipetten übernehmen vorhandene Farben.

## Eigenes Puzzle bauen

1. Im Level-Werkzeug oben Haus, Weihnachtsbaum, Herz, Schmetterling, Fisch oder Blume wählen.
2. **Füllen** erzeugt eine neue vollständige, lösbare Füllung und verflechtet die Pfade miteinander. Jeder Klick erzeugt eine andere Variante; die Prüfung braucht einen kurzen Moment.
3. Mit **Auswahl** einen Pfad anklicken. **Drehen** kehrt seine Pfeilrichtung um; **Zurück** entfernt ihn.
4. Mit **Leer** kannst du von einer leeren Schablone starten.
5. **Zeichnen** wählen und Rasterpunkte anklicken. Das Programm verbindet sie rechtwinklig; bei schräg liegenden Klicks erst horizontal, dann vertikal.
6. **Fertig** oder Enter schließt den Pfad ab. Rücktaste nimmt den letzten Punkt zurück; Escape verwirft die angefangene Linie.
7. **Prüfen** testet die Lösbarkeit. Bei einer Blockade werden die nach den möglichen Zügen verbleibenden Pfade rot markiert.
8. **Testen** startet das Puzzle; **Im Editor** bringt dich zur bearbeitbaren Version zurück.
9. **Speichern** sichert einen Entwurf lokal; **Laden** öffnet ihn wieder im Werkzeug.
10. **Export** schreibt eine fertige JSON-Datei. Im Projekt liegen die neun Spielslots `levels/01.json` bis `levels/09.json`. Exportiere in einen dieser Slots und starte das Spiel neu, um das Motiv dort zu spielen. Der Titel wird aus der Leveldatei übernommen.

Es gibt aktuell einen lokalen Speicherplatz für Entwürfe. Neue Speicherung ersetzt diesen Platz. Änderungen werden erst durch **Speichern** oder **Export** dauerhaft gesichert. Der Wechsel der Schablone ersetzt die aktuellen Pfade.

Spielstände liegen unter `%APPDATA%\Godot\app_userdata\ArrowWay\`. Tests verwenden separate Dateien mit dem Präfix `test_`.
