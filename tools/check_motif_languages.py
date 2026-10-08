"""Check published motif translations before exporting; no network access."""
import json
from pathlib import Path
FIELDS={'title':80,'text':600,'kind':600,'source':600}
def read(path, fallback=None):
    return json.loads(path.read_text(encoding='utf-8-sig')) if path.exists() else (fallback or {})
def check_catalog(root):
    root=Path(root)
    messages=read(root/'localization/en.json').get('messages',{})
    scoped=read(root/'localization/motifs.json',{'version':1,'entries':{}})
    if scoped.get('version')!=1 or not isinstance(scoped.get('entries'),dict):
        return [{'path':'','title':'Sprachdaten','issues':['Ungültige Sprachdatei']}]
    discoveries=read(root/'collections/discoveries.json').get('entries',{})
    problems=[]
    for item in read(root/'collections/taxonomy.json').get('assignments',[]):
        path=item['path']; document=read(root/path.removeprefix('res://'))
        discovery=discoveries.get(path,{})
        de={'title':str(document.get('title',item['title'])).strip(),'text':str(discovery.get('text','')).strip(),'kind':str(discovery.get('kind','Ein kleiner Gedanke')).strip(),'source':str(discovery.get('source','')).strip()}
        record=scoped['entries'].get(path,{})
        issues=[]
        for field,limit in FIELDS.items():
            if field=='source' and not de[field]:continue
            if field in record.get('en',{}):
                en=record['en'][field]; reviewed=record.get('reviewed_de',{}).get(field,'')
            else:
                en=messages.get(de[field],'');reviewed=de[field] if en else ''
            if not isinstance(en,str) or not en.strip():issues.append(field+': Englisch fehlt')
            elif len(en)>limit:issues.append(field+': Englisch zu lang')
            elif reviewed!=de[field]:issues.append(field+': Englisch bitte prüfen')
        if issues:problems.append({'path':path,'title':de['title'],'issues':issues})
    return problems
if __name__=='__main__':
    problems=check_catalog(Path(__file__).resolve().parents[1])
    print('Motive mit offenen englischen Texten:',len(problems))
    for item in problems:print(item['title']+': '+'; '.join(item['issues']))
    raise SystemExit(bool(problems))
