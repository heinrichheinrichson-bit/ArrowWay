extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var store=load("res://catalog_workshop_store.gd").new()
 var state:Dictionary=store.load_state()
 var expected:Dictionary=store.fingerprints()
 var updates:={}
 var language:Dictionary=store.read("localization/motifs.json",{"version":1,"entries":{}})
 var credits:Dictionary=store.read("collections/art_credits.json")
 var recipes=JSON.parse_string(FileAccess.get_file_as_string("res://collections/variety_recipes.json")).entries
 for item in recipes:
  var path:String=item.path.trim_prefix("res://")
  var public_path:String=item.path
  expected[path]=FileAccess.get_sha256(item.path) if FileAccess.file_exists(item.path) else ""
  var baked:String="res://../../work/catalog-variety/baked/"+path.get_file()
  if not FileAccess.file_exists(baked):push_error("Missing baked motif: "+item.title);quit(1);return
  var doc:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(baked))
  var motif:=CustomMotif.decode(doc.motif)
  var paths:=CustomMotif.decode_paths(doc.paths,motif)
  if paths.is_empty() or not LevelDesign.metrics(paths).solvable:push_error("Invalid motif: "+item.title);quit(1);return
  var occupied:={}
  for arrow in paths:
   for point in arrow.points:
    var cell:=ArrowPuzzle.grid(point)
    if occupied.has(cell):push_error("Overlap: "+item.title);quit(1);return
    occupied[cell]=true
  if occupied.size()!=motif.cells.size():push_error("Incomplete motif: "+item.title);quit(1);return
  var assignment:Dictionary={}
  for current in state.taxonomy.assignments:
   if current.path==public_path:assignment=current;break
  if assignment.is_empty():
   for current in state.taxonomy.assignments:
    if current.category_id==item.category:assignment=current.duplicate(true);break
   if assignment.is_empty():push_error("Missing category: "+item.title);quit(1);return
   assignment.path=public_path;assignment.title=item.title;assignment.decision="Eigenständiges neues Motiv"
   var collection:={"id":assignment.group,"title":state.journey.groups[assignment.group].title,"order":state.catalog.levels.size()+1}
   doc.collection=collection;doc.tags=[assignment.category]
   state.catalog.levels.append({"path":public_path,"title":item.title,"collection":collection,"design":doc.design,"tags":doc.tags,"taxonomy":{"world":assignment.world,"category":assignment.category}})
   state.taxonomy.assignments.append(assignment);state.manifest.catalog_order.append(public_path)
  assignment.title=item.title;assignment.erase("attribution")
  for entry in state.catalog.levels:
   if entry.path==public_path:
    entry.title=item.title;entry.design=doc.design;entry.erase("attribution")
    doc.collection=entry.collection.duplicate(true)
    if not doc.has("tags"):doc.tags=entry.get("tags",[]).duplicate()
  doc.erase("color_design")
  updates[path]=doc
  state.discoveries.entries[public_path]=item.discovery
  var german:={"title":item.title,"text":item.discovery.text,"kind":item.discovery.kind,"source":""}
  language.entries[public_path]={"de":german,"en":{"title":item.english_title,"text":item.english_discovery.text,"kind":item.english_discovery.kind,"source":""},"reviewed_de":german.duplicate()}
  credits.get("entries",{}).erase(public_path)
  var protection:Dictionary=state.overrides.entries.get(path,{})
  protection.merge({"protected":true,"title":item.title,"discovery":item.discovery,"art_revision":"catalog-variety-1"},true)
  state.overrides.entries[path]=protection
 store.recount(state)
 updates.merge(store.state_updates(state),true)
 updates["localization/motifs.json"]=language;updates["collections/art_credits.json"]=credits
 if not OS.get_cmdline_user_args().has("--publish"):
  print("VALIDATED ",recipes.size()," scenes; publish explicitly with --publish");quit();return
 if not store.commit(updates,expected):push_error(store.error);quit(1);return
 print("PUBLISHED ",recipes.size()," scenes, ",state.taxonomy.assignments.size()," active motifs. Existing paths and positions retained.")
 quit()
