# Katalogwerkstatt · 0.22

Die Motivwerkstatt ist das separate PC-Autorenwerkzeug für bestehende Bilder, neue Vorlagen, händische Gestaltung und automatische Füllung. Start: `Level-Werkzeug.cmd`. Der Start öffnet die zentrale Verwaltung; im Bearbeitungsfenster führt **← Katalog & Entwürfe** zurück.

## Verwaltung

- Farbige Vorschaubilder, Suche nach Motiv/Sammlung, Sammlungsfilter und neun Vorschauen pro Seite.
- **Motiv bearbeiten** öffnet das vorhandene Rätsel. **Speichern** aktualisiert Pfeile, Farben, Titel und den unter **Bilddaten** erfassten Abschlusstext am bestehenden Platz.
- **Sammlung ändern** ordnet das Motiv einer fachlichen Kategorie und spielbaren Sammlung zu. Motivdatei und Identität bleiben gleich.
- **Als neues Motiv kopieren** erstellt einen eigenen Entwurf. Erst **Bilddaten → Als neues Katalogmotiv hinzufügen** gibt ihm einen neuen Katalogplatz.
- **In den Papierkorb** entfernt das Bild aus dem Spiel, seinen Zählungen und aktiven Zuordnungen. Pfeile, Farben, Text und früherer Platz bleiben wiederherstellbar. Mehrfaches Löschen und Wiederherstellen erhält die Katalogreihenfolge.
- **Papierkorb → Motiv wiederherstellen** setzt es wieder an seinen Platz. Es gibt bewusst noch keine endgültige Löschung im Papierkorb.

## Erstellung und Entwürfe

**Neu zeichnen** beginnt mit leeren Flächen. **Vorlage importieren** öffnet ein Bild oder eine vorhandene Motivdatei. Im Bearbeitungsfenster bleiben Flächenzeichnung, Bildinterpretation, automatische Füllung, Spiegeln, manuelle Pfeile, Pipette, Paletten, Verläufe und Farbvariationen verfügbar.

**Entwürfe** zeigt die lokalen, automatisch gesicherten Arbeiten. Name, Abschlusstext, Quellen, Pfeile und Katalogbindung werden mitgesichert. Der sichtbare Entwurf wird bei Änderungen ungefähr alle zwei Sekunden gesichert. **Entwurf speichern** sichert auch ausdrücklich; **Öffnen → Kopie speichern** exportiert eine separate Datei. Neue Arbeiten werden erst durch **Als neues Katalogmotiv hinzufügen** ins Spiel aufgenommen. Das setzt eine vollständige lösbare Füllung und einen Abschlusstext voraus.

## Sicherheit und Spielerexport

Mehrdateiänderungen werden vorbereitet, mit ihren Originalen gesichert und durch ein Transaktionsjournal geschützt. Nach einer Unterbrechung wird eine unvollständige Änderung vor der nächsten Werkstattaktion zurückgenommen. Sicherungen liegen im Projekt unter `work/catalog-backups/`; Entwürfe im privaten Godot-Nutzerverzeichnis unter `workshop_drafts/`.

Zwischenzeitliche Katalogänderungen verhindern stilles Überschreiben. Manuelle Motive, Texte, neue Zuordnungen und Löschungen sind in `collections/editor_overrides.json` gegen Generatorläufe geschützt. Automatische Generatoren dürfen eigene Motive nicht ersetzen und gelöschte Bilder nicht neu veröffentlichen.

Spielstände und Abschlüsse werden über stabile Motivpfade zugeordnet. Verschieben und Wiederherstellen erhalten die Kompatibilität unveränderter Pfeilgeometrie. Entfernte Rätsel verschwinden aus den Zählungen; leere Sammlungen werden im Spielerpfad ausgeblendet. Die Einführung verwendet die tatsächlich vorhandenen Motive statt neun unveränderlicher Plätze.

`tools/build_player.py` baut in einer isolierten Projektkopie. Werkstattmodule, Papierkorb, private Beispiele, Entwürfe, Tests und unveröffentlichte lokale Leveldateien sind vom Spielerexport ausgeschlossen. **Spieler-APK bauen** in der Katalogübersicht erstellt diese neue APK direkt aus der Werkstatt und hält das Fenster währenddessen bedienbar. Nur gespeicherte Katalogänderungen werden übernommen; offene Entwürfe bleiben privat. Auf dem Smartphone werden Änderungen erst durch Installation der neuen APK sichtbar.

## Nächste Ausbaustufen

Stapelbearbeitung, eigenständige Verwaltung neuer Kategorien sowie weiter verbesserte Vorlageninterpretation und Qualitätskontrollen für automatische Füllungen.
