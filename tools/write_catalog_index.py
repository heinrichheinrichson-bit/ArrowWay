"""Write a human-readable index of the installed, generated motif library."""
import json
from pathlib import Path

root=Path(__file__).resolve().parents[1]
catalog=json.loads((root/'collections/catalog.json').read_text(encoding='utf-8-sig'))
groups={}
for entry in catalog['levels']:
    groups.setdefault(entry['collection']['id'],[]).append(entry)
lines=['# ArrowWay · Alle 500 Katalogmotive','',
       f'{len(catalog["levels"])} spielbare Sammlungsrätsel in {len(groups)} Sammlungen. Mit den neun Einstiegspuzzles enthält die Spielerreise 509 Motive. Eigene Editorentwürfe bleiben getrennt.', '',
       'Im Spiel **Reise** öffnen und eine freigeschaltete Sammlung im Themenbaum wählen. Zum Nachbearbeiten die verlinkte JSON-Datei in der Motivwerkstatt über **Öffnen → Bild, Motiv oder Level-Datei** laden. Persönliche Varianten unter einem eigenen Namen in `levels/` exportieren.', '',
       'Der Katalog enthält eigenständige Motive und Varianten gemeinsamer Motivfamilien, etwa unterschiedliche Tiergesichter, Stadtansichten und Smartphoneanzeigen. Pfeilgeometrie und Farbflächen unterscheiden sich; bloße Umfärbungen werden nicht als neue Motive gezählt. Die Gestaltungsrezepte bleiben reproduzierbar. Menschliche Spieltests und individuelle gestalterische Verfeinerungen bleiben sinnvoll.', '',
       '| Sammlung | Motive | Bildübersicht |','|---|---:|---|']
for group,entries in groups.items():
    lines.append(f'| {entries[0]["collection"]["title"]} | {len(entries)} | [Ansehen](previews/collection-{group}.png) |')
for group,entries in groups.items():
    lines.extend(['',f'## {entries[0]["collection"]["title"]}','',f'[Bildübersicht dieser Sammlung](previews/collection-{group}.png)',''])
    for entry in entries:
        path=entry['path'].removeprefix('res://')
        lines.append(f'- [{entry["title"]}]({path}) · {entry["design"]["paths"]} Pfeile')
(root/'CATALOG.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(f'Indexed {len(catalog["levels"])} motifs in {len(groups)} collections')
