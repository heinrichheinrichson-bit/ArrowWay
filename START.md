# ArrowWay starten

Auf diesem PC kannst du auch einfach `ArrowWay.cmd` doppelklicken.

1. Godot 4 Standard öffnen (die vorhandene Version 4.7.2 funktioniert).
2. Im Projektmanager **Importieren** wählen und `project.godot` aus diesem Ordner auswählen.
3. Das Projekt öffnen und **F5** drücken.

## Spielen

Auf Android startet ArrowWay im festen Hochformat und bleibt auch beim Drehen des Geräts im Hochformat.

Tippe oder klicke auf einen farbigen Pfad. Nur wenn die Richtung seiner Spitze frei ist, kann er entkommen. Blockierte Pfade federn kurz zurück und blinken rot. Neu geöffnete Wege leuchten kurz stärker in ihrer eigenen Farbe. Die Glühbirne oben rechts lässt einen freien Pfad weiß leuchten; der kreisförmige Pfeil daneben startet das Rätsel neu. Nach begonnenem Spiel wird der Neustart bestätigt. Sobald alle Pfade entfernt sind, erscheint **Weiter**. Freigeschaltete Levels bleiben lokal gespeichert. Soundeffekte schaltest du im **Hauptmenü → Einstellungen** ein oder aus; die Einstellung bleibt gespeichert.

Das Spiel startet im Hauptmenü. **Deine Reise** öffnet den geschwungenen Weg durch sieben Themenwelten. **Weiter spielen** setzt das laufende Puzzle fort. Der Zurück-Pfeil im Puzzle führt zur passenden Sammlung; dein laufendes Puzzle bleibt erhalten.

Ziehe die Karte mit dem Finger nach oben oder unten; am PC funktioniert auch das Mausrad. Auf dieser einen Mindmap führen sichtbare Pfade von den großen Themenwelten zu ihren Unterkategorien. Ein Klick auf eine Themenwelt bleibt auf der Karte, ein Klick auf eine Unterkategorie öffnet direkt alle ihre Rätselbilder. Gelöste und ungelöste Bilder stehen zusammen in fester Reihenfolge. Zurück führt wieder auf dieselbe Mindmap.

Zukünftige Themen sind blass sichtbar, ihre Unterkategorien bleiben verborgen. Erst wenn sämtliche Rätsel einer Themenwelt gelöst sind, erhält sie ein Häkchen und die nächste Welt wird verfügbar. Unterkategorien erhalten ihr Häkchen ebenfalls erst nach sämtlichen zugehörigen Rätseln. Für Natur müssen daher zunächst alle neun Einstiegsmotive gelöst sein. Bereits erreichte Themen bleiben verfügbar.

**Meine Kunstwerke** enthält nur Bilder, die du bereits gelöst hast. Ein Bild öffnet sich groß zum Anschauen. Dort kannst du ein Herz setzen oder entfernen und das Rätsel erneut spielen. **Lieblingsbilder** zeigt nur gelöste Bilder mit Herz. Offene und verborgene Rätsel werden im Album nicht angezeigt.

Das Hauptmenü zeigt eine Vorschau des nächsten spielbaren Motivs. Ein bereits begonnenes Rätsel ist in seiner Übersicht durch **Fortsetzen** und einen helleren Rahmen markiert. Auf Android führt die Zurück-Geste aus dem Bild zurück ins Album, aus der Rätselübersicht zurück zur Mindmap und aus Einstellungen zurück ins Hauptmenü. Zurück im Hauptmenü beendet die App. Mehr zur Karte steht in [JOURNEY.md](JOURNEY.md).

## Level-Werkzeug starten

Das Werkzeug ist für die Erstellung unserer Levels gedacht. Es gehört nicht zur Spieleroberfläche.

Unter Windows `Level-Werkzeug.cmd` doppelklicken. Die **Motivwerkstatt** öffnet das aktuelle Motiv mit seiner Pfeilfüllung. Im normalen Spiel sind diese Werkzeuge nicht sichtbar.

1. **Öffnen → Bild, Motiv oder Level-Datei** lädt eine Vorlage oder ein vorhandenes ArrowWay-Motiv. Zum Übernehmen eines früher lokal gespeicherten Entwurfs **Öffnen → Letzten lokalen Entwurf laden** wählen.
2. **Pfeile & Farben** dient zur Auswahl und Farbgestaltung einzelner Pfeile. Zuletzt verwendete Farben sind direkt sichtbar. **Gesamtansicht / Esc** zeigt das ganze Motiv ohne Hervorhebung.
3. Unter **Vorlage & Flächen** neue Bereiche malen. Bestehende Pfeile bleiben erhalten. **Freie Flächen mit Pfeilen füllen** ergänzt nur ungefüllte Stellen.
4. Die Werkzeuge oben zeichnen, löschen und spiegeln eigene Pfeile oder setzen ihre Spitze ans gewünschte Ende.
5. **Speichern** sichert einen benannten JSON-Entwurf. **Im Spiel testen** prüft vollständige Füllung und Lösbarkeit und startet das Puzzle.

Die vollständige Anleitung steht in [MOTIVWERKSTATT.md](MOTIVWERKSTATT.md). Unter `examples/` liegen Vorlagen zum Ausprobieren. Nach dem Spieltest **Export** wählen und einen eigenen JSON-Dateinamen im Ordner `levels/` speichern. Der Export bleibt ein interner Entwurf. Zum Aufnehmen ins Spiel den Pfad und die gewünschte Unterkategorie in `collections/published.json` eintragen, zum Beispiel `{"path":"res://levels/10.json","group":"fantasy"}` in dessen `levels`-Liste. Das Motiv erscheint dann als normales Rätsel dieser Unterkategorie und folgt deren Freischaltungsregeln. Im Hauptmenü der Spieler gibt es weder Editor noch Eigene Motive. Die ursprünglichen neun Spielslots müssen nicht ersetzt werden.

Spielstände und lokale Sicherungen liegen unter `%APPDATA%\Godot\app_userdata\ArrowWay\`. Tests verwenden separate Dateien mit dem Präfix `test_`.

Alle Titel, Vorschauen und bearbeitbaren Leveldateien stehen in [CATALOG.md](CATALOG.md).

Die Spielansicht passt das Motiv an den Bildschirm an. **Zwei Finger auseinanderziehen** vergrößert es bis zum Vierfachen. Mit zwei Fingern kannst du gleichzeitig verschieben; im vergrößerten Bild verschiebt auch **ein Finger** das Motiv. Ein kurzer Tipp schießt den Pfeil erst beim Loslassen weg, damit Wischen und Zoomen keine Spielzüge auslösen. Zwei Finger zusammenziehen zeigt wieder das ganze Motiv. Am PC funktionieren Mausrad und Ziehen mit gedrückter linker Maustaste. Neustart und Abschluss setzen die Ansicht auf das vollständige Kunstwerk zurück. Beim Besuch der Menüs bleibt dein Zoom erhalten. Auf dem echten Smartphone müssen Touchgefühl und Bildschirmränder noch geprüft werden.

## Automatisch fortsetzen

Begonnene Rätsel werden automatisch gespeichert. Weiter spielen setzt das aktuelle Motiv mit den verbliebenen Pfeilen, Zoom und Bildposition fort. Du kannst mehrere Motive beginnen und später einzeln weiterführen. Ein bestätigter Neustart verwirft nur den aktuellen Rätselstand. Das Level-Werkzeug speichert weiterhin separat seine eigenen Entwürfe.

