extends RefCounted

const INTRO_PUZZLES := 5
const PUZZLE_GAP := 4
const ACTIVE_GAP := 360.0
var completed_paths: Array[String] = []
var rounds_since_ad := 0
var active_since_ad := 0.0
var ad_free := false
var seen_worlds: Array[int] = []
var protected_world := -1

func record_completion(path: String, world: int) -> void:
	if completed_paths.has(path): return
	completed_paths.append(path)
	rounds_since_ad+=1
	if protected_world==world: protected_world=-1

func open_world(world: int) -> void:
	if world<0 or seen_worlds.has(world): return
	seen_worlds.append(world)
	protected_world=world

func tick(delta: float, active: bool) -> void:
	if active: active_since_ad+=clampf(delta,0.0,1.0)

func eligible(normal_transition: bool, world: int) -> bool:
	return normal_transition and not ad_free and completed_paths.size()>INTRO_PUZZLES and rounds_since_ad>=PUZZLE_GAP and active_since_ad>=ACTIVE_GAP and protected_world!=world

func ad_shown() -> void:
	# Nothing is queued: one actual display resets both conditions.
	rounds_since_ad=0
	active_since_ad=0.0

func snapshot() -> Dictionary:
	return {"version":1,"completed_paths":completed_paths,"rounds_since_ad":rounds_since_ad,"active_since_ad":active_since_ad,"ad_free":ad_free,"seen_worlds":seen_worlds,"protected_world":protected_world}

func restore(data: Dictionary) -> void:
	completed_paths.clear(); seen_worlds.clear()
	for path in data.get("completed_paths",[]):
		if path is String and not completed_paths.has(path): completed_paths.append(path)
	for world in data.get("seen_worlds",[]):
		if world is int and world>=0 and not seen_worlds.has(world): seen_worlds.append(world)
	rounds_since_ad=maxi(0,int(data.get("rounds_since_ad",0)))
	active_since_ad=maxf(0.0,float(data.get("active_since_ad",0.0)))
	ad_free=bool(data.get("ad_free",false))
	protected_world=int(data.get("protected_world",-1))
