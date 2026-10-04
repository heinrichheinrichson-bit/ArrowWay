# ArrowWay starten

Auf diesem PC kannst du auch einfach `ArrowWay.cmd` doppelklicken.

1. Godot 4 Standard öffnen (die vorhandene Version 4.7.2 funktioniert).
2. Im Projektmanager **Importieren** wählen und `project.godot` aus diesem Ordner auswählen.
3. Das Projekt öffnen und **F5** drücken.

## Spielen

Tippe oder klicke auf einen farbigen Pfad. Nur wenn die Richtung seiner Spitze frei ist, kann er entkommen. Blockierte Pfade federn kurz zurück und blinken rot. Neu geöffnete Wege leuchten kurz stärker in ihrer eigenen Farbe. Die Glühbirne oben rechts lässt einen freien Pfad weiß leuchten; der kreisförmige Pfeil daneben startet das Rätsel neu. Nach begonnenem Spiel wird der Neustart bestätigt. Sobald alle Pfade entfernt sind, erscheint **Weiter**. Freigeschaltete Levels bleiben lokal gespeichert. Soundeffekte schaltest du im **Hauptmenü → Einstellungen** ein oder aus; die Einstellung bleibt gespeichert.

Das Spiel startet im Hauptmenü. **Deine Reise** öffnet den geschwungenen Weg durch sieben Themenwelten. **Weiter spielen** setzt das laufende Puzzle fort. Der Zurück-Pfeil im Puzzle führt zur passenden Sammlung; dein laufendes Puzzle bleibt erhalten.

Ziehe die Karte mit dem Finger nach oben oder unten; am PC funktioniert auch das Mausrad. Zukünftige Themen sind blass zu sehen. Ihre Sammlungen und Motive erscheinen erst, wenn du sie erreichst. Nach drei geschafften Einstiegsmotiven öffnet sich Natur. Innerhalb einer Themenwelt öffnen drei geschaffte Motive erste Abzweigungen, fünf die weiteren Abzweigungen und die nächste Themenwelt. Jede erreichte Sammlung bietet zunächst drei Motive; jedes geschaffte Motiv öffnet ein weiteres. Geschaffte Motive kannst du jederzeit erneut spielen.

**Suchen & Favoriten** durchsucht deine freigeschalteten Motive nach Titel, Sammlung und Thema. Der Stern einer Motivkarte merkt sie als Favorit. **Eigene Motive** sind unabhängig vom Reisefortschritt sofort spielbar. Mehr zur neuen Karte und ihren Ansichten steht in [JOURNEY.md](JOURNEY.md).

## Level-Werkzeug starten

Das Werkzeug ist für die Erstellung unserer Levels gedacht. Es gehört nicht zur Spieleroberfläche.

Unter Windows `Level-Werkzeug.cmd` doppelklicken. Die **Motivwerkstatt** öffnet das aktuelle Motiv mit seiner Pfeilfüllung. Im normalen Spiel sind diese Werkzeuge nicht sichtbar.

1. **Öffnen → Bild, Motiv oder Level-Datei** lädt eine Vorlage oder ein vorhandenes ArrowWay-Motiv. Zum Übernehmen eines früher lokal gespeicherten Entwurfs **Öffnen → Letzten lokalen Entwurf laden** wählen.
2. **Pfeile & Farben** dient zur Auswahl und Farbgestaltung einzelner Pfeile. Zuletzt verwendete Farben sind direkt sichtbar. **Gesamtansicht / Esc** zeigt das ganze Motiv ohne Hervorhebung.
3. Unter **Vorlage & Flächen** neue Bereiche malen. Bestehende Pfeile bleiben erhalten. **Freie Flächen mit Pfeilen füllen** ergänzt nur ungefüllte Stellen.
4. Die Werkzeuge oben zeichnen, löschen und spiegeln eigene Pfeile oder setzen ihre Spitze ans gewünschte Ende.
5. **Speichern** sichert einen benannten JSON-Entwurf. **Im Spiel testen** prüft vollständige Füllung und Lösbarkeit und startet das Puzzle.

Die vollständige Anleitung steht in [MOTIVWERKSTATT.md](MOTIVWERKSTATT.md). Unter `examples/` liegen Vorlagen zum Ausprobieren. Nach dem Spieltest **Export** wählen und einen eigenen JSON-Dateinamen im Ordner `levels/` speichern. **ArrowWay.cmd** starten und im Hauptmenü **Eigene Motive** öffnen: zusätzliche Exporte erscheinen automatisch als direkt spielbare eigene Motive. Die ursprünglichen neun Spielslots müssen nicht ersetzt werden.

Spielstände und lokale Sicherungen liegen unter `%APPDATA%\Godot\app_userdata\ArrowWay\`. Tests verwenden separate Dateien mit dem Präfix `test_`.

Alle Titel, Vorschauen und bearbeitbaren Leveldateien stehen in [CATALOG.md](CATALOG.md).

Die Spielansicht passt das Motiv an den verfügbaren Bildschirm an. Zwei-Finger-Zoom und Verschieben sind für einen späteren Ausbau vorgesehen; die aktuelle Version vergrößert automatisch und erleichtert versetzte Fingertipps. Auf echten Smartphones müssen Touchgefühl und Bildschirmränder anschließend noch geprüft werden.
