# Kurze Entdeckungen

Die Texte erscheinen ab 1,95 Sekunden nach dem letzten Pfeil, mit sanfter Einblendung. Das Kunstwerk bleibt sichtbar, Weiter bleibt bedienbar. Während des Rätsels erscheint keine Textkarte.

`collections/discoveries.json` enthält 20 einzeln zugeordnete Texte. Schlüssel ist der vollständige `res://`-Pfad des Motivs; `kind` benennt die Textart und `text` enthält den eigenen kurzen Wortlaut. Fakten und Kunstgeschichten enthalten zusätzlich `source` und `url`. Eine Quellenaktion öffnet nach Bestätigung den Browser. Alle Texte selbst sind offline verfügbar.

Die übrigen Motive erhalten einen eigenen Gedanken passend zur Sammlung, soweit vorhanden; andernfalls einen allgemeinen kurzen Impuls. Diese Gedanken sind weder Zitate noch Tatsachenbehauptungen. Die ersten Fakten wurden anhand der Australian Koala Foundation, Smithsonian Ocean, NASA, der Eiffelturm-Betreibergesellschaft, des Van Gogh Museum und des Metropolitan Museum of Art geprüft. Quellen sind direkt an den jeweiligen Einträgen hinterlegt.

Weitere Texte können ergänzt werden, ohne Pfeile oder Farben des Motivs zu ändern. Ziel sind kurze, überraschende und zum konkreten Bild passende Texte; keine erfundenen Künstlerzitate. Der neue Katalog ersetzt noch keine vollständige Redaktion aller 500 Motive.

Der Spieltitel bleibt in der ursprünglichen kompakten Darstellung zwischen den Symbolen; der obere Abstand berücksichtigt den Kameraausschnitt. `play_safe_area.gd` berücksichtigt auf Mobilgeräten sowohl den sicheren Displaybereich als auch gemeldete Kameraausschnitte und rechnet die physischen Pixel in die skalierten Spielkoordinaten um. Auch die untere Aktion bleibt innerhalb der sicheren Fläche. Die Geräteprüfung auf dem S22 steht noch aus.
