# Play-Build für arrow.joy

Der Release-Build verwendet `release/play_config.json` und das öffentliche Preset `release/android_export.cfg`. Debug-APKs bleiben bei `com.example.arrowway`; Play-Releases verwenden `com.thinkheim.arrowjoy`.

Erforderlich: Godot 4.7.2 und passende Export-Templates, Java 17 oder höher, Android SDK Plattform 36 / Build-Tools 36.0.0. Der installierte Gradle-Build verwendet AGP 8.13.2, Gradle 8.14.3, Kotlin 2.2.20 und NDK 28.2.13676358. Die native Godot-Engine wird aus dem offiziellen Template übernommen und nicht selbst neu kompiliert.

Den privaten Upload-Schlüssel nie ins Repository oder Store-Unterlagen kopieren. Er wird über folgende Umgebungsvariablen übergeben:

- GODOT_ANDROID_KEYSTORE_RELEASE_PATH
- GODOT_ANDROID_KEYSTORE_RELEASE_USER
- GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD

`python tools/build_player.py --godot PATH --release --output PATH.aab`

Versionsname und Standard-Versionscode stehen in play_config.json; einen höheren Code kann man mit `--version-code` übergeben. Vor jedem späteren Play-Upload Code erhöhen. Nicht mehrere Exporte gleichzeitig auf dieselbe Ausgabedatei starten.

Der Export erfolgt in einer isolierten Kopie. Persönliche Quelldateien, Werkstatt, Skriptwerkzeuge und Schlüssel werden ausgeschlossen. Gelöschte/private Intro-Dateien werden aus der Kopie entfernt. Die mobile Version verwendet OpenGL Compatibility und höchstens 60 FPS.

`python tools/check_play_bundle.py --bundle PATH.aab --bundletool PATH.jar --java PATH --report PATH.json`

Die zusätzliche Prüfung kontrolliert Bundle-Struktur, Manifest, SDKs, Hochformat, Renderer, Berechtigungen, alle öffentlichen Katalogpfade, Werkstattausschluss und die ELF-Ausrichtung für 16-KB-Seiten bei beiden 64-Bit-Architekturen.

Store-Texte und Datenschutztexte sind versioniert. Store-Grafiken und signierte Ausgaben liegen außerhalb des Repositorys im Ausgabeordner. Der öffentliche Datenschutz-Link muss vor der Play-Einreichung bereitstehen.
