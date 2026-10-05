extends RefCounted

static var entries: Dictionary={}

static func for_level(game: Node) -> Dictionary:
	if entries.is_empty(): entries=JSON.parse_string(FileAccess.get_file_as_string("res://collections/discoveries.json")).entries
	var path: String=game.level_path(game.level)
	if entries.has(path): return entries[path].duplicate(true)
	var group: String=game.level_collection(game.level).id
	var thoughts: Dictionary={
		"winter":"Hier bleibt das Licht warm, auch wenn das Motiv nach kalten Fingern aussieht.",
		"halloween":"Die Geister dürfen bleiben. Die blockierten Wege hast du bereits vertrieben.",
		"christmas":"Ein kleines Kunstwerk, das weder Geschenkpapier noch Batterien braucht.",
		"easter":"Heute musstest du keine Eier suchen. Nur ihre freien Wege.",
		"technology":"Manchmal ist die beste Verbindung diejenige, die man gerade gelöst hat.",
		"computers":"Keine Fehlermeldung. Nur ein fertiges kleines Kunstwerk.",
		"smartphones":"Das Handy leuchtet sowieso. Heute hat es dafür einen besonders schönen Grund.",
		"animals":"Wenn dieses Tier dir jetzt zunickt: Du hast es dir verdient.",
		"music":"Ein Bild kann leise sein und trotzdem seinen eigenen Rhythmus haben.",
		"sports":"Hier gewinnt man mit einem guten Blick. Die Laufschuhe dürfen Pause machen.",
		"travel":"Eine kleine Reise, für die du keinen Koffer packen musst.",
		"fantasy":"Ein wenig Geduld, ein paar freie Wege – und plötzlich wirkt es wie Magie.",
		"art":"Welche Farbe würdest du diesem Bild geben, wenn es ein Gefühl wäre?",
		"ocean":"Du hast alle Wege freigemacht. Jetzt darf der Blick ein wenig treiben.",
		"landscapes":"Hier gibt es gerade nichts mehr zu lösen. Nur etwas anzusehen."}
	return {"kind":"Ein kleiner Gedanke","text":thoughts.get(group,"Viele einzelne Wege. Ein gemeinsames Bild. Lass deinen Blick noch einen Moment darin spazieren.")}
