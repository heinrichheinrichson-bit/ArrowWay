# Deutsch und Englisch

Im Spiel unter **Einstellungen → Sprache** stehen **Systemsprache**, **Deutsch**
und **Englisch** zur Wahl. Ohne gespeicherte Auswahl gilt die Systemsprache:
Deutsch für deutsche Geräte-Sprachen, Englisch für alle anderen. Die Auswahl
wirkt sofort und bleibt beim nächsten Start erhalten. Zurück zu Systemsprache
folgt wieder der Gerätesprache, auch nach einer Änderung während einer Pause.

## Übersetzungen pflegen

- `app_language.gd` verwaltet Auswahl, gespeicherte Einstellung und Anzeige.
- `localization/en.json` enthält die offline mitgelieferten englischen Texte.
  Schlüssel sind die vollständigen deutschen Originaltexte; Werte sind Englisch.
- Rätselnamen, Kategorien, Themenwelten, Abschlusstexte, Quellenbezeichnungen und
  Oberflächentexte verwenden dieselbe Übersetzungsschicht. Quellen-URLs,
  Motivdateien, Kennungen, Reihenfolge und Spielstände bleiben unverändert.
- Variablen wie `%d` oder `%s` müssen in der Übersetzung in derselben Reihenfolge
  stehen. Bei UI-Texten wird die Vorlage **vor** dem Einsetzen der Werte übersetzt.
- Neue oder geänderte deutsche Texte brauchen einen passenden Eintrag in
  `localization/en.json`. `python tools/localization_catalog.py` meldet fehlende
  Einträge und gibt bei unvollständiger Abdeckung einen Fehlercode zurück.
- Die private Motivwerkstatt bleibt deutsch und bearbeitet Originaldaten. Eine
  englische Anzeige im Spiel wird niemals als neuer deutscher Originaltext
  zurück in eine Motivdatei gespeichert.

## Prüfen

`godot --headless --audio-driver Dummy --path . --script res://tests/test_localization.gd -- --test`

Der Test prüft alle aktiven veröffentlichten Rätsel und Abschlusstexte, die
Sprachwahl im Menü, Systemeinstellung und Rückfall auf Englisch, das sofortige
Umschalten, getrennte Soundeinstellungen, erhaltenen Fortschritt und Zoom sowie
den Sprachwechsel auf einem bereits abgeschlossenen Kunstwerk.

Mit `--capture-dir ABSOLUTER_ORDNER` hinter `--test` und ohne `--headless` erstellt
derselbe Test Bildschirmbilder für die visuelle Prüfung beider Sprachen.

Die APK enthält die Übersetzungen. Das Spiel benötigt dafür weder Internet
noch einen Übersetzungsdienst.

## Redaktionelle Prüfung der Abschlusstexte

Am 8. Oktober 2026 wurden sämtliche englischen Abschlusstexte und Ersatztexte
mit den deutschen Originalen abgeglichen und sprachlich geprüft. Wortspiele und
Gedanken sind sinngemäß formuliert. Dies war keine erneute externe Faktenrecherche.
`localization/completion_review.json` dokumentiert die geprüften Textstände mit
SHA-256-Prüfsummen; geänderte Originaltexte benötigen erneut eine Prüfung.

## Zweisprachige Motivwerkstatt

Unter **Bilddaten → Deutsch & Englisch bearbeiten …** stehen Original und
Übersetzung nebeneinander. Bestehende englische Texte werden geladen. Änderungen
an Pfeilen und Farben gelten für beide Sprachen. **Beide Sprachen speichern**
übernimmt Namen und Texte gemeinsam am bisherigen Katalogplatz.

Änderungen am deutschen Text markieren die zugehörige englische Fassung zur
Prüfung. Englisch bleibt erhalten. Nach Bearbeitung oder bewusstem Abgleich
bestätigt **Englisch geprüft** den aktuellen Stand. Die Vorschau zeigt beide
Abschlussbilder. Entwürfe behalten beide Sprachen und Prüfmarkierungen.

Der Katalogfilter **Englisch offen** findet unvollständige oder ungeprüfte Motive.
Speichern ist auch mit offenen Texten möglich; ein APK-Bau wartet jedoch, bis
alle veröffentlichten Motive vollständig geprüft sind. Es gibt keine automatische
Online-Übersetzung.

Motivübersetzungen liegen unter ihrem stabilen Dateipfad in
`localization/motifs.json`; sie haben Vorrang vor der bisherigen allgemeinen
Übersetzung. Gleiche deutsche Namen können dadurch unterschiedliche englische
Fassungen erhalten. Die Werkstatt bleibt privat und wird nicht mitexportiert.

Prüfung: `python tools/check_motif_languages.py` und
`godot --headless --audio-driver Dummy --path . --script res://tests/test_workshop_languages.gd -- --test`.
