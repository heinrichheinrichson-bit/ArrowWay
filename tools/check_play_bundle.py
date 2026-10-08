"""Validate the shipped Android bundle, manifest, private-tool exclusion and ELF alignment."""
import argparse
import hashlib
import json
import struct
import subprocess
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ANDROID = '{http://schemas.android.com/apk/res/android}'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bundle', type=Path, required=True)
    parser.add_argument('--bundletool', required=True)
    parser.add_argument('--java', required=True)
    parser.add_argument('--report', type=Path, required=True)
    args = parser.parse_args()
    command = [args.java, '-jar', args.bundletool]
    subprocess.run(command + ['validate', '--bundle=' + str(args.bundle)], check=True, stdout=subprocess.DEVNULL)
    manifest = ET.fromstring(subprocess.check_output(command + ['dump', 'manifest', '--bundle=' + str(args.bundle)]))
    sdk = manifest.find('uses-sdk')
    application = manifest.find('application')
    permissions = [item.get(ANDROID + 'name') for item in manifest.findall('uses-permission')]
    assert manifest.get('package') == 'com.thinkheim.arrowjoy'
    assert sdk.get(ANDROID + 'minSdkVersion') == '24'
    assert sdk.get(ANDROID + 'targetSdkVersion') == '36'
    assert application.get(ANDROID + 'debuggable', 'false') == 'false'
    assert application.get(ANDROID + 'allowBackup') == 'false'
    assert not permissions, permissions
    activity = application.find('activity')
    assert activity.get(ANDROID + 'screenOrientation') == '1'
    metadata = {item.get(ANDROID + 'name'): item.get(ANDROID + 'value') for item in application.findall('meta-data')}
    assert metadata['org.godotengine.rendering.method'] == 'gl_compatibility'
    native = []
    with zipfile.ZipFile(args.bundle) as bundle:
        names = bundle.namelist()
        private = ['motif_studio', 'motif_canvas', 'color_studio', 'color_preview', 'catalog_workshop_store', 'catalog_workshop_browser', 'workshop_language_service', 'workshop_text_editor']
        for name in names:
            assert not any('/' + file + '.' in name for file in private), name
            assert not any('/assets/' + folder + '/' in name for folder in ['tools', 'tests', 'work', 'examples', 'release']), name
            assert not any(name.endswith('/' + file) for file in ['editor_overrides.json', 'workshop_manifest.json', 'workshop_trash.json', 'variety_recipes.json']), name
            if not name.endswith('.so'):
                continue
            data = bundle.read(name)
            assert data[:4] == b'\x7fELF'
            endian = '<' if data[5] == 1 else '>'
            is64 = data[4] == 2
            offset = struct.unpack_from(endian + ('Q' if is64 else 'I'), data, 32 if is64 else 28)[0]
            size, count = struct.unpack_from(endian + 'HH', data, 54 if is64 else 42)
            alignments = []
            for index in range(count):
                header = offset + index * size
                kind = struct.unpack_from(endian + 'I', data, header)[0]
                if kind == 1:
                    alignment = struct.unpack_from(endian + ('Q' if is64 else 'I'), data, header + (48 if is64 else 28))[0]
                    alignments.append(alignment)
            assert alignments
            if is64:
                assert min(alignments) >= 16384, (name, alignments)
            native.append({'path': name, 'bits': 64 if is64 else 32, 'load_alignment': min(alignments)})
        abis = sorted({item['path'].split('/')[2] for item in native})
        assert abis == ['arm64-v8a', 'armeabi-v7a', 'x86_64'], abis
        # Godot AABs put game data in an install-time asset pack.
        taxonomy_path = next(name for name in names if name.endswith('/assets/collections/taxonomy.json'))
        asset_root = taxonomy_path.removesuffix('collections/taxonomy.json')
        assert all(asset_root + 'privacy/' + lang + '.txt' in names for lang in ['de', 'en'])
        taxonomy = json.loads(bundle.read(taxonomy_path))
        paths = [entry['path'].removeprefix('res://') for entry in taxonomy['assignments']]
        assert len(paths) == len(set(paths))
        assert all(asset_root + path in names for path in paths)
    report = {'status': 'PASS', 'bundle': args.bundle.name, 'sha256': hashlib.sha256(args.bundle.read_bytes()).hexdigest(), 'package': manifest.get('package'), 'version_code': manifest.get(ANDROID + 'versionCode'), 'version_name': manifest.get(ANDROID + 'versionName'), 'min_sdk': 24, 'target_sdk': 36, 'debuggable': False, 'portrait': True, 'renderer': 'gl_compatibility', 'permissions': permissions, 'abis': abis, 'active_puzzles': len(paths), 'private_workshop_excluded': True, 'offline_privacy_de_en': True, 'native_libraries': native, 'device_testing': 'See Android-Testbericht.md; structural validation alone does not prove runtime compatibility.'}
    args.report.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print('PASS Play bundle:', len(paths), 'puzzles, API 24–36, ARM32/ARM64/x86_64, 16KB ELF alignment, no private workshop.')

if __name__ == '__main__':
    main()
