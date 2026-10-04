extends SceneTree

# Rebuild the six curated layouts offline. Run with -- --test to isolate progress files.
const RECIPES := [
	[1, 5514, 6, 1800],
	[2, 5163, 8, 2000],
	[0, 4817, 12, 2000],
	[1, 4990, 10, 2000],
	[2, 5682, 4, 2000],
	[0, 5336, 6, 2000]]

func _initialize() -> void:
	call_deferred("build")

func build() -> void:
	DirAccess.make_dir_recursive_absolute("res://levels")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for i in range(RECIPES.size()):
		var recipe: Array = RECIPES[i]
		game.level = i
		game.shape_index = recipe[0]
		game.arrows = LevelDesign.refine(recipe[0], recipe[1], recipe[2], recipe[3])
		var analysis := LevelDesign.metrics(game.arrows)
		if not analysis.solvable:
			push_error("Cannot bake an unsolvable level")
			quit(1)
			return
		var document: Dictionary = game.level_document()
		document["design"] = analysis
		var file := FileAccess.open("res://levels/%02d.json" % (i + 1), FileAccess.WRITE)
		if file == null:
			quit(1)
			return
		file.store_string(JSON.stringify(document, "\t"))
		print("Built %s: %s" % [document.title, analysis])
	quit()
