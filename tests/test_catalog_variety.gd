extends SceneTree
var failed:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
 if not ok:failed+=1;push_error(message)
func run()->void:
 var recipes=JSON.parse_string(FileAccess.get_file_as_string("res://collections/variety_recipes.json")).entries
 var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
 var taxonomy=JSON.parse_string(FileAccess.get_file_as_string("res://collections/taxonomy.json"))
 var discovery=JSON.parse_string(FileAccess.get_file_as_string("res://collections/discoveries.json")).entries
 var language=JSON.parse_string(FileAccess.get_file_as_string("res://localization/motifs.json")).entries
 var game=load("res://main.tscn").instantiate();game.storage_prefix="user://test_variety_";game.scan_user_exports=true;root.add_child(game)
 game.journey_mode=false
 var geometry:={}
 for item in recipes:
  var document=JSON.parse_string(FileAccess.get_file_as_string(item.path))
  var motif:=CustomMotif.decode(document.motif)
  var paths:=CustomMotif.decode_paths(document.paths,motif)
  check(not paths.is_empty(),"Valid solvable geometry: "+item.title)
  var signature:String=JSON.stringify(motif.cells.keys()).sha256_text()
  check(not geometry.has(signature),"Revised scenes have different silhouettes: "+item.title)
  geometry[signature]=true
  check(document.title==item.title and discovery[item.path]==item.discovery,"Names and closing texts match artwork")
  check(language[item.path].reviewed_de.title==document.title and language[item.path].reviewed_de.text==discovery[item.path].text,"Both languages reviewed against current artwork")
  var used:={}
  for arrow in paths:
   for point in arrow.points:
    var cell:=ArrowPuzzle.grid(point)
    check(not used.has(cell),"No overlapping arrow cells");used[cell]=true
  check(used.size()==motif.cells.size(),"Complete arrow coverage")
  var index:int=game.level_files.find(item.path)
  check(index>=0,"Puzzle is reachable in player catalog")
  game.start_journey_puzzle(index)
  for arrow in ArrowPuzzle.solution(game.arrows):
   check(not game.is_blocked(arrow),"Runtime accepts solution")
   game.click_at(game.arrows[arrow].points[0]);game._process(2.0)
  check(game.cleared==paths.size() and game.mistakes==0,"Actual game completes: "+item.title)
 var counts:={}
 for entry in taxonomy.assignments:counts[entry.group]=int(counts.get(entry.group,0))+1
 var groups=JSON.parse_string(FileAccess.get_file_as_string("res://collections/journey.json")).groups
 for id in groups:check(int(groups[id].count)==counts.get(id,0),"Journey counts stay consistent")
 game.queue_free();await process_frame
 if failed==0:print("PASS 69 distinct scenes: full coverage, actual gameplay, bilingual texts and catalog counts")
 quit(1 if failed else 0)
