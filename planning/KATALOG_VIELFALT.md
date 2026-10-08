# Katalog: unterschiedliche Bildideen statt Farbvarianten

Version 0.25.1 überarbeitet 66 vorhandene Rätsel an ihren bisherigen Pfaden und
fügt drei eigenständige Motive hinzu: Anker, Gleise und Zug auf einer Bogenbrücke.
Die 69 Szenen verteilen sich auf elf bestehende Unterkategorien.

- Zahnmedizin: Zahnarztspiegel ersetzt das unpassende Zahngesicht.
- Seen und Flüsse: senkrechter Wasserfall und geschwungener Flusslauf.
- Küsten: Lagune, Strandliege, Fjord, Palme, Vulkaninsel, Leuchtturm, Strandhütten.
- Wüste: Oase, Tafelberge, Dünen, Kamel am Brunnen und Savannenakazie.
- Ballsport: Tor, Korb, Volleyballnetz, Tennisplatz, Fanghandschuh und Bowlingkegel.
- Schiffe: Dampfer, Motoryacht, Piratenschiff und Anker.
- Fluggeräte: Hubschrauber, Jet mit Schweif, Segelflugzeug, Wasser- und Papierflieger.
- Straßenfahrzeuge: eigene Karosserien und Ansichten; Blaulicht, Leiter, Rettungskreuz,
  Aufstelldach und Materialfarben unterscheiden die Fahrzeugtypen.
- Schiene: Seitenansicht des Schnellzugs, Straßenbahn, Metro im Tunnel, Gleise, Brücke.
- Berge: schmale tiefe Schlucht und breites grünes Tal.
- Städte: Straßenperspektive, Hafenkran, Kuppeln, Altstadt, Brücke, Dachlandschaft,
  Viadukt, Aussichtsturm, Sternwarte, Ladenfront, Segeltürme, Brunnenplatz,
  Schneestadt, Stufenturm, Riesenrad, Glastürme, Monddächer, Kanalviertel und Stadttor.

Alle Masken sind Originalzeichnungen aus geometrischen Zeichenprimitiven;
Pfeile und Materialregionen bleiben in der privaten Werkstatt editierbar.
Die neuen kurzen Abschlusstexte sind eigene Gedanken, keine recherchierten Fakten
oder zugeschriebenen Zitate. Deutsche und englische Fassungen liegen motivbezogen
in `localization/motifs.json` und werden beim APK-Bau geprüft.

## Werkzeuge

1. `python tools/curate_catalog_variety.py` erstellt die benannten Regionsmasken.
2. Godot mit `--script res://tools/bake_catalog_variety.gd -- --test` füllt sie im
   Arbeitsordner. Gleichbleibende Rezepte werden wiederverwendet; `--rebuild` baut neu.
3. `tools/preview_catalog_variety.gd` ohne Headless-Modus rendert die echten Pfeile.
4. `tools/install_catalog_variety.gd` validiert zunächst nur. `--publish` übernimmt
   alles über den gesicherten Katalog-Speicher mit Rücksicherung und Konfliktprüfung.
5. `tests/test_catalog_variety.gd` prüft volle Belegung, unterschiedliche Silhouetten,
   Laufzeitlösungen, deutsche/englische Texte und konsistente Sammlungszahlen.

Der allgemeine Kataloggenerator berücksichtigt die überarbeiteten Rezepte.
Manuell geschützte Bilder haben weiterhin Vorrang. Neue Motive werden hinten
angefügt; vorhandene Reihenfolge, IDs und persönliche Änderungen bleiben erhalten.
Die zusätzlichen Autorrezepte werden nicht in die Spieler-APK exportiert.
