"""Export an Android player from an isolated copy, without private author tools.
Usage: python tools/build_player.py --godot PATH --output PATH.apk
Debug builds use the local export preset. Release builds use release/android_export.cfg.
Signing secrets are supplied through Godot's release-keystore environment variables.
"""
import argparse, json, os, re, shutil, subprocess, tempfile, zipfile
from pathlib import Path
from check_motif_languages import check_catalog
ROOT = Path(__file__).resolve().parents[1]
AUTHOR_FILES = {'motif_studio.gd', 'motif_canvas.gd', 'color_studio.gd', 'color_preview.gd', 'catalog_workshop_store.gd', 'catalog_workshop_browser.gd', 'workshop_language_service.gd', 'workshop_text_editor.gd'}
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--release', action='store_true')
    parser.add_argument('--version-code', type=int)
    args = parser.parse_args()
    problems = check_catalog(ROOT)
    if problems:
        for item in problems: print(item['title'] + ': ' + '; '.join(item['issues']))
        raise SystemExit('APK nicht gebaut: englische Texte bitte in der Werkstatt prüfen oder vervollständigen.')
    environment = os.environ.copy()
    java = Path('C:/Program Files/Android/Android Studio/jbr')
    if not environment.get('JAVA_HOME') and java.exists(): environment['JAVA_HOME'] = str(java)
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    scratch = ROOT.parent.parent / 'work'
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='player-export-', dir=scratch) as folder:
        stage = Path(folder) / 'project'
        built_output = Path(folder) / output.name
        shutil.copytree(ROOT, stage, ignore=shutil.ignore_patterns('.git', '.godot', 'work', 'builds', 'tools', 'tests', 'examples', 'previews', 'planning', 'release', 'android', '*.jks', '*.keystore', '*.aab', '*.pending', '*.log', '*.apk'))
        public = {entry['path'].removeprefix('res://') for entry in json.loads((stage/'collections/taxonomy.json').read_text(encoding='utf-8-sig'))['assignments']}
        for file in (stage/'levels').glob('*.json'):
            if file.relative_to(stage).as_posix() not in public:
                file.unlink()
        config = stage / 'export_presets.cfg'
        release_config = json.loads((ROOT / 'release/play_config.json').read_text()) if args.release else {}
        if args.release:
            shutil.copyfile(ROOT / 'release/android_export.cfg', config)
        text = config.read_text(encoding='utf-8-sig')
        # An export-only staging project must not poll or disconnect USB devices.
        text = re.sub(r'(?ms)^\[runnable_presets\].*?(?=^\[preset\.)', '', text)
        text = re.sub(r'^include_filter=.*$', 'include_filter="privacy/*.txt"', text, flags=re.M)
        exclusions = ','.join(sorted(AUTHOR_FILES) + ['collections/editor_overrides.json', 'collections/workshop_trash.json', 'collections/workshop_manifest.json', 'collections/variety_recipes.json', '*.cmd', '*.md'])
        text = re.sub(r'^exclude_filter=.*$', 'exclude_filter="' + exclusions + '"', text, flags=re.M)
        # Keep the installed application identity stable when the display name changes.
        android_options = {
            'package/unique_name': '"com.example.arrowway"',
            'package/name': '"arrow.joy"',
            'launcher_icons/main_192x192': '"res://branding/icon.png"',
            'launcher_icons/adaptive_foreground_432x432': '"res://branding/adaptive_foreground.png"',
            'launcher_icons/adaptive_background_432x432': '"res://branding/adaptive_background.png"',
            'launcher_icons/adaptive_monochrome_432x432': '"res://branding/adaptive_monochrome.png"',
            'splash_screen/icon': '"res://branding/icon.png"',
            'splash_screen/background_color': 'Color(0.027, 0.075, 0.176, 1)',
        }
        if args.release:
            required = ['GODOT_ANDROID_KEYSTORE_RELEASE_PATH', 'GODOT_ANDROID_KEYSTORE_RELEASE_USER', 'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD']
            if any(not environment.get(key) for key in required):
                raise SystemExit('Release signing environment is incomplete.')
            android_options.update({
                'package/unique_name': json.dumps(release_config['package']),
                'version/code': str(args.version_code or release_config['version_code']),
                'version/name': json.dumps(release_config['version_name']),
                'gradle_build/use_gradle_build': 'true',
                'gradle_build/export_format': '1' if output.suffix == '.aab' else '0',
                'gradle_build/min_sdk': '"24"',
                'gradle_build/target_sdk': '"36"',
                'architectures/armeabi-v7a': 'true',
                'architectures/arm64-v8a': 'true',
                'architectures/x86_64': 'true',
            })
            project = stage / 'project.godot'
            project_text = project.read_text(encoding='utf-8-sig')
            project_text = re.sub(r'^config/version=.*$', 'config/version=' + json.dumps(release_config['version_name']) + '\nrun/max_fps=60', project_text, flags=re.M)
            project_text = project_text.replace('renderer/rendering_method="gl_compatibility"', 'renderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"')
            project.write_text(project_text, encoding='utf-8')
            template = Path(os.environ['APPDATA']) / 'Godot/export_templates/4.7.2.stable/android_source.zip'
            with zipfile.ZipFile(template) as source:
                source.extractall(stage / 'android/build')
            (stage / 'android/.gdignore').write_text('', encoding='utf-8')
            (stage / 'android/.build_version').write_text('4.7.2.stable', encoding='utf-8')
            # Use the locally installed, API-36-compatible Android toolchain.
            gradle_config = stage / 'android/build/config.gradle'
            gradle_config.write_text(gradle_config.read_text().replace("'8.6.1'", "'8.13.2'").replace("'36.1.0'", "'36.0.0'").replace("'2.1.21'", "'2.2.20'").replace("'29.0.14206865'", "'28.2.13676358'"))
            settings = stage / 'android/build/settings.gradle'
            settings.write_text(settings.read_text().replace("    plugins {", "    resolutionStrategy { eachPlugin { if (requested.id.id.startsWith('com.android.')) useModule('com.android.tools.build:gradle:8.13.2'); if (requested.id.id == 'org.jetbrains.kotlin.android') useModule('org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20') } }\n    plugins {"))
            wrapper = stage / 'android/build/gradle/wrapper/gradle-wrapper.properties'
            wrapper.write_text(wrapper.read_text().replace('gradle-8.11.1-bin.zip', 'gradle-8.14.3-all.zip'))
        for key, value in android_options.items():
            text = re.sub(r'^' + re.escape(key) + r'=.*$', key + '=' + value, text, flags=re.M)
        config.write_text(text, encoding='utf-8')
        subprocess.run([args.godot, '--headless', '--audio-driver', 'Dummy', '--path', str(stage), '--editor', '--quit'], check=True, env=environment)
        try:
            subprocess.run([args.godot, '--headless', '--audio-driver', 'Dummy', '--path', str(stage), '--export-release' if args.release else '--export-debug', 'Android', str(built_output), '--quit'], check=True, env=environment, timeout=1200)
        except subprocess.TimeoutExpired:
            raise SystemExit('Android exporter did not exit within 20 minutes. Existing output has not been replaced; inspect the export log before retrying.')
        with zipfile.ZipFile(built_output) as apk:
            names = apk.namelist()
            for name in names:
                if any('/' + file.removesuffix('.gd') + '.' in name for file in AUTHOR_FILES):
                    raise RuntimeError('Author tool found in player: ' + name)
                if re.search(r'(?:^|/)assets/(?:tools|tests|work|examples)/', name):
                    raise RuntimeError('Private author data found in player: ' + name)
        shutil.copyfile(built_output, output)
        print('PLAYER EXPORTED WITHOUT PRIVATE WORKSHOP:', output)
if __name__ == '__main__':
    main()
