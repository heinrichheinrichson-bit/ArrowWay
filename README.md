# ArrowWay

Ein spielbares Godot-Puzzle mit leuchtenden, gerundeten Pfeilpfaden. Die Motive sind auf einem gleichmäßigen Raster vollständig gefüllt: freie Pfade entkommen entlang ihrer Linie, blockierte Pfade bleiben liegen. Das Level-Werkzeug startet separat vom Spiel.

![ArrowWay Haus-Puzzle](previews/house.png)

## Start

Godot **4.x Standard** verwenden; geprüft mit **4.7.2**, GDScript und Compatibility-Renderer. `project.godot` importieren und **F5** drücken. Die ausführliche deutsche Anleitung steht in [START.md](START.md).

## Aktueller Stand · 0.10.0

- Neun gestaltete Levels mit 25–39 Pfaden, jeweils vollständig gefüllten Motiven und allen vier Pfeilrichtungen.
- Längere, stärker verflochtene Verläufe. Abhängigkeiten und freie Startzüge werden beim Erstellen gemessen; die Serie beginnt mit einer übersichtlicheren Baumfüllung und endet mit engeren Freispielketten im Haus.
- Neu freigewordene Pfade erhalten einen kurzen Leuchtimpuls in ihrer Motivfarbe und eine passende Rückmeldung.
- Gerundete Kurven und ein durchgehend berechneter Neon-Leuchtsaum mit hellem Linienkern. Linien und Pfeilspitzen teilen dieselbe Darstellung; dadurch entstehen keine Flecken durch überlagerte Teilflächen.
- Motivfarben: grüner Baum mit braunem Stamm, Haus mit warmem Dach, blauen Wänden, hellen Fenstern und violetter Tür; Herz in Pink- und Rottönen.
- Sanfter Anlauf entlang der gerundeten Linie, kurzes Zurückfedern bei Blockaden und weich eingeblendeter Levelabschluss.
- Dezente synthetisierte Klänge für freie Züge, Blockaden, Hinweise, neu geöffnete Wege und den Abschluss. **Ton: An/Aus** schaltet sie ab; die Einstellung bleibt gespeichert.
- Scrollbare Levelübersicht mit gerundeten Motivvorschauen, gesperrten und geschafften Puzzles, Fortschrittszähler und lokal gespeicherten Freischaltungen. Ein geöffnetes Puzzle bleibt beim Besuch der Übersicht erhalten.
- Neue Motive: Schmetterling in Violett und Pink mit goldener Mitte, türkisblauer Fisch mit warmer Schwanzflosse und pinke Blume mit gelber Mitte und grünem Stiel.
- **Klare Werkstattführung**: direkte Pfeilwerkzeuge, getrennte Bereiche für Pfeile/Farben und Vorlage/Flächen, Gesamtansicht ohne Auswahl, sichtbare zuletzt verwendete Farben und Motivfarben. Neue Flächen und ihre Füllung erhalten alle bestehenden Pfeile. Öffnen und Speichern beliebiger Motiventwürfe; bestätigte Ersetzungen erhalten eine lokale Sicherung.
- **Pfeile bearbeiten**: eigene Rasterpfeile nach dem Füllen ergänzen, löschen, die Spitze per Klick wählen und an einer senkrechten Achse spiegeln. Überschneidungsprüfung, Rückgängig und Lösbarkeitsprüfung; auch noch blockierte Entwürfe bleiben speicherbar.
- **Farben & Verläufe**: automatische Schattierungen aus einer Grundfarbe, kontinuierliche Verläufe innerhalb der Pfeile, vier Farbvorschläge, nachträgliche Bearbeitung einzelner Pfeile und Pipetten für Pfeilfarben beziehungsweise die Bildvorlage. Individuelle Farben können bei Flächenänderungen erhalten bleiben; Entwürfe und Levels speichern die Farbgestaltung.
- Neue **Motivwerkstatt**: Bildimport, Erkennung geschlossener Umrisse oder Farbflächen, Flächenpinsel, Radierer, Trennlinie, Zusammenführen und Neonpaletten. Die automatische Füllung deckt jeden akzeptierten Rasterpunkt ab und bleibt vollständig lösbar. Bildanalyse und Füllung laufen im Hintergrund.
- Separates Level-Werkzeug: Schablone wählen, automatisch füllen, Rasterpfade zeichnen, auswählen, Richtung umkehren, löschen, Lösbarkeit prüfen und direkt testen.
- Entwürfe lokal speichern und laden; fertige Levels als JSON in den Projektordner exportieren.
- Das eigentliche Spiel zeigt keine Editorbedienelemente und lädt fertige Leveldateien aus `levels/`.
- Maus- und Touch-Eingabe; Hochformat mit skalierbarer Darstellung.

## Aufbau

- `puzzle.gd`: Formenmasken, geometrische Blockierungsprüfung und Lösungsfolge.
- `motif_colors.gd`, `color_studio.gd`, `color_preview.gd`, `color_suggestion.gd`: automatische Abstufungen, räumliche Verläufe, Vorschläge und individuelle Pfeilfarben mit Livevorschau.
- `custom_motif.gd`: freie Flächen, Paletten, geometrische Bearbeitung und validierte Speicherung.
- `motif_import.gd`: lokale Bildanalyse für Umrisse, Farben und Transparenz.
- `motif_studio.gd`, `motif_canvas.gd`, `motif_preview.gd`: Motivwerkstatt mit Hintergrundberechnung und Neonvorschau.
- `motifs.gd`: gleichmäßige vollständige Füllung, Motivbereiche und Neonpaletten.
- `level_design.gd`: Verflechtung und Verbindung benachbarter Pfade, Ausrichtung der Spitzen und Bewertung von Startzügen und Abhängigkeiten. Jede übernommene Variante bleibt vollständig lösbar.
- `levels/`: neun fertige, reproduzierbar erzeugte und geprüfte Leveldateien.
- `main.gd`: Spielzustand, gerundete Animation, Benutzeroberfläche, Werkzeugmodus und Speicherung.
- `feedback_audio.gd`: kurze Klänge mit weichem Ein- und Ausklang und begrenzter Überlagerung.
- `level_card.gd`: Motivvorschauen und Status in der Levelübersicht.
- `board.gd`: Darstellung der Pfade innerhalb des Spielfelds und wiederverwendbare Zeichenflächen.
- `neon.gdshader`: zusammenhängende Kontur und weicher Leuchtsaum für Pfad und Pfeilspitze; Kantenglättung berücksichtigt die Bildschirmauflösung.
- `tests/test_runner.gd`: Spiellogik und Editorintegration.
- `tools/build_series.gd`: reproduzierbare Rezepte für die neun aktuellen Levels; läuft offline zur Erstellung der Dateien.

Die Formen bestehen aus Rasterzellen mit 14 Pixeln Abstand. Der Generator füllt Motivbereiche mit ineinandergreifenden horizontalen und vertikalen Schleifen. Randzellen werden angeschlossen, ohne andere Zellen zu duplizieren. Unvollständige oder unlösbare Varianten werden verworfen. Alle neun gelieferten Puzzles sind zu 100 Prozent belegt. Alle Pfade bestehen aus echten Punktfolgen; die Darstellung und Animation runden die Ecken mit kleinen Kreisbögen ab. Die Blockierungsprüfung berücksichtigt auch parallele Linien, Linienenden und die eigene Pfadgeometrie.

Das Level-Werkzeug startet mit `godot --path . -- --editor-tool`, unter Windows auch mit `Level-Werkzeug.cmd`. Der normale Projektstart öffnet ausschließlich das Spiel. Im Werkzeug startet die neue Motivwerkstatt automatisch; **Bild & Flächen** öffnet sie erneut. Die ausführliche Anleitung und Bildbeispiele stehen in [MOTIVWERKSTATT.md](MOTIVWERKSTATT.md). Im Werkzeug schreibt **Export** die aktuelle Füllung in eine JSON-Datei; `levels/01.json` bis `levels/09.json` sind die neun Slots des aktuellen Spiels. Exportierte Änderungen werden beim Neustart oder erneuten Laden des Levels übernommen.

**Füllen** verflechtet die erzeugten Pfade zusätzlich und prüft jede Änderung. Dadurch braucht die Erstellung etwas länger als die reine Rasterfüllung. Die Werkzeugbedienung ist währenddessen gesperrt. **Prüfen** zeigt auch freie Startzüge und Freispielstufen an. Diese Werte beschreiben den Abhängigkeitsgraphen; sie ersetzen kein Spielen und Bewerten durch Menschen.

Die neun aktuellen Levels haben 9, 8, 12, 10, 8, 6, 8, 12 und 5 freie Startzüge. Der Schmetterling hat 16, der ruhigere Fisch 10 und die abschließende Blume 17 Abhängigkeitsstufen. Die längste Kette steigt vom Einstieg mit 9 auf 17 Abhängigkeitsstufen im sechsten Level; dazwischen gibt es bewusst verschiedene Motive und etwas ruhigere Abschnitte. Das bisherige Baum-Level mit 35 sofort freien Pfeilen wurde durch eine Variante mit deutlich mehr Abhängigkeiten ersetzt.

Der Lösbarkeitstest baut einen Abhängigkeitsgraphen und entfernt schrittweise freie Pfade. Er prüft dieselbe Geometrie wie das Spiel. Da entfernte Pfade keine neuen Blockaden erzeugen, genügt diese Reihenfolge zur Prüfung.

## Tests

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_runner.gd -- --test
godot --headless --path . --script res://tests/test_import.gd -- --test
godot --headless --path . --script res://tests/test_colors.gd -- --test
```

Die Serie lässt sich mit `godot --headless --path . --script res://tools/build_series.gd -- --test` neu erstellen. Das überschreibt `levels/01.json` bis `levels/09.json`; eigene Änderungen an diesen Dateien vorher separat sichern.

Bei einer portablen Installation `godot` durch den vollständigen Pfad zur Godot-Konsole ersetzen. Der erste Befehl importiert ein frisches Checkout und registriert die Scriptklasse.

Geprüft werden vollständige Lösungsfolgen aller neun Levels, vollständige Füllung weiterer Generator-Seeds, überlappungsfreie Formen, Verflechtung ohne verlorene oder doppelte Zellen, die Bewertung der Level, Motivfarben, gerundete Geometrie, Entkommensrichtungen, blockierte Klicks, Hinweise, Rückmeldung neu geöffneter Wege, zyklische Abhängigkeiten, Selbstblockaden, Editorzeichnung und Richtungswechsel, JSON-Rundlauf, Testmodus und Rückkehr sowie ungültige Speicherdateien. Maus- und Touch-Ereignisse werden durch die tatsächliche Eingabeverarbeitung geschickt. Die Übersicht wird mit echten Mausklicks geprüft, einschließlich Sperren, Rückkehr und gespeichertem Abschlussstatus. Zusätzlich werden sanfter Anlauf, schnelle aufeinanderfolgende Züge, Pegel und stille Klangenden sowie die gespeicherte Toneinstellung geprüft. Testdateien sind von normalen Spielständen getrennt.

## Nächste Ausbaustufen

Dieser Stand ist ein Desktop-Prototyp. Android-Export, Bedienung auf echten Smartphones und das Spielgefühl der neuen Serie müssen noch geprüft werden. Die erste lokale Bildanalyse arbeitet mit klaren Umrissen, Farbflächen und Transparenz. Allgemeine Fotoerkennung, automatische Benennung von Bildteilen, feinere beziehungsweise variable Raster, eine komfortable Bibliothek für eigene Motive und Veröffentlichung stehen noch aus. Die Verflechtung verbessert die rechnerischen Kennzahlen und die Vielfalt der Pfade; eine angenehme Schwierigkeitskurve muss anschließend mit Spieltests abgestimmt werden.

![Pfad-Editor](previews/editor.png)

![Levelübersicht](previews/gallery.png)

![Bild zu Pfeilpuzzle](previews/studio-filled.png)

![Automatische Farbgestaltung](previews/color-studio.png)
