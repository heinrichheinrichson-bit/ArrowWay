"""Install our first-party Android bridge in the isolated Godot export only."""
import json
import shutil
from pathlib import Path

def install(root: Path, stage: Path, test_ads: bool) -> None:
    cfg = json.loads((root / 'release/admob.json').read_text())
    build = stage / 'android/build'
    source = build / 'src/main/java/com/thinkheim/arrowjoy/ArrowJoyAds.java'
    source.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(root / 'release/native/ArrowJoyAds.java', source)
    gradle = build / 'build.gradle'
    text = gradle.read_text()
    text = text.replace('dependencies {', 'dependencies {\n    implementation "com.google.android.gms:play-services-ads:'+cfg['ads_sdk']+'"\n    implementation "com.google.android.ump:user-messaging-platform:'+cfg['ump_sdk']+'"', 1)
    gradle.write_text(text)
    manifest = build / 'src/main/AndroidManifest.xml'
    text = manifest.read_text()
    app_id = cfg['test_app_id'] if test_ads else cfg['app_id']
    text = text.replace('<application', '''<uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_ADSERVICES_AD_ID" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_ADSERVICES_ATTRIBUTION" tools:node="remove" />
    <uses-permission android:name="android.permission.ACCESS_ADSERVICES_TOPICS" tools:node="remove" />
    <application''', 1)
    text = text.replace('</application>', f'''<meta-data android:name="org.godotengine.plugin.v2.ArrowJoyAds" android:value="com.thinkheim.arrowjoy.ArrowJoyAds" />
        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="{app_id}" />
        <meta-data android:name="com.google.android.gms.ads.DELAY_APP_MEASUREMENT_INIT" android:value="true" />
        <meta-data android:name="com.google.android.gms.ads.flag.OPTIMIZE_INITIALIZATION" android:value="true" />
        <meta-data android:name="com.google.android.gms.ads.flag.OPTIMIZE_AD_LOADING" android:value="true" />
    </application>''')
    manifest.write_text(text)
    (stage / 'admob_runtime.json').write_text(json.dumps({
        'test_ads': test_ads,
        'interstitial_id': cfg['test_interstitial_id'] if test_ads else cfg['interstitial_id'],
    }))
