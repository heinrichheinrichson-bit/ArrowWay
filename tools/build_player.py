"""Export an Android player from an isolated copy, without private author tools.
Usage: python tools/build_player.py --godot PATH --output PATH.apk
Uses the local, untracked export_presets.cfg; never changes it.
"""
import argparse, json, os, re, shutil, subprocess, tempfile, zipfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
AUTHOR_FILES = {'motif_studio.gd', 'motif_canvas.gd', 'color_studio.gd', 'color_preview.gd', 'catalog_workshop_store.gd', 'catalog_workshop_browser.gd'}
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
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
        exclusions = ','.join(sorted(AUTHOR_FILES) + ['collections/editor_overrides.json', 'collections/workshop_trash.json', '*.cmd', '*.md'])
        text = re.sub(r'^exclude_filter=.*$', 'exclude_filter="' + exclusions + '"', text, flags=re.M)
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
