# Motivwerkstatt · 0.10.1

Die Werkstatt öffnet das aktuelle Motiv mitsamt seinen Pfeilen. Oben stehen die direkten Werkzeuge **Auswählen**, **Zeichnen**, **Löschen**, **Spitze wählen** und **Spiegeln**. Rechts gibt es zwei getrennte Bereiche: **Pfeile & Farben** und **Vorlage & Flächen**.

## Das ganze Motiv ansehen

**Gesamtansicht · Esc** beendet die Hervorhebung, blendet das Bearbeitungsraster aus und zeigt alle Pfeile in ihrer tatsächlichen Farbe. Klicks verändern dort nichts. **Auswählen** oder **Zeichnen** kehrt zur Bearbeitung zurück. Esc verwirft auch eine noch nicht abgeschlossene Zeichnung.

## Pfeile bearbeiten und färben

1. **Auswählen** drücken und einen Pfeil anklicken. Seine Nummer steht rechts; die übrigen Pfeile werden zur Orientierung abgedunkelt.
2. Das große Farbfeld weist nur diesem Pfeil eine eigene Farbe zu. **Zuletzt verwendet** und **Farben aus diesem Motiv** bieten Farben mit einem Klick. Zuletzt verwendete Farben bleiben beim nächsten Start erhalten.
3. **Verläufe & Farbvorschläge** bietet automatische Schattierungen, vertikale und horizontale Verläufe, eine radiale Beleuchtung und vier Farbvarianten. Die Vorschau verändert den Entwurf erst durch Übernehmen.
4. **Pipette** übernimmt eine vorhandene Pfeilfarbe. Im Farbdialog gibt es zusätzlich eine Pipette für die Bildvorlage.
5. **Farben für das gesamte Motiv** öffnet ausdrücklich die Farbgestaltung des ganzen Motivs. Individuelle Pfeilfarben können dabei erhalten bleiben.

**Rückgängig** nimmt eine Bearbeitung zurück. Eine zusammenhängende Änderung im Farbwähler zählt als ein Schritt; die zuletzt gewählte Farbe bleibt trotzdem als Vorschlag verfügbar.

## Eigene Pfeile zeichnen

**Zeichnen** wählen und mit gedrückter Maustaste eine Linie ziehen. Sie folgt dem Raster mit waagerechten und senkrechten Schritten und weichen Ecken. Freie Rasterpunkte außerhalb der bisherigen Motivfläche sind erlaubt. Beim Loslassen entsteht der Pfeil mit der Spitze am zuletzt gezeichneten Ende. Die Werkstatt kehrt zur Auswahl zurück.

Für einen Umriss die Linie mit einer kleinen Öffnung zeichnen: Ein Pfeil braucht zwei unterschiedliche Enden. Geschlossene Schleifen und Überschneidungen mit bestehenden Pfeilen oder der eigenen Linie sind nicht erlaubt; die Vorschau zeigt solche Stellen rot. Das vorhandene Raster begrenzt die Zeichnung.

- **Spitze wählen**: Erst einen Pfeil auswählen, dann auf das gewünschte Ende klicken. **R** kehrt die Richtung um, wenn die Zeichenfläche den Fokus hat.
- **Löschen / Entf**: Entfernt ausschließlich den ausgewählten Pfeil und gibt seine Rasterpunkte frei. Rückgängig stellt ihn samt Motivfläche wieder her.
- **Spiegeln**: Ergänzt eine Kopie mit gleicher Form und Farbgestaltung. Die senkrechte Achse 14 liegt in der Motivmitte. Halbe Spalten sind möglich; alternativ die Achse direkt im Motiv anklicken.

## Vorhandene Motive erweitern

Unter **Vorlage & Flächen** eine **Neue Fläche** erstellen, benennen und mit **Fläche malen** auf freien Rasterpunkten ergänzen. Vorhandene Pfeile werden weder beim Werkzeugwechsel noch beim Malen entfernt oder verändert. Der Pinsel überspringt belegte Punkte. **Radieren** entfernt ungefüllte Rasterpunkte; bestehende Pfeile lassen sich über die Pfeilauswahl gezielt löschen.

**Freie Flächen mit Pfeilen füllen** ergänzt nur bislang ungefüllte Bereiche. Geometrie und Farben aller vorhandenen Pfeile bleiben erhalten. Die gemeinsame Lösbarkeit wird geprüft. Bereits vollständig gefüllte Motive werden durch diesen Knopf nicht neu erzeugt.

Flächen lassen sich mit einer Linie teilen oder zusammenführen. Vorhandene Pfeile bleiben erhalten; eine Trennlinie teilt keine bestehenden Pfeilwege in zwei Stücke.

## Bilder, Entwürfe und Levels öffnen

**Öffnen → Bild, Motiv oder Level-Datei** akzeptiert PNG, JPG, JPEG, WebP und ArrowWay-JSON-Dateien. Vorhandene Spiellevel und gespeicherte Motiventwürfe bleiben mitsamt ihrer Pfeile bearbeitbar. Auch Entwürfe mit noch ungefüllten Flächen lassen sich öffnen.

Bei Bildvorlagen erkennt die Werkstatt geschlossene Umrisse, Farbflächen oder Transparenz. Unter **Vorlage & Flächen** können Erkennungsmodus und Helligkeitsschwelle angepasst werden. Hausumrisse, eine transparente Palme und eine Sonne liegen im Ordner `examples/`.

Das Öffnen eines anderen Motivs oder eine neue Bilderkennung fragt nach, bevor die vorhandene Füllung ersetzt wird. **Abbrechen** erhält den aktuellen Entwurf. Vor dem bestätigten Ersetzen wird zusätzlich eine lokale Sicherung angelegt.

## Speichern und Testen

**Speichern** öffnet einen Dateidialog. Die JSON-Datei enthält Motivfläche, Vorlage, Namen, Farben, Verläufe und alle Pfeile. Dabei wird zusätzlich der lokale Schnellstand aktualisiert. Über **Öffnen → Letzten lokalen Entwurf laden** lassen sich auch Entwürfe aus älteren Werkzeugversionen übernehmen.

**Öffnen → Letzte ersetzte Füllung wiederherstellen** stellt die Sicherung vor dem letzten bestätigten Ersetzen wieder her. Rückgängig bleibt zusätzlich verfügbar.

**Im Spiel testen** startet nur vollständig gefüllte und lösbare Motive. Unfertige oder noch blockierte Entwürfe dürfen trotzdem gespeichert werden. Für den Export in einen Spielslot steht nach dem Test die Exportfunktion des Level-Werkzeugs bereit.

**Alle Pfeile neu erzeugen** befindet sich im Bereich **Vorlage & Flächen** und verlangt eine ausdrückliche Bestätigung. Nur diese komplette Neufüllung ersetzt auch handgezeichnete Details.

## Exportierte Motive im echten Spiel

Nach **Im Spiel testen** im Level-Werkzeug **Export** wählen und die fertige JSON-Datei im Projektordner `levels/` speichern. Ein eigener Dateiname ist erlaubt; ein bestehendes Level muss nicht ersetzt werden. **ArrowWay.cmd** ist der richtige Spielstarter. Über **Alle Levels** oder die Levelauswahl erscheinen zusätzliche gültige Exporte als sofort spielbare eigene Motive. Das erneute Öffnen der Übersicht liest neue Dateien ein. Ein Spiel, das noch mit einer älteren Version läuft, muss einmal neu gestartet werden.

**Speichern** in der Motivwerkstatt sichert einen bearbeitbaren Entwurf. **Export** nach dem Spieltest schreibt dagegen die spielbare Leveldatei. JSON-Dateien außerhalb von `levels/` erscheinen nicht automatisch im Spiel.
