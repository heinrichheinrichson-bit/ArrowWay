extends SceneTree
const DEST="res://../../work/catalog-variety/baked/"
func _initialize()->void:call_deferred("run")
func run()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DEST))
 var recipes=JSON.parse_string(FileAccess.get_file_as_string("res://collections/variety_recipes.json")).entries
 var failures:=0
 var results:Array=[]
 for i in range(recipes.size()):
  var item:Dictionary=recipes[i]
  var output:String=DEST+item.path.get_file()
  if FileAccess.file_exists(output) and not OS.get_cmdline_user_args().has("--rebuild"):
   var cached=JSON.parse_string(FileAccess.get_file_as_string(output))
   if cached.get("source_hash","")==JSON.stringify(item).sha256_text():continue
  var motif:=CustomMotif.decode(item.motif)
  var original_size:int=motif.cells.size()
  for clean in range(12):
   var probe:=MotifBuilder.build(6,641981+i*173,motif)
   var used:={}
   for arrow in probe:
    for point in arrow.points:used[ArrowPuzzle.grid(point)]=true
   if used.size()==motif.cells.size():break
   for cell:Vector2i in motif.cells.keys():
    if used.has(cell):continue
    var neighbors:Array[int]=[]
    var exposed:=false
    for direction in ArrowPuzzle.DIRECTIONS:
     var neighbor:Vector2i=cell+direction
     if not motif.cells.has(neighbor):exposed=true
     elif motif.cells[neighbor]!=motif.cells[cell]:neighbors.append(motif.cells[neighbor])
    if not neighbors.is_empty():motif.cells[cell]=neighbors[0]
    elif exposed:motif.cells.erase(cell)
  if motif.cells.size()<original_size*.92 or not CustomMotif.isolated(motif).is_empty():
   push_error("Contour loss or isolated cells: "+item.title);failures+=1;continue
  motif.styles={}
  for part in motif.palettes:
   var colors:=MotifColors.shades(Color(motif.palettes[part][0]),.30)
   motif.palettes[part]=colors
   motif.styles[part]={"mode":3,"colors":colors,"strength":.30,"bounds":MotifColors.bounds_for(motif,part)}
  var paths:Array[Dictionary]=[]
  for attempt in range(8):
   paths=LevelDesign.refine(6,641981+i*173+attempt*3109,8,100,motif)
   if not paths.is_empty():break
  if paths.is_empty():push_error("No fill: "+item.title);failures+=1;continue
  MotifColors.apply(motif,paths)
  var document:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(item.path)) if FileAccess.file_exists(item.path) else {}
  document.merge({"version":2,"shape":6,"title":item.title,"motif":CustomMotif.encode(motif),"paths":CustomMotif.encode_paths(paths),"design":LevelDesign.metrics(paths),"source_hash":JSON.stringify(item).sha256_text(),"source_cells":original_size,"art_revision":"catalog-variety-1"},true)
  # This is new artwork; previous per-arrow overrides and inherited source licenses do not apply.
  document.erase("attribution");document.erase("compatible_color_checkpoints")
  var file:=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(document,"\t"));file.close()
  results.append({"path":output,"title":item.title})
  print("BUILT %d/%d %s: %d cells, %d arrows" % [i+1,recipes.size(),item.title,motif.cells.size(),paths.size()])
 print("VARIETY FAILURES: ",failures)
 quit(1 if failures else 0)
