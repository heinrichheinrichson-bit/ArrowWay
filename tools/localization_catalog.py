"""Extract player-facing German messages; keep translations outside puzzle data.

The translation JSON is shipped offline. This tool only audits/extracts sources;
it does not contact a translation service or rewrite authored puzzles.
"""
import json, re, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLAYER_SCRIPTS = ['main.gd', 'journey_view.gd', 'journey_progress.gd',
                  'journey_station.gd', 'journey_puzzle_card.gd', 'level_card.gd',
                  'discovery_card.gd', 'discoveries.gd', 'ad_controller.gd']
STRING = re.compile(r'"(?:\\.|[^"\\])*"', re.S)
SINGLES = {'Zurück','Weiter','Hinweis','Einstellungen','Soundeffekte','Geschafft',
           'Spielbar','Spielen','Losspielen','Fortsetzen','Gesperrt','Einstieg',
           'Herzenswege','Herzklopfen','Meerespause','Verflochten','Knifflig',
           'Füllen','Fertig','Auswahl','Drehen','Leeren','Prüfen','Testen',
           'Speichern','Laden','Export','Herz','Haus','Baum','Blume','Welle',
           'Weiterreisen','Leuchtet','Entdeckt','Sprache','Deutsch','Englisch',
           'Systemsprache','Sonnenblumen','Winterlabyrinth','Lieblingsbilder',
           'Neustart','Fisch','Spiel','Zeichnen','Leer','Natur','Pflanzen',
           'Symbole','Tiere','Architektur','Weihnachtsbaum','Schmetterling',
           'LEVEL-WERKZEUG','MOTIVBIBLIOTHEK','Verschnaufpause'}

def decode(literal):
    return json.loads(literal, strict=False)

def human(value):
    if value in SINGLES: return True
    if not re.search(r'[a-zA-ZäöüÄÖÜß]', value): return False
    if any(t in value for t in ('res://','user://','http://','https://','<svg','<path',
                               '<circle','<g ',"fill=",'stroke=', 'position:', 'assets/')):
        return False
    if value.startswith(('--','[url=', '#')): return False
    if '_' in value and ' ' not in value: return False
    if re.fullmatch(r'[A-Za-z0-9_./:-]+', value) and not re.search('[äöüÄÖÜß]',value):
        return False
    return ' ' in value or bool(re.search('[äöüÄÖÜß]',value))

def sources(include_head=False):
    values = set()
    for name in PLAYER_SCRIPTS:
        for match in STRING.finditer((ROOT/name).read_text(encoding='utf-8-sig')):
            value = decode(match.group())
            if human(value): values.add(value)
    fields = {'title','collection_title','text','kind','notice','source','description','subtitle'}
    def collect(data, field=''):
        if isinstance(data,dict):
            for key,value in data.items(): collect(value,key)
        elif isinstance(data,list):
            for value in data: collect(value,field)
        elif isinstance(data,str) and (field in fields or field=='tags') and data.strip():
            values.add(data)
    paths = [ROOT/'collections'/n for n in ('catalog.json','journey.json','taxonomy.json','discoveries.json','art_credits.json','published.json')]
    paths += list((ROOT/'levels').glob('*.json')) + list((ROOT/'collections/levels').glob('*.json'))
    for path in paths:
        if path.exists(): collect(json.loads(path.read_text(encoding='utf-8-sig')))
    if include_head:
        # Also cover the committed catalogue when the author has unpublished edits.
        for name in ['collections/catalog.json','collections/discoveries.json','collections/journey.json','collections/taxonomy.json'] + [f'levels/{n:02d}.json' for n in range(1,10)]:
            result=subprocess.run(['git','show','HEAD:'+name],cwd=ROOT,capture_output=True)
            if result.returncode==0: collect(json.loads(result.stdout))
    values.update(SINGLES)
    return sorted(values)

if __name__=='__main__':
    messages=json.loads((ROOT/'localization/en.json').read_text(encoding='utf-8'))['messages']
    missing=[s for s in sources() if s not in messages]
    print('Messages:',len(messages),'Missing:',len(missing))
    for s in missing: print(s)
    raise SystemExit(bool(missing))
