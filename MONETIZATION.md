# Werbung: Grundlage und Offline-Test

Es ist noch kein Werbe-SDK und kein Zahlungsanbieter angeschlossen. Es werden keine echten Anzeigen geladen, keine Käufe angeboten und keine Daten an einen Werbedienst übertragen.

## Vereinbarte Regeln

- Die ersten fünf neu gelösten Rätsel sind komplett werbefrei. Die erste Anzeige kann frühestens nach dem sechsten Abschluss erscheinen.
- Später müssen mindestens vier neue Rätselabschlüsse und sechs Minuten aktiver Spielzeit seit der letzten tatsächlich angezeigten Werbung zusammenkommen.
- Spielzeit zählt nur während eines laufenden Rätsels im Vordergrund. Menüs, Album, Dialoge, Hintergrundzeit, Werbezeit und das fertige Abschlussbild zählen nicht.
- Einzig der normale Weiterreisen-Wechsel von einem fertigen Rätsel ins nächste ist ein Werbeplatz. Erst Lichtwelle und Text, dann eine bewusste Betätigung von Weiterreisen, gegebenenfalls Anzeige, dann das nächste Rätsel.
- Abschluss einer Sammlung oder Themenwelt und das erstmalige Öffnen einer Welt sind geschützt. Ein neuer Weltabschnitt bleibt bis zu seinem ersten neuen Rätselabschluss geschützt. Danach kann ein normaler Übergang wieder berechtigt sein.
- Verschobene Anzeigen werden nicht aufgestapelt. Nach einer tatsächlich angezeigten Werbung beginnen beide Abstände neu. Ist kein Anbieter bereit, wird sofort weitergespielt und nichts zurückgesetzt.
- Gespeicherte oder erneut gespielte bereits gelöste Rätsel zählen nicht erneut als neuer Abschluss. Bestehende öffentliche Erfolge werden bei einem Update übernommen.

## Auf dem Smartphone testen

In der Entwicklungsfassung: Startseite → Einstellungen → **Testanzeigen aktivieren**. Der Schalter ist standardmäßig aus. Die vereinbarten Abstände gelten auch im Testmodus; es gibt keinen verkürzten Takt und kein künstliches Warten. Eine geeignete Runde öffnet einen Dialog mit der eindeutigen Kennzeichnung „Testanzeige · keine echte Werbung“. **Weiterreisen** oder Zurück schließt ihn und setzt den vorgesehenen Übergang genau einmal fort.

**Werbefrei simulieren** schaltet auch die Testanzeigen aus. Das ist ein separater Entwicklungszustand, kein Kauf und kein echtes Kaufrecht. Beide Schalter fehlen in einer Release-Fassung.

## Technischer Anschluss später

`ad_policy.gd` entscheidet über Abstände und Schutz. `ad_controller.gd` speichert Zähler und aktive Spielzeit in `user://ads.json`, schreibt über eine temporäre Datei und hält eine Sicherung für beschädigte Dateien vor. Es speichert während des Spiels spätestens nach 15 aktiven Sekunden sowie bei Abschluss, Anzeige, Fokusverlust und App-Pause.

`is_ad_free()` ist die zentrale Abfrage. `set_verified_ad_free()` ist für den späteren Anschluss von Kauf und Kaufwiederherstellung vorgesehen; derzeit existiert dafür kein Zahlungsablauf. Ein echter Anbieter muss Anzeigen vorladen, fehlende Anzeigen sofort überspringen und den Zähler erst bei tatsächlicher Anzeige zurücksetzen. Der Kauf soll sämtliche Werbung ausschalten. Ein späterer freiwilliger Belohnungsclip muss den Werbeabstand ebenfalls neu beginnen lassen und für Käufer eine gleichwertige Möglichkeit ohne Anzeige erhalten.

`tests/test_ads.gd` prüft Regeln, echte Weiterreisen-Übergänge, Abschlussfeiern, Weltöffnung, inaktive Zeiten, Werbefreiheit, fehlenden Anbieter, doppelte Betätigungen und Wiederherstellung aus der Sicherung.
