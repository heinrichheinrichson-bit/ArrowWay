class_name JourneyProgress
extends RefCounted

static var definition: Dictionary = {}
static var owner_id := 0
static var revision := -1
static var completed_hash := -1
static var group_indices := {}
static var group_counts := {}
static var legacy_groups: Array[String] = []
static var cached_frontier := -1

static func refresh(game: Node) -> void:
	if owner_id != game.get_instance_id() or revision != game.journey_index_revision:
		owner_id = game.get_instance_id(); revision = game.journey_index_revision
		group_indices.clear(); completed_hash = -1
		for index in game.level_count():
			var group: String = game.level_collection(index).id
			if not group_indices.has(group):
				var ordered: Array[int] = []
				group_indices[group] = ordered
			group_indices[group].append(index)
	var fingerprint: int = hash([game.completed,game.journey_legacy_paths])
	if completed_hash == fingerprint: return
	completed_hash = fingerprint; cached_frontier = -1
	group_counts.clear(); legacy_groups.clear()
	for index in game.completed:
		if index >= game.level_count(): continue
		var group: String = game.level_collection(index).id
		group_counts[group] = int(group_counts.get(group,0))+1
	for path in game.journey_legacy_paths:
		var index: int = game.level_files.find(path)
		if index >= 0: legacy_groups.append(game.level_collection(index).id)

static func worlds() -> Array:
	if definition.is_empty(): definition = JSON.parse_string(FileAccess.get_file_as_string("res://collections/journey.json"))
	return definition.worlds

static func indices(game: Node, group: String) -> Array[int]:
	refresh(game)
	var empty: Array[int] = []
	return group_indices.get(group,empty)

static func group_done(game: Node, group: String) -> int:
	refresh(game)
	return int(group_counts.get(group,0))

static func world_index(group: String) -> int:
	for index in worlds().size():
		if worlds()[index].groups.has(group): return index
	return -1

static func world_done(game: Node, index: int) -> int:
	refresh(game)
	var result := 0
	for group in worlds()[index].groups: result += int(group_counts.get(group,0))
	return result

static func world_total(game: Node, index: int) -> int:
	var total := 0
	for group in worlds()[index].groups: total += indices(game, group).size()
	return total

static func world_complete(game: Node, index: int) -> bool:
	var total := world_total(game, index)
	return total > 0 and world_done(game, index) == total

static func group_complete(game: Node, group: String) -> bool:
	var total := indices(game, group).size()
	return total > 0 and group_done(game, group) == total

static func frontier(game: Node) -> int:
	refresh(game)
	if cached_frontier >= 0: return cached_frontier
	var result := 0
	while result + 1 < worlds().size() and world_complete(game, result): result += 1
	cached_frontier = result
	return result

static func group_visible(game: Node, group: String) -> bool:
	if group == "custom": return true
	var world := world_index(group)
	return world >= 0 and world <= frontier(game)

static func level_open(game: Node, index: int) -> bool:
	if index < 0 or index >= game.level_count(): return false
	# Retain old individual achievements without unlocking unfinished themes.
	if game.completed.has(index): return true
	if game.journey_legacy_paths.has(game.level_path(index)): return true
	return group_visible(game, game.level_collection(index).id)

static func next_open(game: Node, index: int) -> int:
	var group: String = game.level_collection(index).id
	for candidate in indices(game, group):
		if candidate > index and level_open(game, candidate) and not game.completed.has(candidate): return candidate
	for candidate in indices(game, group):
		if level_open(game, candidate) and not game.completed.has(candidate): return candidate
	return -1

static func group_title(game: Node, group: String) -> String:
	if group == "base": return "Einstieg"
	if group == "custom": return "Deine eigenen Motive"
	var found := indices(game, group)
	return game.level_collection(found[0]).title if not found.is_empty() else group

static func group_icon(group: String) -> String:
	var icons := {"base":"spark","garden":"tree","animals":"paw","birds":"bird","flowers":"flower","ocean":"fish","landscapes":"mountain","winter":"snow","christmas":"tree","halloween":"moon","easter":"flower","space":"planet","cosmos":"planet","technology":"chip","computers":"chip","smartphones":"phone","workshop":"chip","world":"city","skylines":"city","vehicles":"car","travel":"mountain","taste":"cup","bakery":"cup","fruit":"flower","cozy":"cup","art":"palette","music":"music","sports":"ball","toys":"spark","fantasy":"moon","custom":"spark"}
	return icons.get(group, "spark")
