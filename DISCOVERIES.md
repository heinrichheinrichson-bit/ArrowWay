# Kurze Entdeckungen

Die Texte erscheinen ab 1,95 Sekunden nach dem letzten Pfeil, mit sanfter Einblendung. Das Kunstwerk bleibt sichtbar, Weiter bleibt bedienbar. Während des Rätsels erscheint keine Textkarte.

`collections/discoveries.json` enthält 509 einzeln zugeordnete Texte: alle 500 Katalogmotive und die 9 Einstiegsmotive. Darunter sind 50 Fakten/Kunstgeschichten mit Quelle und 459 eigene Gedanken. Schlüssel ist der vollständige `res://`-Pfad des Motivs; `kind` benennt die Textart und `text` enthält den eigenen kurzen Wortlaut. Fakten und Kunstgeschichten enthalten zusätzlich `source` und `url`. Eine Quellenaktion öffnet nach Bestätigung den Browser. Alle Texte selbst sind offline verfügbar.

Alle mitgelieferten Spielmotive besitzen nun einen eigenen Abschluss. Nur zusätzliche, noch nicht redaktionell zugeordnete Motive verwenden weiterhin einen Gedanken zur Sammlung oder einen allgemeinen Impuls. Eigene Gedanken sind keine Zitate; Fantasietexte beschreiben bewusst erfundene kleine Szenen. Die Fakten wurden anhand von Originalquellen geprüft, darunter Australian Koala Foundation, Smithsonian, NASA, NOAA, Royal Botanic Gardens Kew, Natural History Museum, IBM, NIST, San Diego Zoo, Yamaha, Universitäten und Kunstmuseen. Neu recherchierte Einträge tragen das Prüfdatum 2026-10-05. Quellen sind direkt an den jeweiligen Einträgen hinterlegt.

Weitere Texte können ergänzt oder überarbeitet werden, ohne Pfeile oder Farben des Motivs zu ändern. Ziel sind kurze, überraschende und zum konkreten Bild passende Texte; keine erfundenen Künstlerzitate. Die flächendeckende erste Textfassung lässt sich später weiter verfeinern und um zusätzliche recherchierte Entdeckungen ergänzen.

Der Spieltitel bleibt in der ursprünglichen kompakten Darstellung zwischen den Symbolen; der obere Abstand berücksichtigt den Kameraausschnitt. `play_safe_area.gd` berücksichtigt auf Mobilgeräten sowohl den sicheren Displaybereich als auch gemeldete Kameraausschnitte und rechnet die physischen Pixel in die skalierten Spielkoordinaten um. Auch die untere Aktion bleibt innerhalb der sicheren Fläche. Die Geräteprüfung auf dem S22 steht noch aus.
