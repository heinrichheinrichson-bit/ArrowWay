extends Node

var game: Node2D
var states := {}
var active_path := ""
var completed_paths: Array[String] = []
var filename := ""
var fingerprint := ""
var fingerprint_path := ""
var compatible_color_fingerprints: Array[String] = []
var dirty := false
var worker: Thread
var last_error := OK
var retry_delay := 0.0

func enabled() -> bool:
	return game.resume_enabled and game.journey_mode and not game.authoring and not game.editor and not game.testing

func _ready() -> void:
	filename=ProjectSettings.globalize_path(game.storage_prefix+"sessions.json")
	if not enabled(): return
	for path in [filename,filename+".bak"]:
		if not FileAccess.file_exists(path): continue
		var parser:=JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path))!=OK: continue
		var data=parser.data
		if not data is Dictionary or data.get("version")!=1 or not data.get("states") is Dictionary: continue
		var saved_paths=data.get("completed_paths",[])
		if not saved_paths is Array: continue
		states=data.states
		active_path=data.get("active_path","") if data.get("active_path") is String else ""
		for value in saved_paths:
			if value is String: completed_paths.append(value)
		break

func recover_progress() -> void:
	if not enabled(): return
	for path in completed_paths:
		var index: int=game.level_files.find(path)
		if index<0 or JourneyProgress.world_index(game.level_collection(index).id)<0: continue
		if not game.completed.has(index): game.completed.append(index)
		if index<game.base_level_count: game.unlocked=maxi(game.unlocked,mini(index+1,game.base_level_count-1))

func configure() -> void:
	if not enabled(): return
	fingerprint_path=game.level_path(game.level)
	fingerprint=FileAccess.get_sha256(fingerprint_path)
	compatible_color_fingerprints.clear()
	var document=JSON.parse_string(FileAccess.get_file_as_string(fingerprint_path))
	if not document is Dictionary or not document.get("compatible_color_checkpoints") is Array: return
	var paths: Array[String]=[]
	for arrow in game.arrows:
		var points: Array[String]=[]
		for point in arrow.points: points.append("%d,%d" % [int(point.x),int(point.y)])
		paths.append(";".join(points))
	var geometry: String="|".join(paths).sha256_text()
	for predecessor in document.compatible_color_checkpoints:
		if predecessor is Dictionary and predecessor.get("geometry")==geometry and predecessor.get("fingerprint") is String and predecessor.fingerprint.length()==64:
			compatible_color_fingerprints.append(predecessor.fingerprint)

func capture() -> void:
	if not enabled() or not is_instance_valid(game.board_navigation) or game.arrows.is_empty(): return
	var path: String=game.level_path(game.level)
	if path!=fingerprint_path: configure()
	var removed: Array[int]=[]
	var escaping: Array=[]
	for index in game.arrows.size():
		var arrow: Dictionary=game.arrows[index]
		if arrow.removed: removed.append(index)
		elif arrow.escaping: escaping.append([index,arrow.escape_time])
	states[path]={"fingerprint":fingerprint,"count":game.arrows.size(),"removed":removed,"escaping":escaping,"mistakes":game.mistakes,"clock":game.clock_time,"started":game.session_in_progress,"zoom":game.board_navigation.zoom,"center":[game.board_navigation.center.x,game.board_navigation.center.y]}
	active_path=path
	completed_paths.clear()
	for index in game.completed:
		if index>=0 and index<game.level_count(): completed_paths.append(game.level_path(index))
	dirty=true

func has_unfinished(path: String) -> bool:
	if not enabled(): return false
	var data=states.get(path)
	return data is Dictionary and bool(data.get("started",false)) and data.get("removed") is Array and valid_number(data.get("count")) and data.removed.size()<int(data.count)

func restore() -> bool:
	if not enabled(): return false
	configure()
	var data=states.get(fingerprint_path)
	if not data is Dictionary or data.get("count")!=game.arrows.size(): return false
	if data.get("fingerprint")!=fingerprint and not compatible_color_fingerprints.has(str(data.get("fingerprint",""))): return false
	if not data.get("removed") is Array or not data.get("escaping") is Array: return false
	if data.removed.size()+data.escaping.size()>game.arrows.size(): return false
	var used := {}
	for index in data.removed:
		if not valid_index(index) or used.has(int(index)): return false
		used[int(index)]=true
	for entry in data.escaping:
		if not entry is Array or entry.size()!=2 or not valid_index(entry[0]) or used.has(int(entry[0])) or not valid_number(entry[1]) or entry[1]<0: return false
		used[int(entry[0])]=true
	if not valid_number(data.get("clock")) or not valid_number(data.get("mistakes")): return false
	for index in data.removed: game.arrows[int(index)].removed=true
	for entry in data.escaping:
		var arrow: Dictionary=game.arrows[int(entry[0])]
		arrow.escaping=true; arrow.escape_time=minf(float(entry[1]),3600)
		arrow.travel=game.escape_distance(arrow.escape_time)
	game.cleared=data.removed.size()
	game.mistakes=clampi(int(data.mistakes),0,10000000)
	game.clock_time=clampf(float(data.clock),0,31536000)
	game.display_progress=float(game.cleared)/game.arrows.size()
	game.session_in_progress=bool(data.get("started",false))
	if game.cleared==game.arrows.size():
		game.finish_puzzle(true)
	else:
		var point=data.get("center")
		if valid_number(data.get("zoom")) and point is Array and point.size()==2 and valid_number(point[0]) and valid_number(point[1]):
			game.board_navigation.zoom=clampf(float(data.zoom),1.0,4.0)
			game.board_navigation.center=Vector2(float(point[0]),float(point[1]))
			game.board_navigation.apply_view()
	game.known_free.clear()
	for index in game.free_paths(): game.known_free[index]=true
	return true

func valid_index(value: Variant) -> bool:
	return valid_number(value) and float(value)==int(value) and int(value)>=0 and int(value)<game.arrows.size()

func valid_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func payload() -> Dictionary:
	return {"version":1,"active_path":active_path,"completed_paths":completed_paths.duplicate(),"states":states.duplicate(true)}

func _process(delta: float) -> void:
	retry_delay=maxf(0,retry_delay-delta)
	if is_instance_valid(worker) and worker.is_started():
		if worker.is_alive(): return
		last_error=worker.wait_to_finish()
		if last_error!=OK: dirty=true; retry_delay=1.0
	if not dirty or retry_delay>0: return
	dirty=false
	worker=Thread.new()
	last_error=worker.start(write_snapshot.bind(payload(),filename))
	if last_error!=OK: dirty=true; retry_delay=1.0

func flush() -> void:
	if is_instance_valid(worker) and worker.is_started():
		last_error=worker.wait_to_finish()
		if last_error!=OK: dirty=true
	if dirty:
		dirty=false
		last_error=write_snapshot(payload(),filename)
		if last_error!=OK: dirty=true

func _exit_tree() -> void: flush()

static func write_snapshot(data: Dictionary, path: String) -> int:
	var temporary:=path+".tmp"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	var error:=file.get_error()
	file.close()
	if error!=OK: return error
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path+".bak"):
			error=DirAccess.remove_absolute(path+".bak")
			if error!=OK: return error
		error=DirAccess.rename_absolute(path,path+".bak")
		if error!=OK: return error
	return DirAccess.rename_absolute(temporary,path)
