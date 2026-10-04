# ArrowWay · Bild zu Puzzle

Starte **Level-Werkzeug.cmd**. Die neue Motivwerkstatt öffnet sich automatisch in einem eigenen Fenster. Im bisherigen Pfadwerkzeug öffnet **Bild & Flächen** dieselbe Werkstatt erneut.

![Motivwerkstatt mit fertiger Füllung](previews/studio-filled.png)

## Ein Motiv erstellen

1. **Bild öffnen**: PNG, JPG oder WebP wählen. Zum Ausprobieren liegen `examples/haus-umrisse.png` und `examples/palme-transparent.png` bei. Der Dateidialog beginnt in diesem Ordner.
2. **Automatisch** erkennt geschlossene Schwarz-Weiß-Umrisse oder Farbflächen beziehungsweise Transparenz. Bei Bedarf **Geschlossene Umrisse** oder **Farben / Transparenz** wählen und **Neu erkennen** drücken. Der Hell-Dunkel-Regler beeinflusst die Erkennung von Umrisslinien.
3. Mit **Fläche auswählen** in einen Bereich klicken. Gib ihm einen Namen, etwa Dach, Fassade, Fenster oder Stamm. Die gleiche Auswahl ist rechts in der Flächenliste möglich.
4. Eine Neonpalette wählen oder die drei Farbfelder individuell ändern. Bei farbigen Vorlagen werden passende Neonfarben vorgeschlagen. Schwarz-Weiß-Vorlagen erhalten zunächst unterschiedliche Vorschlagsfarben; deren Bedeutung und Namen legst du selbst fest.
5. Flächen bei Bedarf korrigieren: **Fläche malen** und **Radieren** funktionieren durch Ziehen mit gedrückter linker Maustaste. **Neue Fläche** erstellt einen eigenen Bereich und aktiviert das Malen. **Rückgängig** stellt vorherige Flächen und Pfeile wieder her.
6. **Automatisch mit Pfeilen füllen** erzeugt eine vollständige, lösbare Füllung. Ein erneuter Klick erzeugt eine neue Variante. Die Berechnung läuft im Hintergrund. Die Werkstatt zeigt die Pfeile mit derselben Neon-Darstellung wie das Spiel.
7. **Übernehmen und testen** öffnet das Motiv im tatsächlichen Spiel. **Zum Level-Werkzeug** bringt dich zur Bearbeitung zurück; nach dem Lösen funktioniert auch **Zurück zum Editor**. Dort kannst du **Export** verwenden.

## Flächen trennen und verbinden

Wähle zunächst die Fläche, die du teilen möchtest. Wähle **Fläche mit Linie trennen** und ziehe quer durch sie, von außerhalb der einen Grenze bis außerhalb der anderen. Die Teilflächen bekommen eigene Einträge und übernehmen zunächst die Palette. Die Trennlinie wird den beiden Seiten zugeordnet: Im Motiv entsteht keine leere Schneise.

Zum Zusammenführen zuerst die Zielfläche auswählen, dann **Angeklickte Fläche zusammenführen** wählen und auf den anderen Bereich klicken. Getrennte Teilbereiche dürfen dieselbe Palette verwenden; Pfeile bleiben innerhalb ihrer Flächen. Die Lösbarkeit wird für das gesamte Puzzle geprüft, auch bei Blockaden zwischen verschiedenen Flächen.

Eine Änderung an der Flächengeometrie verwirft die bisherige Vorschau. Danach erneut füllen. Eine reine Palettenänderung erhält die Pfeilgeometrie und färbt sie sofort um.

## Farben, Schattierungen und Verläufe

**Farben & Verläufe · Vorschläge** öffnet die neue Farbgestaltung. Sie funktioniert vor und nach dem Füllen. Die Vorschau zeigt die Farbwirkung direkt auf dem Motiv beziehungsweise auf seinen Pfeilen; **Farben übernehmen** wendet sie auf den Entwurf an.

- **Ausgewählte Fläche** färbt den aktuell gewählten Bereich.
- **Ausgewählter Pfeil** färbt nur einen Pfeil. Klicke im gefüllten Motiv direkt auf den Pfeil. Die anderen Pfeile werden abgedunkelt; oben steht seine Nummer. Das Farbfeld daneben weist sofort eine eigene Farbe zu. **Verläufe …** öffnet Schattierungen und Vorschläge für diesen Pfeil. Mit **Nur Fläche auswählen** kannst du stattdessen ganze Flächen wählen.
- **Ganzes Motiv · Grundfarben behalten** erzeugt Abstufungen für alle Flächen. Jede Fläche behält ihre eigene Farbfamilie: Blätter bleiben grün, der Stamm braun.

Wähle eine Grundfarbe und eine Farbwirkung: **Einfarbig**, **Sanfte Schattierungen**, vertikaler oder horizontaler Verlauf beziehungsweise **Leuchtende Mitte**. **Stärke der Schattierung** bestimmt, wie deutlich sich die Töne unterscheiden. Bei einer gelben Sonne kann die Mitte hellgelb und der Rand wärmer und dunkler werden. Verläufe sind innerhalb eines Pfeils kontinuierlich und werden beim Entkommen mitgeführt.

Die vier Vorschläge **Natürlich**, **Wärmer**, **Pastell** und **Kräftiger** werden aus deiner Grundfarbe berechnet. Ein Klick aktualisiert die Vorschau; **Farben übernehmen** bestätigt die Auswahl. Die drei Farbfelder in der Werkstatt lassen sich weiterhin einzeln bearbeiten und bestimmen bei Verläufen den hellen, mittleren und dunklen Ton.

**Eigene Pfeilfarben erhalten** schützt individuell bearbeitete Pfeile bei späteren Flächen- oder Motivänderungen. Mit **Eigene Pfeilfarben zurücksetzen** erhalten sie wieder die Farben ihrer Fläche. Beide Aktionen lassen sich in der Werkstatt rückgängig machen. Eine komplett neue Pfeilfüllung erzeugt neue Pfeile; individuelle Anpassungen an alten Pfeilen gehören zu deren bisheriger Füllung.

Die Pipette hat zwei Quellen: eine vorhandene Pfeil- beziehungsweise Flächenfarbe und die ursprüngliche Bildvorlage. Nach dem Anklicken der Pipette verschwindet der Farbdialog vorübergehend. Klicke in der Werkstatt auf die gewünschte Farbe; danach erscheint der Dialog mit dieser Grundfarbe wieder. Die Auswahl der Zielfläche oder des Zielpfeils bleibt erhalten. **Einfarbig** übernimmt den Farbton direkt, die übrigen Wirkungen erzeugen daraus Abstufungen. Beim Ziel **Ganzes Motiv** wechselt die Pipette zur ausgewählten Fläche, damit eine einzelne aufgenommene Farbe gezielt angewendet wird.

Unter `examples/sonne-transparent.png` liegt eine gelbe Sonne zum Ausprobieren. Verläufe und individuelle Pfeilfarben werden in Entwürfen und exportierten Levels gespeichert.

![Farbgestaltung mit Sonne und Vorschlägen](previews/color-studio.png)

## Speichern und exportieren

**Entwurf speichern** sichert Flächen, Namen, Paletten, Bildreferenz und die genaue Pfeilfüllung. **Entwurf laden** stellt sie wieder her. Es gibt zunächst einen lokalen Entwurfsplatz; neue Speicherung ersetzt ihn. Beim Schließen und erneuten Öffnen bleibt der aktuelle Stand zusätzlich in dieser laufenden Sitzung erhalten.

Entwürfe liegen in `%APPDATA%\Godot\app_userdata\ArrowWay\motif_draft.json`. Der Eintrag `reference_png` enthält die verkleinerte Bildreferenz; zum erneuten automatischen Erkennen die ursprüngliche Bilddatei wieder öffnen.

Im Pfadwerkzeug schreibt **Export** eine eigenständige Leveldatei mit Flächen und Pfeilen im Format Version 2. Du kannst sie separat sichern. Das Spiel lädt weiterhin die neun Slots `levels/01.json` bis `levels/09.json`: Exportiere in den gewünschten Slot und lade ihn im Spiel neu oder starte das Spiel neu. Der Motivname aus der Datei erscheint in der Levelauswahl. Die ursprünglichen Levels sind weiterhin im Git-Verlauf vorhanden.

## Welche Vorlagen funktionieren?

Am zuverlässigsten sind klare, geschlossene Umrisse auf weißem Hintergrund, flächige Zeichnungen auf einheitlichem Hintergrund und Motive auf transparentem Hintergrund. Die Bildanalyse erkennt Flächen anhand von Linien und Farben. Sie benennt keine Gegenstände automatisch und ist keine allgemeine Fotoerkennung.

Das Bild wird proportional auf das vorhandene Raster von 29 × 33 Punkten übertragen. Details unterhalb dieser Auflösung können verschwinden oder zu klein für einen Pfeil werden. Einzelpunkte einer Fläche werden rot markiert und verhindern die Füllung. Verbreitere oder verbinde sie mit dem Malwerkzeug, ordne sie einer Nachbarfläche zu oder entferne sie. Auch bei anderen ungünstigen Geometrien kann eine Füllung scheitern; der Editor meldet das und übernimmt keine unvollständige Variante.

Bildanalyse und Füllung laufen lokal in Godot. Python, Cloud-Dienste und zusätzliche Installationen werden für diese erste Version nicht benötigt.

## Prüfung

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_runner.gd -- --test
godot --headless --path . --script res://tests/test_import.gd -- --test
```

Die Importtests prüfen Hausumrisse, eine farbige transparente Palme, leere Vorlagen und schwarze Silhouetten. Sie prüfen vollständige Füllung, Flächengrenzen, Paletten, Trennung ohne verlorene Rasterpunkte, echte Mauseingaben, Hintergrundberechnung, Rückgängig, Speichern/Laden und einen vollständigen Spieltest des importierten Motivs. Testdateien sind von normalen Entwürfen und Spielständen getrennt.

Bei ausgewähltem Pfeil zeigen auch die Farbfelder rechts **FARBEN FÜR PFEIL …**. Sowohl diese Farbfelder als auch die Palettenauswahl bearbeiten dann ausschließlich diesen Pfeil. Seine eigene Farbe wird unabhängig von der Flächenpalette gespeichert.

## Pfeile nach dem Füllen von Hand bearbeiten

Oben öffnet **Pfeile bearbeiten** die Zeichen-, Lösch- und Spiegelwerkzeuge.

- **Pfeil zeichnen**: Mit gedrückter linker Maustaste eine Linie ziehen. Sie folgt dem vorhandenen Raster mit waagerechten und senkrechten Schritten und weichen Ecken. Auch freie Rasterpunkte außerhalb der bisherigen Motivfläche sind erlaubt. Beim Loslassen entsteht der Pfeil; seine Spitze sitzt am zuletzt gezeichneten Ende. Die Werkstatt kehrt zur Auswahl zurück.
- **Spitze per Klick wählen**: Erst einen Pfeil auswählen, dann dieses Werkzeug öffnen und auf das gewünschte Ende klicken. Alternativ dreht **R** die Richtung um, wenn die Zeichenfläche den Fokus hat.
- **Löschen**: Pfeil auswählen und **Entf** drücken oder den Löschknopf verwenden. Seine Rasterpunkte werden frei und aus der Spielfläche entfernt; du kannst dort einen Ersatz zeichnen. Die Bildvorlage bleibt erhalten.
- **Spiegeln**: Pfeil auswählen, die senkrechte Achse einstellen und **gespiegelt ergänzen** drücken. Die Kopie hat die gleiche Form und Farbgestaltung. Achse 14 ist die Mitte des 29 Spalten breiten Rasters; halbe Spalten sind ebenfalls möglich. Über **Achse im Motiv anklicken** kannst du sie direkt festlegen.
- **Abbrechen**: **Esc** verwirft die gerade gezogene Linie. **Rückgängig** stellt fertige Bearbeitungen einschließlich der Motivfläche wieder her.

Überschneidungen mit bestehenden Pfeilen oder der eigenen Linie erscheinen beim Zeichnen rot; solche Pfeile werden nicht hinzugefügt. Die Zeichnung muss innerhalb des verfügbaren Rasters bleiben. Ein Umrisspfeil braucht zwei verschiedene Enden: Zeichne die Umrandung mit einer kleinen Öffnung, nicht als geschlossene Schleife.

Nach jeder Bearbeitung zeigt die Werkstatt die Lösbarkeit an. Noch blockierte Entwürfe lassen sich speichern und laden; **Übernehmen und testen** startet erst ein lösbares Puzzle. Farben und handgezeichnete Pfeile bleiben beim Speichern und Level-Export erhalten.

**Automatisch mit Pfeilen füllen** erzeugt eine neue gesamte Füllung und ersetzt dabei auch von Hand ergänzte Pfeile. Ergänze die Details deshalb nach dem automatischen Füllen.
