# Vollständige Sicherung des persönlichen App-Stands

Im Spiel: **Einstellungen → App-Stand → App-Stand sichern**. Eine einzige JSON-Datei enthält Einstellungen, Fortschritt und Zugriffsgruppen der Reise, Lieblingsbilder, alle gespeicherten Motiv-Sitzungen inklusive entfernter und fliegender Pfeile, Fehlern, Spielzeiten, Zoom und Bildposition sowie Werbezähler und aktuelle Testeinstellungen.

**App-Stand wiederherstellen** öffnet eine Datei und zeigt Datum, gelöste Rätsel, Lieblingsbilder und angefangene Rätsel. Erst **Wiederherstellen** übernimmt die Daten. Die App baut ihre Ansicht anschließend neu auf; Sprache, Ton und Rätselstände gelten sofort.

Vor dem Import wird `before-restore.json` im privaten App-Ordner geschrieben. **Vorherigen Stand wiederherstellen** öffnet diese Sicherung mit derselben Vorschau. Jeder weitere bestätigte Import sichert erneut den gerade aktuellen Stand. Die manuell exportierte Datei bleibt unverändert.

## Umfang und Kompatibilität

- Format `arrow.joy.app-state`, Version 1; UTF-8-JSON, offline und ohne Konto.
- Einstellungen, Fortschritt, Bibliothek, Sitzungen und Werbestatus werden aus den sieben erlaubten Datendateien übernommen, einschließlich vorhandener Rückfalldateien für Sitzungen und Werbung. Unbekannte Dateinamen sind nicht erlaubt.
- Motivpfade und Kategorien-Kennungen werden gespeichert. Umordnung des Katalogs ändert die Zuordnung nicht. Im aktuellen Katalog fehlende Motive werden bei der Anzeige übersprungen. Veränderte Pfeilgeometrie startet die betreffende Sitzung neu; unveränderte oder ausdrücklich kompatible Motive behalten ihren Rätselstand.
- Die installierte App, der mitgelieferte Katalog, Werkstattentwürfe und temporäre Menüs sind kein Bestandteil dieser persönlichen Sicherung.
- Android verwendet `FileDialog.use_native_dialog` mit `ACCESS_FILESYSTEM` und dem JSON-MIME-Typ. Die vom System zurückgegebene Dokument-URI wird direkt mit `FileAccess` gelesen oder geschrieben; keine umfassende Speicherberechtigung ist nötig. Desktop verwendet ebenfalls die native Dateiauswahl, falls verfügbar.

## Zuverlässigkeit

Vor dem Export werden aktive Sitzung und Zähler gespeichert. Jeder enthaltene Text hat eine SHA-256-Prüfsumme. Import prüft Formatversion, Größe (maximal 16 MiB), Dateinamen, Prüfsummen, Konfigurationswerte und Sitzungsdaten, bevor etwas übernommen wird. Prüfsummen erkennen Beschädigungen, sie authentifizieren keine fremden Dateien.

Ein Wiederherstellungsjournal enthält den vorherigen Stand. Fehler während des Imports lösen eine Rücknahme aus; ein unterbrochener Import wird beim nächsten Start zurückgenommen, bevor die App ihre Daten lädt. Laufende Sitzungsschreiber werden vor dem Neuaufbau deaktiviert, damit alte Daten den Import nicht überschreiben.

`tests/test_app_state_backup.gd` prüft Export, beschädigte und fremde Dateien, Vorschau/Abbrechen, exakte Übernahme der Datendateien, Neuaufbau, Einstellungen, Rätsel und Kameraposition, Werbezähler, Rücknahme, automatische Sicherung, fehlgeschlagene Sicherung und Start nach einem unterbrochenen Import. Der native Dokumentdialog muss zusätzlich auf dem Zielgerät geprüft werden.
