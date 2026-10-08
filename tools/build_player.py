"""Export an Android player from an isolated copy, without private author tools.
Usage: python tools/build_player.py --godot PATH --output PATH.apk
Uses the local, untracked export_presets.cfg; never changes it.
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
        shutil.copytree(ROOT, stage, ignore=shutil.ignore_patterns('.git', '.godot', 'work', 'builds', 'tools', 'tests', 'examples', 'previews', 'planning', '*.pending', '*.log', '*.apk'))
        public = {entry['path'].removeprefix('res://') for entry in json.loads((stage/'collections/taxonomy.json').read_text(encoding='utf-8-sig'))['assignments']}
        for file in (stage/'levels').glob('*.json'):
            if file.relative_to(stage).as_posix() not in public:
                file.unlink()
        config = stage / 'export_presets.cfg'
        text = config.read_text(encoding='utf-8-sig')
        exclusions = ','.join(sorted(AUTHOR_FILES) + ['collections/editor_overrides.json', 'collections/workshop_trash.json', 'collections/variety_recipes.json', '*.cmd', '*.md'])
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
        for key, value in android_options.items():
            text = re.sub(r'^' + re.escape(key) + r'=.*$', key + '=' + value, text, flags=re.M)
        config.write_text(text, encoding='utf-8')
        subprocess.run([args.godot, '--headless', '--path', str(stage), '--editor', '--quit'], check=True, env=environment)
        subprocess.run([args.godot, '--headless', '--path', str(stage), '--export-debug', 'Android', str(output)], check=True, env=environment)
        with zipfile.ZipFile(output) as apk:
            names = apk.namelist()
            for name in names:
                if any('/' + file.removesuffix('.gd') + '.' in name for file in AUTHOR_FILES):
                    raise RuntimeError('Author tool found in player: ' + name)
                if name.startswith(('assets/tools/', 'assets/tests/', 'assets/work/', 'assets/examples/')):
                    raise RuntimeError('Private author data found in player: ' + name)
        print('PLAYER EXPORTED WITHOUT PRIVATE WORKSHOP:', output)
if __name__ == '__main__':
    main()
