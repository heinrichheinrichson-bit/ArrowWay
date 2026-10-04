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

Unter Windows `Level-Werkzeug.cmd` doppelklicken. Die **Motivwerkstatt** öffnet das aktuelle Motiv mit seiner Pfeilfüllung. Im normalen Spiel sind diese Werkzeuge nicht sichtbar.

1. **Öffnen → Bild, Motiv oder Level-Datei** lädt eine Vorlage oder ein vorhandenes ArrowWay-Motiv. Zum Übernehmen eines früher lokal gespeicherten Entwurfs **Öffnen → Letzten lokalen Entwurf laden** wählen.
2. **Pfeile & Farben** dient zur Auswahl und Farbgestaltung einzelner Pfeile. Zuletzt verwendete Farben sind direkt sichtbar. **Gesamtansicht / Esc** zeigt das ganze Motiv ohne Hervorhebung.
3. Unter **Vorlage & Flächen** neue Bereiche malen. Bestehende Pfeile bleiben erhalten. **Freie Flächen mit Pfeilen füllen** ergänzt nur ungefüllte Stellen.
4. Die Werkzeuge oben zeichnen, löschen und spiegeln eigene Pfeile oder setzen ihre Spitze ans gewünschte Ende.
5. **Speichern** sichert einen benannten JSON-Entwurf. **Im Spiel testen** prüft vollständige Füllung und Lösbarkeit und startet das Puzzle.

Die vollständige Anleitung steht in [MOTIVWERKSTATT.md](MOTIVWERKSTATT.md). Unter `examples/` liegen Vorlagen zum Ausprobieren. Die Spielslots befinden sich in `levels/01.json` bis `levels/09.json`; fertige Motive können nach dem Spieltest über die Exportfunktion in einen Slot geschrieben werden.

Spielstände und lokale Sicherungen liegen unter `%APPDATA%\Godot\app_userdata\ArrowWay\`. Tests verwenden separate Dateien mit dem Präfix `test_`.
