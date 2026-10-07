"""Exercise author overrides against real generators, exclusively in a disposable copy."""
import argparse, json, shutil, subprocess, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--godot',required=True); args=parser.parse_args()
    scratch=ROOT.parent.parent/'work';scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='workshop-generator-test-',dir=scratch) as folder:
        stage=Path(folder)/'project'
        shutil.copytree(ROOT,stage,ignore=shutil.ignore_patterns('.git','.godot','work','builds','examples','previews','*.apk','__pycache__'))
        (stage/'.godot').mkdir(); shutil.copy2(ROOT/'.godot/global_script_class_cache.cfg',stage/'.godot/global_script_class_cache.cfg')
        def read(path):return json.loads((stage/path).read_text(encoding='utf-8-sig'))
        def write(path,data):(stage/path).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
        source=read('collections/source_masks.json')[:2]
        paths=[f"collections/levels/{i['collection']['id']}_{int(i['collection']['order']):02d}_{i['key']}.json" for i in source]
        removed,moved=paths
        doc=read(moved);doc['title']='Geschütztes Werkstattmotiv';doc['motif']['title']=doc['title']
        write(moved,doc);(stage/removed).unlink()
        catalog=read('collections/catalog.json');taxonomy=read('collections/taxonomy.json'); discoveries=read('collections/discoveries.json')
        assignment=next(i.copy() for i in taxonomy['assignments'] if i['path']=='res://'+moved)
        assignment.update(world='science',world_title='Wissenschaft',category='Mathematik',category_id='science_01',group='science_basics',title=doc['title'])
        collection={'id':'science_basics','title':'Wissenschaft & Entdeckungen','order':999};doc['collection']=collection;write(moved,doc)
        discovery={'kind':'Ein kleiner Gedanke','text':'Dieser manuelle Text darf nicht überschrieben werden.'}
        new='collections/levels/workshop_test_created.json';write(new,doc)
        new_assignment=dict(assignment,path='res://'+new)
        catalog['levels'].append(dict(path='res://'+new,title=doc['title'],collection=collection,design=doc['design'],tags=[]))
        taxonomy['assignments'].append(new_assignment);write('collections/catalog.json',catalog);write('collections/taxonomy.json',taxonomy)
        protected={removed:{'protected':True,'deleted':True},moved:{'protected':True,'title':doc['title'],'discovery':discovery,'assignment':assignment,'collection':collection},new:{'protected':True,'title':doc['title'],'discovery':discovery,'assignment':new_assignment,'collection':collection}}
        write('collections/editor_overrides.json',{'version':1,'entries':protected})
        import sys
        subprocess.run([sys.executable,'tools/install_expansion.py'],cwd=stage,check=True,capture_output=True,text=True)
        assert all(e['path']!='res://'+removed for e in read('collections/catalog.json')['levels'])
        assert next(e for e in read('collections/catalog.json')['levels'] if e['path']=='res://'+moved)['collection']['id']=='science_basics'
        assert read('collections/discoveries.json')['entries']['res://'+moved]==discovery
        assert any(e['path']=='res://'+new for e in read('collections/catalog.json')['levels'])
        original=read(moved)
        subprocess.run([sys.executable,'tools/color_expansion.py'],cwd=stage,check=True,capture_output=True,text=True)
        assert read(moved)==original and not (stage/removed).exists()
        shutil.copy2(stage/'collections/catalog.json',stage/'collections/generator_test_catalog.json')
        result=subprocess.run([args.godot,'--headless','--path',str(stage),'--script','tools/generate_collections.gd','--','--test','--rebuild','--limit','2','--output','res://collections/generator_test_catalog.json'],check=True,capture_output=True,text=True,timeout=90)
        generated=read('collections/generator_test_catalog.json')['levels']
        assert all(e['path']!='res://'+removed for e in generated)
        assert any(e['path']=='res://'+new for e in generated)
        assert next(e for e in generated if e['path']=='res://'+moved)['title']==doc['title']
        assert read(moved)==original
        print('PASS real installer, color generator and forced geometry rebuild preserve deleted, moved, edited and newly created workshop motifs')
if __name__=='__main__':main()
