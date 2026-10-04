# Die ArrowWay-Sammlungen

Der Katalog enthält **500 Motive in 29 Sammlungen**, zusätzlich zu den neun Einstiegspuzzles und eigenen Exporten. [CATALOG.md](CATALOG.md) enthält alle Titel, Dateilinks und die mit dem Spielrenderer erzeugten Sammlungsvorschauen.

Halloween, Weihnachten, Winter und Ostern stehen neben Technik, Computern, Smartphones, Skylines, Fahrzeugen, Meerestieren, Vögeln, Blumen, Essen, Musik, Sport, Spielzeug, Reisen, Fantasy und Landschaften. Verwandte Motive bilden bewusst Serien mit unterschiedlichen Formen, Teilflächen und Details.

Alle 500 gelieferten Dateien sind vollständig und ohne überlappende Pfeile gefüllt. Ihre Lösungsfolgen wurden durch die tatsächliche Spiellogik gespielt; außerdem wurden sämtliche Dateien im Editor geöffnet und Einzelpfeilfarben mit Rückgängig in jeder Sammlung geprüft. Die automatische Prüfung ersetzt keine menschliche Bewertung von Schönheit, Schwierigkeit und Spielgefühl. Dafür lassen sich alle Motive anschließend feinjustieren.

## Bibliothek für viele Motive

`collections/catalog.json` enthält Titel, Dateipfade, Sammlungszuordnung, Themen und Bewertungswerte. Die Pfeilgeometrie liegt getrennt in `collections/levels/`. Beim Katalogaufbau wird die Geometrie dieser gelieferten Motive nicht geladen oder erneut gelöst. Die Übersicht erzeugt höchstens zwölf Vorschauen pro Seite; Filter und Seitenwechsel erlauben das Durchblättern größerer Bibliotheken.

Ein automatisierter Test prüft die echte Übersicht mit einem Index aus 1.000 Einträgen, einschließlich der letzten Seite. Dafür wird dieselbe Geometrie wiederverwendet: Der Test prüft Seitenlogik und Anzahl der Vorschauen, keinen Benchmark mit 1.000 unterschiedlichen Dateien. Suche, Themen und Favoriten sind ab 0.12.0 verfügbar. Bei großen Downloads können später einzelne Sammlungspakete hinzukommen.

Suche und Filter greifen auf die Katalogdaten zu, ohne sämtliche Leveldateien zu öffnen. Die Suche berücksichtigt Titel, Sammlung und Themen; Großschreibung und deutsche Umlaute sind optional. Die Kunstmotive tragen zusätzlich Künstlernamen als Suchbegriffe. **Thema**, **Fortschritt** und **Favoriten** lassen sich kombinieren. Mit **Alles zeigen** lässt sich auch eine leere Ergebnisauswahl einfach verlassen.

Favoriten werden getrennt vom Spielfortschritt in `library.cfg` gespeichert. Ihre Dateipfade bleiben auch bei veränderter Katalogreihenfolge erhalten. Nicht mehr verfügbare Dateien werden nicht angezeigt; ihre Favoritenmarkierung bleibt erhalten, falls sie später wieder hinzukommen. Eigene Exporte können optional ein Feld `tags` mit einer Liste von Texten enthalten; ohne Tags bleiben sie über ihren Titel auffindbar.

Die neun Einstiegspuzzles behalten ihre Freischaltungen. Fortschritte zusätzlicher Motive werden über ihre Dateipfade gespeichert, damit eingefügte Motive bestehende Abschlüsse nicht verschieben. Eigene Exporte im Ordner `levels/` erscheinen als **Eigene Motive**. Solche extern bearbeitbaren Exporte werden weiterhin streng beim Einlesen geprüft.

## Motive weiterbearbeiten

In der Motivwerkstatt **Öffnen → Bild, Motiv oder Level-Datei** wählen und ein JSON aus `collections/levels/` öffnen. Flächen, Pfeile und Farben lassen sich wie bei eigenen Motiven bearbeiten. Für eine persönliche Variante unter einem eigenen Namen in `levels/` exportieren.

`collections/source_masks.json` speichert die Ausgangsflächen. `tools/generate_collections.gd` erzeugt daraus die gelieferten Level und den Katalog mit festen Seeds. Unfüllbare einzelne Randspitzen werden vor der Füllung mit benachbarten Farbflächen vereinigt oder am äußeren Umriss geglättet; innere Löcher werden nicht erzeugt. Die endgültige Maske muss lückenlos und lösbar gefüllt sein.

```powershell
godot --headless --path . --script res://tools/generate_collections.gd -- --test
godot --path . --script res://tools/preview_collections.gd -- --test
godot --headless --path . --script res://tests/test_collections.gd -- --test
```

Der Generator verwendet unveränderte, geprüfte Dateien erneut und erzeugt geänderte Rezepte neu. `--rebuild` erzwingt eine vollständige Neuerstellung. Dabei werden die gelieferten Sammlungsdateien überschrieben. Bearbeitete Varianten vorher unter eigenem Namen sichern. Die Vorschauen werden mit dem tatsächlichen Neonrenderer erzeugt und benötigen einen Grafikrenderer.


Die Ausgangsmotive werden mit `python tools/build_catalog_masks.py` aufgebaut; anschließend erzeugt der Godot-Generator die Pfeile. `python tools/write_catalog_index.py` aktualisiert die vollständige Übersicht.
