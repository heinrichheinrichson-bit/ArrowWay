# ArrowWay

Ein spielbares Godot-Puzzle mit leuchtenden, gerundeten Pfeilpfaden. Die Motive sind auf einem gleichmäßigen Raster vollständig gefüllt: freie Pfade entkommen entlang ihrer Linie, blockierte Pfade bleiben liegen. Das Level-Werkzeug startet separat vom Spiel.

![ArrowWay Haus-Puzzle](previews/house.png)

## Start

Godot **4.x Standard** verwenden; geprüft mit **4.7.2**, GDScript und Compatibility-Renderer. `project.godot` importieren und **F5** drücken. Die ausführliche deutsche Anleitung steht in [START.md](START.md).

## Aktueller Stand · 0.3.0

- Sechs Levels mit 33–41 Pfaden, jeweils vollständig gefüllten Motiven und mehreren Pfeilrichtungen.
- Gerundete Kurven, mehrschichtiger Neon-Leuchtsaum und heller Linienkern.
- Motivfarben: grüner Baum mit braunem Stamm, Haus mit warmem Dach, blauen Wänden, hellen Fenstern und violetter Tür; Herz in Pink- und Rottönen.
- Entkommensanimation entlang der gerundeten Linie, Blockierungsfeedback und Hinweise.
- Levelauswahl, Fortschrittsanzeige und lokal gespeicherte Freischaltungen.
- Separates Level-Werkzeug: Schablone wählen, automatisch füllen, Rasterpfade zeichnen, auswählen, Richtung umkehren, löschen, Lösbarkeit prüfen und direkt testen.
- Entwürfe lokal speichern und laden; fertige Levels als JSON in den Projektordner exportieren.
- Das eigentliche Spiel zeigt keine Editorbedienelemente und lädt fertige Leveldateien aus `levels/`.
- Maus- und Touch-Eingabe; Hochformat mit skalierbarer Darstellung.

## Aufbau

- `puzzle.gd`: Formenmasken, geometrische Blockierungsprüfung und Lösungsfolge.
- `motifs.gd`: gleichmäßige vollständige Füllung, Motivbereiche und Neonpaletten.
- `levels/`: sechs fertige, reproduzierbar erzeugte und geprüfte Leveldateien.
- `main.gd`: Spielzustand, gerundete Animation, Benutzeroberfläche, Werkzeugmodus und Speicherung.
- `board.gd`: Darstellung der Pfade innerhalb des Spielfelds.
- `tests/test_runner.gd`: Spiellogik und Editorintegration.

Die Formen bestehen aus Rasterzellen mit 14 Pixeln Abstand. Der Generator füllt Motivbereiche mit ineinandergreifenden horizontalen und vertikalen Schleifen. Randzellen werden angeschlossen, ohne andere Zellen zu duplizieren. Unvollständige oder unlösbare Varianten werden verworfen. Alle sechs gelieferten Motive sind zu 100 Prozent belegt. Alle Pfade bestehen aus echten Punktfolgen; die Darstellung und Animation runden die Ecken mit kleinen Kreisbögen ab. Die Blockierungsprüfung berücksichtigt auch parallele Linien, Linienenden und die eigene Pfadgeometrie.

Das Level-Werkzeug startet mit `godot --path . -- --editor-tool`, unter Windows auch mit `Level-Werkzeug.cmd`. Der normale Projektstart öffnet ausschließlich das Spiel. Im Werkzeug schreibt **Export** die aktuelle Füllung in eine JSON-Datei; `levels/01.json` bis `levels/06.json` sind die sechs Slots des aktuellen Spiels. Exportierte Änderungen werden beim Neustart oder erneuten Laden des Levels übernommen.

Der Lösbarkeitstest baut einen Abhängigkeitsgraphen und entfernt schrittweise freie Pfade. Er prüft dieselbe Geometrie wie das Spiel. Da entfernte Pfade keine neuen Blockaden erzeugen, genügt diese Reihenfolge zur Prüfung.

## Tests

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_runner.gd -- --test
```

Bei einer portablen Installation `godot` durch den vollständigen Pfad zur Godot-Konsole ersetzen. Der erste Befehl importiert ein frisches Checkout und registriert die Scriptklasse.

Geprüft werden vollständige Lösungsfolgen aller sechs Levels, vollständige Füllung weiterer Generator-Seeds, überlappungsfreie Formen, Motivfarben, gerundete Geometrie, Entkommensrichtungen, blockierte Klicks, Hinweise, zyklische Abhängigkeiten, Selbstblockaden, Editorzeichnung und Richtungswechsel, JSON-Rundlauf, Testmodus und Rückkehr sowie ungültige Speicherdateien. Maus- und Touch-Ereignisse werden durch die tatsächliche Eingabeverarbeitung geschickt. Testdateien sind von normalen Spielständen getrennt.

## Nächste Ausbaustufen

Dieser Stand ist ein Desktop-Prototyp. Android-Export, Bedienung auf echten Smartphones und Schwierigkeit müssen noch geprüft werden. Freier Bildimport, frei zeichnbare Motivbereiche, eine komfortable Levelbibliothek, Sounds und Veröffentlichung sind noch nicht implementiert. Die aktuelle Füllung verwendet regelmäßige Schleifen; freiere, organischere Pfadkompositionen sind eine spätere Erweiterung.

![Pfad-Editor](previews/editor.png)
