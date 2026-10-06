"""Prepare curated, attributed vector outlines for conversion into editable masks."""
import argparse
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PALETTES = {'rose': ['ff568f', 'ffd9e7'], 'sky': ['65d5ff', 'd9f6ff'], 'mint': ['4cf0c4', 'e5fffa'], 'violet': ['b58aff', 'eaddff'], 'gold': ['ffd267', 'fff1b9'], 'earth': ['e9ad68', 'ffe0ab'], 'pearl': ['e0f4ff', 'b1d4ec'], 'leaf': ['51ec91', 'aeff91']}
OVERRIDES = {'flamingo':'ff89b5', 'pelican':'ecf5ff', 'heart-organ': 'ff5478', 'lungs': 'ff9fba', 'brain': 'c99cff', 'tooth': 'e9f7ff', 'axolotl': 'ff9fce', 'salamander': 'ffe34d', 'ladybug': 'ff536b', 'scarab-beetle': '55e5bf', 'bee': 'ffd247', 'ammonite-fossil': 'efbb79', 'eggplant': 'b284ff', 'beet': 'ed5f93', 'cotton-flower': 'edf6ff', 'dandelion-flower': 'ffe767', 'corn': 'ffe55b', 'garlic': 'fff0d2', 'anvil': 'a2ccf1', 'bandage-roll': 'fff0db', 'fossil': 'e2c192', 'dinosaur-bones': 'fff0d3', 'philosopher-bust': 'e0dcf3'}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--icons', type=Path, required=True)
    args = parser.parse_args()
    index = {}
    for p in sorted(args.icons.rglob('*.svg'), key=lambda p: (['delapouite', 'lorc', 'caro-asercion'].index(p.parent.name) if p.parent.name in ['delapouite', 'lorc', 'caro-asercion'] else 9, str(p))):
        index.setdefault(p.stem, p)
    for p in (ROOT/'collections/original_vectors').glob('*.svg'): index.setdefault(p.stem,p)
    taxonomy = json.loads((ROOT/'collections/taxonomy.json').read_text(encoding='utf-8-sig'))
    categories = {c['id']: (w,c) for w in taxonomy['worlds'] for c in w['categories']}
    destination = ROOT/'collections/vector_sources'
    destination.mkdir(exist_ok=True)
    entries, missing, used = [], [], set()
    category, palette = '', ''
    commit = subprocess.check_output(['git', '-C', str(args.icons), 'rev-parse', 'HEAD'], text=True).strip()
    for line in (ROOT/'planning/NEUE_MOTIVE.txt').read_text(encoding='utf-8').splitlines():
        if not line or line.startswith('#'): continue
        if line.startswith('@'):
            category,palette=line[1:].split('|'); assert category in categories; continue
        icon,title,text=line.split('|')
        if icon not in index:
            missing.append(icon); continue
        assert icon not in used, f'Duplicate source: {icon}'
        used.add(icon)
        source=index[icon]; w,c=categories[category]
        key='new_'+icon.replace('-','_')
        shutil.copyfile(source,destination/(key+'.svg'))
        colors=PALETTES[palette].copy(); colors[0]=OVERRIDES.get(icon, colors[0])
        own=source.parent.name=='original_vectors'
        entries.append(dict(key=key, title=title, category=category, world=w['id'], colors=colors, svg='res://collections/vector_sources/'+key+'.svg', text=text,
            attribution=dict(author='ArrowWay' if own else source.parent.name, source='https://github.com/heinrichheinrichson-bit/ArrowWay/blob/feature/neon-progression-map/collections/original_vectors/'+source.name if own else 'https://github.com/game-icons/icons/blob/'+commit+'/'+source.parent.name+'/'+source.name, license='Originalgestaltung' if own else ('CC0' if source.parent.name=='viscious-speed' else 'CC BY 3.0'), changes='Rasterized, simplified, colored and filled with solvable neon arrow paths.')))
    (ROOT/'collections/expansion_recipes.json').write_text(json.dumps(dict(version=1, source_commit=commit, entries=entries),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    shutil.copyfile(args.icons/'license.txt', destination/'LICENSE.txt')
    print(f'{len(entries)} curated motifs; {len(missing)} missing outlines: '+', '.join(missing))

if __name__=='__main__': main()
