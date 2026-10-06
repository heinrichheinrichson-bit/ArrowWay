"""Publish validated additions, preserving every existing catalog index and access ID."""
import json
from collections import Counter
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,value): (ROOT/p).write_text(json.dumps(value,ensure_ascii=False,indent=None if p=='collections/source_masks.json' else 2)+'\n',encoding='utf-8')

MAPPING={
 'animals': ['animals','birds','insects','spiders','reptiles','amphibians','ocean'],
 'plants': ['flowers','forests','tropical','mushrooms','garden'],
 'seasons': ['changing_seasons','changing_seasons','changing_seasons','winter','christmas','easter','halloween','traditions','traditions','traditions','traditions'],
 'home': ['homes','kitchen','rooms','rooms','bathroom','rooms','rooms','cozy','cozy','household','fashion'],
 'food': ['fruit','vegetables','bakery','bakery','taste','meals','meals','world_cuisine'],
 'craft': ['workshop','workshop','workshop','installation','workshop','textiles','pottery','farming','professions'],
 'tech': ['vintage_technology','vintage_technology','vintage_technology','technology','computers','smartphones','technology','communication','technology'],
 'science': ['mathematics','science_basics','science_basics','biology','geology','research'],
 'medicine': ['anatomy','senses','medical_care','medical_care','dental','medical_history'],
 'space': ['space','spaceflight','spaceflight','cosmos','cosmos'],
 'travel': ['vehicles','rail','ships','aircraft','historic_vehicles','skylines','world','travel','camping'],
 'history': ['antiquity','medieval','castles','archaeology','historic_life','ancient_writing','cultural_architecture'],
 'culture': ['art','sculptures','art','literature','art'],
 'leisure': ['music','ball_sports','sports','water_sports','sports','sports','sports','sports','toys','board_games','stage_and_fun','stage_and_fun','music','stage_and_fun'],
 'fantasy': ['fantasy','creatures','creatures','fantasy'],
}
NEW_GROUPS={
 'insects':('Insekten','flower','baff79'), 'spiders':('Spinnen & Skorpione','moon','c7a1ff'), 'reptiles':('Reptilien','paw','66eeb3'), 'amphibians':('Amphibien','fish','ff9fce'),
 'forests':('Bäume & Wälder','tree','89efb0'), 'tropical':('Tropisches Grün','flower','55e5c5'), 'mushrooms':('Pilze','tree','ffd078'),
 'changing_seasons':('Frühling, Sommer & Herbst','flower','a4ee78'), 'traditions':('Feste & Traditionen','spark','f5a1d8'),
 'homes':('Häuser & Wohnorte','house','ffbd84'), 'kitchen':('Küche','cup','ffd078'), 'rooms':('Wohnräume','house','c2a6ff'), 'bathroom':('Bad & Wasser','house','89e3ff'),
 'household':('Haushalt','tool','78ebd7'), 'fashion':('Mode & Schmuck','spark','ff99bc'), 'vegetables':('Gemüse','flower','88f184'), 'world_cuisine':('Küche der Welt','cup','ffb68a'),
 'installation':('Elektrik & Installation','chip','76dfff'), 'textiles':('Nähen & Textilien','spark','ff9bbb'), 'pottery':('Ton & Keramik','cup','efb87e'), 'farming':('Landwirtschaft','tree','a9ea74'), 'professions':('Berufe','tool','ffcf7a'),
 'vintage_technology':('Alte Technik','chip','efc385'), 'mathematics':('Mathematik & Formen','spark','bba5ff'), 'biology':('Biologie & Mikroskopie','flower','68ebc4'), 'geology':('Fossilien & Mineralien','mountain','efb87e'), 'research':('Forschung & Labor','flask','8cddff'),
 'anatomy':('Anatomie','paw','ff89ab'), 'senses':('Sinne','spark','89d9ff'), 'medical_care':('Medizinische Geräte & Praxis','flask','75e8d5'), 'dental':('Zahnmedizin','spark','e0f4ff'), 'medical_history':('Geschichte der Medizin','flask','ffcd85'),
 'historic_vehicles':('Historische Fahrzeuge','train','efba7d'), 'antiquity':('Antike','city','ffd078'), 'medieval':('Mittelalter','house','a6bdff'), 'castles':('Burgen & Schlösser','city','e4b486'),
 'archaeology':('Archäologie','mountain','ffca8b'), 'historic_life':('Historischer Alltag','cup','e7bb81'), 'ancient_writing':('Schrift & Zeichen','spark','d3a6ff'), 'cultural_architecture':('Baukunst der Kulturen','city','80dccd'),
 'sculptures':('Skulpturen','palette','d7d5f5'), 'literature':('Berühmte Geschichten','palette','ffa5c6'), 'water_sports':('Wassersport','fish','73dfff'), 'board_games':('Brettspiele & Denksport','spark','ffd078'), 'stage_and_fun':('Bühne & Vergnügen','music','dba0ff'),
}
WORLD_MAP={'intro':'beginning','animals':'nature','plants':'plants','nature':'landscapes','seasons':'celebrations','home':'home','food':'comfort','craft':'craft','tech':'discovery','science':'science','medicine':'medicine','space':'space','travel':'travel','history':'history','culture':'imagination','leisure':'leisure','fantasy':'fantasy'}

def main():
    expansion=read('collections/expansion_catalog.json')['levels']
    recipes={e['key']:e for e in read('collections/expansion_recipes.json')['entries']}
    masks=read('collections/expansion_masks.json')
    researched=read('collections/expansion_discoveries.json')['entries'] if (ROOT/'collections/expansion_discoveries.json').exists() else {}
    key_by_path={f'res://collections/levels/{e["collection"]["id"]}_{int(e["collection"]["order"]):02d}_{e["key"]}.json':e['key'] for e in masks}
    assert len(expansion)==len(recipes)==len(masks) and len(expansion)>=250
    assert all(e['design']['solvable'] for e in expansion)
    catalog=read('collections/catalog.json'); taxonomy=read('collections/taxonomy.json'); journey=read('collections/journey.json'); discoveries=read('collections/discoveries.json')
    categories={c['id']:(w,c) for w in taxonomy['worlds'] for c in w['categories']}
    assignments={a['path']:a for a in taxonomy['assignments'] if a['path'] not in key_by_path}
    assert len(assignments)==509
    registry=journey['groups']
    for gid,(title,icon,color) in NEW_GROUPS.items(): registry[gid]=dict(id=gid,title=title,icon=icon,color=color)
    for entry in expansion:
        item=recipes[key_by_path[entry['path']]]; w,c=categories[item['category']]
        group=MAPPING[w['id']][int(c['id'].rsplit('_',1)[1])-1]
        assignments[entry['path']]=dict(path=entry['path'],title=entry['title'],old_collection=entry['collection']['id'],old_collection_title=entry['collection']['title'],world=w['id'],world_title=w['title'],category=c['title'],category_id=c['id'],group=group,decision='Neues eigenständiges Motiv',existing_tags=entry['tags'],attribution=item['attribution'])
        entry['legacy_collection']=entry['collection'].copy()
        entry['collection']=dict(id=group,title=registry[group]['title'],order=entry['legacy_collection']['order'])
        entry['taxonomy']=dict(world=w['id'],category=c['id'])
        discoveries['entries'][entry['path']]=researched.get(item['key'],dict(kind='Ein kleiner Gedanke',text=item['text']))
    # Keep old indices, including earlier expansion checkpoints, completely stable.
    by_path={e['path']:e for e in catalog['levels'] if e['path'] not in key_by_path}
    by_path.update({e['path']:e for e in expansion})
    old_order=[e['path'] for e in catalog['levels']]
    catalog['levels']=[by_path[p] for p in old_order]+[e for e in expansion if e['path'] not in set(old_order)]
    assert len(catalog['levels'])==500+len(expansion)
    counts=Counter(a['group'] for a in assignments.values())
    for group in list(registry):
        if group not in counts: del registry[group]
        else: registry[group]['count']=counts[group]
    for w in taxonomy['worlds']:
        for c in w['categories']:
            members=[a for a in assignments.values() if a['category_id']==c['id']]
            c['existing_count']=len(members); c['status']='populated' if members else 'prepared'; c['playable_groups']=sorted({a['group'] for a in members})
    worlds={w['id']:w for w in journey['worlds']}
    worlds['discovery']['title']='Technik gestern & heute'
    for wid,title,icon,color,ad_id in [('science','Wissenschaft & Entdeckungen','flask','91d9ff',14),('medicine','Medizin & Mensch','flask','ff9dbc',15),('history','Geschichte & Kulturen','city','efc289',16)]:
        worlds.setdefault(wid,dict(id=wid,title=title,subtitle='Entdecke die Kunstwerke dieser Themenwelt',icon=icon,color=color,ad_id=ad_id,groups=[]))
    canonical_world={a['group']:WORLD_MAP[a['world']] for a in assignments.values()}
    # Existing mixed collections retain their established home.
    for world in journey['worlds']:
        for group in world['groups']:
            if group!='science_basics': canonical_world[group]=world['id']
    canonical_world['science_basics']='science'
    for wid,w in worlds.items():
        prior=[g for g in w['groups'] if canonical_world.get(g)==wid]
        w['groups']=prior+[g for g in registry if canonical_world[g]==wid and g not in prior]
    order=['beginning','nature','plants','landscapes','celebrations','home','comfort','craft','discovery','science','medicine','space','travel','history','imagination','leisure','fantasy']
    journey['worlds']=[worlds[w] for w in order]; journey['version']=4
    taxonomy['assignments']=list(assignments.values()); taxonomy['version']=2
    write('collections/catalog.json',catalog); write('collections/journey.json',journey); write('collections/taxonomy.json',taxonomy); write('collections/discoveries.json',discoveries)
    sources=read('collections/source_masks.json')
    sources=[e for e in sources if e['key'] not in recipes]+masks
    assert len(sources)==500+len(masks)
    write('collections/source_masks.json',sources)
    credits={e['path']:e['attribution'] for e in expansion}
    write('collections/art_credits.json',dict(version=1,notice='Icons made by the credited authors. Adapted into editable, colored neon arrow puzzles.',license_url='https://creativecommons.org/licenses/by/3.0/',entries=credits))
    names={'lorc':'Lorc','delapouite':'Delapouite','caro-asercion':'Caro Asercion','skoll':'Skoll','quoting':'Quoting','faithtoken':'Faithtoken','sbed':'Sbed','cathelineau':'Cathelineau','heavenly-dog':'HeavenlyDog','heavenlydog':'HeavenlyDog'}
    authors=sorted({names.get(a['author'],a['author']) for a in credits.values() if a['author']!='ArrowWay'})
    notice='Icons made by '+', '.join(authors)+'.\n\nQuelle: Game-icons.net / game-icons/icons.\nLizenz: Creative Commons Attribution 3.0 (CC BY 3.0), einzelne Quellen CC0.\n\nDie Vorlagen wurden vereinfacht, eingefärbt und in editierbare, lösbare Neon-Pfeilrätsel umgewandelt. Originalgestaltungen von ArrowWay sind gesondert gekennzeichnet.\n\nDie einzelnen Motivquellen und Lizenzen findest du in der folgenden Liste.'
    write('collections/art_credits.json',dict(version=1,notice=notice,license_url='https://creativecommons.org/licenses/by/3.0/',entries=credits))
    (ROOT/'collections/ART_CREDITS.txt').write_text(notice+'\n',encoding='utf-8')
    lines=['# ArrowWay – neuer Motivbestand','',f'{len(expansion)} neue Motive · {len(assignments)} Motive insgesamt · {len(journey["worlds"])} Themenwelten · {len(registry)} spielbare Sammlungen','', 'Jedes neue Motiv hat einen eigenen Abschlusstext. Die Vorlagen sind unterschiedlich; Umfärbungen zählen nicht als neue Motive. Alle bisherigen Leveldateien und Indizes bleiben erhalten.','']
    for w in journey['worlds']:
        lines += [f'## {w["title"]}', '']+[f'- {registry[g]["title"]}: {counts[g]} Motive' for g in w['groups']]+['']
    lines += ['## Neue Motive nach fachlicher Kategorie','']
    for w in taxonomy['worlds']:
        for c in w['categories']:
            members=[a for a in expansion if a['taxonomy']['category']==c['id']]
            if not members: continue
            lines += [f'### {w["title"]} / {c["title"]}','']+[f'- {e["title"]}' for e in members]+['']
    lines += ['## Bildquellen','',notice,'']
    (ROOT/'planning/MOTIVAUSBAU_AKTUELL.md').write_text('\n'.join(lines),encoding='utf-8')
    print(f'INSTALLED {len(expansion)} new motifs / {len(assignments)} total / {len(registry)} groups; all {len(categories)} canonical categories populated: {all(c["existing_count"] for w,c in categories.values())}')

if __name__=='__main__': main()
