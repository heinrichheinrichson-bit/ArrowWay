# Katalogumbau · Prüfung vom 6. Oktober 2026

Version: 0.19.0-dev auf `feature/neon-progression-map`.

## Ergebnis

- Alle 509 veröffentlichten Motive sind eindeutig zugeordnet: 14 spielbare Themenwelten, 43 Sammlungen inklusive Einstieg.
- Die fachliche Planung umfasst 17 Oberthemen und 123 Unterkategorien. 56 leere Unterkategorien bleiben vorbereitet und unsichtbar.
- Alle 500 Katalog-Leveldateien und die neun Einstiegsdateien sind unverändert. Katalog-Indizes, Dateipfade und Pfeilgeometrien bleiben erhalten.
- Erneutes Generieren verwendet alle 500 vorhandenen Motive aus dem Cache, erhält die aktuelle Zuordnung und bewahrt die bisherige Katalog-Reihenfolge.
- Ältere erreichte Sammlungen behalten Zugriff an ihrem neuen Ort. Nicht erreichte Geschwisterzweige bleiben verborgen. Vollständige Lösungen sind weiterhin Voraussetzung für Häkchen.
- Werbezähler und Schutzphasen verwenden feste Welt-Schlüssel unabhängig von ihrer Kartenposition.

## Ausgeführte Prüfungen

Godot 4.7.2, Windows, Compatibility-Renderer:

- `test_taxonomy.gd`: vollständige Zuordnung, leere Kategorien, stabile Werbeschlüssel, realistische Upgrade-Spielstände, verborgene Geschwisterzweige und Fortsetzung einer Pfeilanimation mit Zoom nach Umordnung.
- `test_journey.gd`: echte Touchbedienung, gemeinsame Mindmap, sämtliche Freischaltungen, genaue Häkchen, Neustart und Erreichbarkeit des ganzen Katalogs. Zusätzlich mit Grafikrenderer und Screenshots geprüft.
- `test_collections.gd`: alle 500 Motive vollständig mit echten Spielzügen gelöst; Füllung, Lösbarkeit, Vorschauen, Filter, Reihenfolge und Fortschritt geprüft.
- `test_catalog_editing.gd`: alle 500 Motive im tatsächlichen Editor unverändert geöffnet; einzelne Pfeilfarben und Rückgängig in allen 42 Katalogsammlungen geprüft.
- `test_player_ui.gd`, `test_mobile_play.gd`, `test_resume.gd`, `test_ads.gd`, `test_discoveries.gd`, `test_library.gd`: jeweils bestanden.
- Bildübersichten aller 42 Katalogsammlungen neu erstellt; Stichproben der neuen Gruppen visuell geprüft.
- Android-Debug-APK gebaut und Signatur verifiziert: `com.example.arrowway`, `0.19.0-dev`, ARM64, festes Hochformat.

Der Android-Export meldet weiterhin das bereits fehlende Projekt-Appsymbol; die APK wurde erfolgreich erstellt und signiert. Ein eigenständiges endgültiges Appsymbol bleibt für die spätere Gestaltung offen. Diese Version wurde nicht auf einem physischen S22 ausgeführt.

Neue Motivzeichnungen für vorbereitete Kategorien wurden in diesem Strukturumbau noch nicht erstellt.
