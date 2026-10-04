# ArrowWay starten

1. Godot 4 Standard öffnen (die vorhandene Version 4.7.2 funktioniert).
2. Im Projektmanager **Importieren** wählen und `project.godot` aus diesem Ordner auswählen.
3. Das Projekt öffnen und **F5** drücken.

## Spielen

Tippe oder klicke auf einen farbigen Pfad. Nur wenn die Richtung seiner Spitze frei ist, kann er entkommen. Blockierte Pfade blinken rot. **Hinweis** lässt einen freien Pfad weiß leuchten. Sobald alle Pfade entfernt sind, erscheint **Nächstes Puzzle**. Freigeschaltete Levels bleiben lokal gespeichert.

## Eigenes Puzzle bauen

1. **Editor** öffnen und oben Haus, Weihnachtsbaum oder Herz wählen.
2. **Füllen** erzeugt eine neue lösbare Füllung. Jeder Klick erzeugt eine andere Variante.
3. Mit **Auswahl** einen Pfad anklicken. **Drehen** kehrt seine Pfeilrichtung um; **Zurück** entfernt ihn.
4. Mit **Leer** kannst du von einer leeren Schablone starten.
5. **Zeichnen** wählen und Rasterpunkte anklicken. Das Programm verbindet sie rechtwinklig; bei schräg liegenden Klicks erst horizontal, dann vertikal.
6. **Fertig** oder Enter schließt den Pfad ab. Rücktaste nimmt den letzten Punkt zurück; Escape verwirft die angefangene Linie.
7. **Prüfen** testet die Lösbarkeit. Bei einer Blockade werden die nach den möglichen Zügen verbleibenden Pfade rot markiert.
8. **Testen** startet das Puzzle; **Im Editor** bringt dich zur bearbeitbaren Version zurück.
9. **Speichern** sichert ein eigenes Puzzle lokal. **Laden** öffnet es im Editor; **Eigenes Puzzle** startet es zum Spielen.

Es gibt aktuell einen Speicherplatz für eigene Puzzle. Neue Speicherung ersetzt diesen Platz. Editoränderungen werden erst durch **Speichern** dauerhaft gesichert. Der Wechsel der Schablone ersetzt die aktuellen Pfade.

Spielstände liegen unter `%APPDATA%\Godot\app_userdata\ArrowWay\`. Tests verwenden separate Dateien mit dem Präfix `test_`.
