# ArrowWay

Ein spielbares Godot-Puzzle mit leuchtenden, gerundeten Pfeilpfaden. Die Motive sind auf einem gleichmäßigen Raster vollständig gefüllt: freie Pfade entkommen entlang ihrer Linie, blockierte Pfade bleiben liegen. Das Level-Werkzeug startet separat vom Spiel.

![ArrowWay Haus-Puzzle](previews/house.png)

## Start

Godot **4.x Standard** verwenden; geprüft mit **4.7.2**, GDScript und Compatibility-Renderer. `project.godot` importieren und **F5** drücken. Die ausführliche deutsche Anleitung steht in [START.md](START.md).

## Aktueller Stand · 0.5.0

- Sechs neu gestaltete Levels mit 25–39 Pfaden, jeweils vollständig gefüllten Motiven und allen vier Pfeilrichtungen.
- Längere, stärker verflochtene Verläufe. Abhängigkeiten und freie Startzüge werden beim Erstellen gemessen; die Serie beginnt mit einer übersichtlicheren Baumfüllung und endet mit engeren Freispielketten im Haus.
- Neu freigewordene Pfade erhalten einen kurzen Leuchtimpuls in ihrer Motivfarbe und eine passende Rückmeldung.
- Gerundete Kurven und ein durchgehend berechneter Neon-Leuchtsaum mit hellem Linienkern. Linien und Pfeilspitzen teilen dieselbe Darstellung; dadurch entstehen keine Flecken durch überlagerte Teilflächen.
- Motivfarben: grüner Baum mit braunem Stamm, Haus mit warmem Dach, blauen Wänden, hellen Fenstern und violetter Tür; Herz in Pink- und Rottönen.
- Sanfter Anlauf entlang der gerundeten Linie, kurzes Zurückfedern bei Blockaden und weich eingeblendeter Levelabschluss.
- Dezente synthetisierte Klänge für freie Züge, Blockaden, Hinweise, neu geöffnete Wege und den Abschluss. **Ton: An/Aus** schaltet sie ab; die Einstellung bleibt gespeichert.
- Levelauswahl, Fortschrittsanzeige und lokal gespeicherte Freischaltungen.
- Separates Level-Werkzeug: Schablone wählen, automatisch füllen, Rasterpfade zeichnen, auswählen, Richtung umkehren, löschen, Lösbarkeit prüfen und direkt testen.
- Entwürfe lokal speichern und laden; fertige Levels als JSON in den Projektordner exportieren.
- Das eigentliche Spiel zeigt keine Editorbedienelemente und lädt fertige Leveldateien aus `levels/`.
- Maus- und Touch-Eingabe; Hochformat mit skalierbarer Darstellung.

## Aufbau

- `puzzle.gd`: Formenmasken, geometrische Blockierungsprüfung und Lösungsfolge.
- `motifs.gd`: gleichmäßige vollständige Füllung, Motivbereiche und Neonpaletten.
- `level_design.gd`: Verflechtung und Verbindung benachbarter Pfade, Ausrichtung der Spitzen und Bewertung von Startzügen und Abhängigkeiten. Jede übernommene Variante bleibt vollständig lösbar.
- `levels/`: sechs fertige, reproduzierbar erzeugte und geprüfte Leveldateien.
- `main.gd`: Spielzustand, gerundete Animation, Benutzeroberfläche, Werkzeugmodus und Speicherung.
- `feedback_audio.gd`: kurze Klänge mit weichem Ein- und Ausklang und begrenzter Überlagerung.
- `board.gd`: Darstellung der Pfade innerhalb des Spielfelds und wiederverwendbare Zeichenflächen.
- `neon.gdshader`: zusammenhängende Kontur und weicher Leuchtsaum für Pfad und Pfeilspitze; Kantenglättung berücksichtigt die Bildschirmauflösung.
- `tests/test_runner.gd`: Spiellogik und Editorintegration.
- `tools/build_series.gd`: reproduzierbare Rezepte für die sechs aktuellen Levels; läuft offline zur Erstellung der Dateien.

Die Formen bestehen aus Rasterzellen mit 14 Pixeln Abstand. Der Generator füllt Motivbereiche mit ineinandergreifenden horizontalen und vertikalen Schleifen. Randzellen werden angeschlossen, ohne andere Zellen zu duplizieren. Unvollständige oder unlösbare Varianten werden verworfen. Alle sechs gelieferten Motive sind zu 100 Prozent belegt. Alle Pfade bestehen aus echten Punktfolgen; die Darstellung und Animation runden die Ecken mit kleinen Kreisbögen ab. Die Blockierungsprüfung berücksichtigt auch parallele Linien, Linienenden und die eigene Pfadgeometrie.

Das Level-Werkzeug startet mit `godot --path . -- --editor-tool`, unter Windows auch mit `Level-Werkzeug.cmd`. Der normale Projektstart öffnet ausschließlich das Spiel. Im Werkzeug schreibt **Export** die aktuelle Füllung in eine JSON-Datei; `levels/01.json` bis `levels/06.json` sind die sechs Slots des aktuellen Spiels. Exportierte Änderungen werden beim Neustart oder erneuten Laden des Levels übernommen.

**Füllen** verflechtet die erzeugten Pfade zusätzlich und prüft jede Änderung. Dadurch braucht die Erstellung etwas länger als die reine Rasterfüllung. Die Werkzeugbedienung ist währenddessen gesperrt. **Prüfen** zeigt auch freie Startzüge und Freispielstufen an. Diese Werte beschreiben den Abhängigkeitsgraphen; sie ersetzen kein Spielen und Bewerten durch Menschen.

Die sechs aktuellen Levels haben 9, 8, 12, 10, 8 und 6 freie Startzüge. Die längste Kette steigt vom Einstieg mit 9 auf 17 Abhängigkeitsstufen im letzten Level; dazwischen gibt es bewusst verschiedene Motive und etwas ruhigere Abschnitte. Das bisherige Baum-Level mit 35 sofort freien Pfeilen wurde durch eine Variante mit deutlich mehr Abhängigkeiten ersetzt.

Der Lösbarkeitstest baut einen Abhängigkeitsgraphen und entfernt schrittweise freie Pfade. Er prüft dieselbe Geometrie wie das Spiel. Da entfernte Pfade keine neuen Blockaden erzeugen, genügt diese Reihenfolge zur Prüfung.

## Tests

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_runner.gd -- --test
```

Die Serie lässt sich mit `godot --headless --path . --script res://tools/build_series.gd -- --test` neu erstellen. Das überschreibt `levels/01.json` bis `levels/06.json`; eigene Änderungen an diesen Dateien vorher separat sichern.

Bei einer portablen Installation `godot` durch den vollständigen Pfad zur Godot-Konsole ersetzen. Der erste Befehl importiert ein frisches Checkout und registriert die Scriptklasse.

Geprüft werden vollständige Lösungsfolgen aller sechs Levels, vollständige Füllung weiterer Generator-Seeds, überlappungsfreie Formen, Verflechtung ohne verlorene oder doppelte Zellen, die Bewertung der Level, Motivfarben, gerundete Geometrie, Entkommensrichtungen, blockierte Klicks, Hinweise, Rückmeldung neu geöffneter Wege, zyklische Abhängigkeiten, Selbstblockaden, Editorzeichnung und Richtungswechsel, JSON-Rundlauf, Testmodus und Rückkehr sowie ungültige Speicherdateien. Maus- und Touch-Ereignisse werden durch die tatsächliche Eingabeverarbeitung geschickt. Zusätzlich werden sanfter Anlauf, schnelle aufeinanderfolgende Züge, Pegel und stille Klangenden sowie die gespeicherte Toneinstellung geprüft. Testdateien sind von normalen Spielständen getrennt.

## Nächste Ausbaustufen

Dieser Stand ist ein Desktop-Prototyp. Android-Export, Bedienung auf echten Smartphones und das Spielgefühl der neuen Serie müssen noch geprüft werden. Freier Bildimport, frei zeichnbare Motivbereiche, eine komfortable Levelbibliothek und Veröffentlichung sind noch nicht implementiert. Die Verflechtung verbessert die rechnerischen Kennzahlen und die Vielfalt der Pfade; eine angenehme Schwierigkeitskurve muss anschließend mit Spieltests abgestimmt werden.

![Pfad-Editor](previews/editor.png)
