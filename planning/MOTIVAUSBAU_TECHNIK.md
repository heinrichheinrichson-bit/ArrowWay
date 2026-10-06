# Motiverweiterung 0.20.0-dev

314 zusätzliche Motive, 814 Kataloglevels und neun Einstiegsrätsel. Keine bestehenden Leveldateien wurden ersetzt. Der bisherige Katalog bleibt an den ersten 500 Positionen; neue Pfade werden angehängt. Die Freischaltung verwendet weiterhin stabile Sammlungs-IDs und bestehende Zugriffsrechte.

## Quellen und Bearbeitung

295 SVG-Silhouetten stammen aus Game-icons.net, Repository `game-icons/icons`, Commit `82d948812bfe3f269ef8f731dcdb07b08160edc4`. 19 zusätzliche Umrisse sind eigene Entwürfe. Die ausgewählten Vorlagen und Urheberangaben liegen im Repository, der laufende Editor und das Spiel benötigen keinen externen Dienst.

SVGs werden auf ein Raster übertragen, unspielbare isolierte Punkte entfernt und die verbleibenden Flächen vollständig mit lösbaren Pfeilpfaden gefüllt. Automatische Farbabstufungen ergänzen die Grundfarbe. Jedes Motiv behält Umrissflächen und einzelne Pfeile für die Motivwerkstatt. Die Vorlagen sind in `collections/expansion_recipes.json` kuratiert; `planning/NEUE_MOTIVE.txt` enthält zusätzlich 35 noch nicht umgesetzte Kandidaten. Diese zählen nicht zum Katalog.

Alle 314 neuen Motive haben unterschiedliche Abschlusstexte. Neun recherchierte Fakten mit Quellen werden aus `collections/expansion_discoveries.json` übernommen; die übrigen neuen Texte sind eigene kurze Gedanken. Erneutes Installieren der Erweiterung erhält die recherchierten Texte.

## Reproduzierbare Befehle

Im Projektverzeichnis mit Python und Godot 4.7.2 ausführen. Die bereits gespeicherten Raster und Leveldateien reichen für einen normalen Neuaufbau:

```text
godot --headless --path . --editor --quit
godot --headless --path . --script tools/generate_collections.gd
python tools/install_expansion.py
python tools/write_catalog_index.py
godot --path . --script tools/preview_collections.gd -- --catalog res://collections/catalog.json
```

Für eine erneute Umwandlung der ausgewählten SVGs:

```text
godot --headless --path . --script tools/rasterize_expansion.gd
godot --headless --path . --script tools/generate_collections.gd -- --source res://collections/expansion_masks.json --output res://collections/expansion_catalog.json
python tools/install_expansion.py
```

`tools/prepare_motif_expansion.py --icons PFAD` ist nur nötig, wenn die kuratierte Auswahl aus einem Checkout von `game-icons/icons` neu zusammengestellt wird. Dafür den oben genannten Quell-Commit verwenden. Die eigenen SVGs liegen in `collections/original_vectors/`.

## Geprüfter Stand

- `test_collections.gd`: 814 unterschiedliche Geometrien und Bildtitel, vollständige Füllung, jede Lösung durch tatsächliche Spielzüge, keine Fehler, Sammlungspaginierung und Fortschritt.
- `test_catalog_editing.gd`: alle 814 Katalogmotive öffnen mit unveränderten Pfeilen und Farben; einzelne Pfeile einfärben und Undo in allen 87 Katalogsammlungen.
- `test_taxonomy.gd` und `test_journey.gd`: vollständige Zuordnung, alle 123 fachlichen Kategorien befüllt, strikte neue Freischaltungen, alte Zugriffsrechte, richtige Häkchen und Erreichbarkeit des ganzen Bestands.
- `test_discoveries.gd`: alle Abschlusstexte, Quellen und Platzbedarf in verschiedenen Smartphoneformaten.
- `test_expansion.gd`: 314 unterschiedliche Quellvorlagen, unterschiedliche neue Texte, erhaltene Urheberangaben und scrollbarer Lizenzdialog im Smartphoneformat.
- `test_resume.gd`, `test_board_navigation.gd`, `test_ads.gd`, `test_player_ui.gd`: Wiederaufnahme, Kamera, Touch, Werbeintervalle, Album und private Editorentwürfe.
- Die bisherigen 500 Leveldateien wurden byteweise mit dem vorherigen Git-Stand verglichen. Ihre Reihenfolge sowie alle 509 bisherigen Abschlusstexte sind unverändert.
- APK-Inhalt geprüft: sämtliche Kataloglevels, 823 Abschlusstexte und 314 vollständige Bildnachweise enthalten. Android-Paket `com.example.arrowway`, ARM64, Version `0.20.0-dev`, Hochformat, Signatur verifiziert.

Testaufruf: `godot --headless --path . --script tests/test_NAME.gd -- --test`. Für sichtbare Lizenzdialog-Aufnahmen: `godot --path . --script tests/test_expansion.gd -- --test --capture`.

Die praktische Bedienung der neuen Motive auf dem S22 und die subjektive Schwierigkeitskurve benötigen weiterhin menschliche Spieltests. Der spätere Bereich Formen & Denkwege ist nur als Konzept vorgemerkt.
