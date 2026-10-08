extends RefCounted

static var entries: Dictionary={}

static func for_level(game: Node) -> Dictionary:
	if entries.is_empty(): entries=JSON.parse_string(FileAccess.get_file_as_string("res://collections/discoveries.json")).entries
	var path: String=game.level_path(game.level)
	if entries.has(path): return AppLanguage.motif_fields(entries[path],path)
	var group: String=game.level_collection(game.level).id
	var thoughts: Dictionary={
		"winter":AppLanguage.text("Hier bleibt das Licht warm, auch wenn das Motiv nach kalten Fingern aussieht."),
		"halloween":AppLanguage.text("Die Geister dürfen bleiben. Die blockierten Wege hast du bereits vertrieben."),
		"christmas":AppLanguage.text("Ein kleines Kunstwerk, das weder Geschenkpapier noch Batterien braucht."),
		"easter":AppLanguage.text("Heute musstest du keine Eier suchen. Nur ihre freien Wege."),
		"technology":AppLanguage.text("Manchmal ist die beste Verbindung diejenige, die man gerade gelöst hat."),
		"computers":AppLanguage.text("Keine Fehlermeldung. Nur ein fertiges kleines Kunstwerk."),
		"smartphones":AppLanguage.text("Das Handy leuchtet sowieso. Heute hat es dafür einen besonders schönen Grund."),
		"animals":AppLanguage.text("Wenn dieses Tier dir jetzt zunickt: Du hast es dir verdient."),
		"music":AppLanguage.text("Ein Bild kann leise sein und trotzdem seinen eigenen Rhythmus haben."),
		"sports":AppLanguage.text("Hier gewinnt man mit einem guten Blick. Die Laufschuhe dürfen Pause machen."),
		"travel":AppLanguage.text("Eine kleine Reise, für die du keinen Koffer packen musst."),
		"fantasy":AppLanguage.text("Ein wenig Geduld, ein paar freie Wege – und plötzlich wirkt es wie Magie."),
		"art":AppLanguage.text("Welche Farbe würdest du diesem Bild geben, wenn es ein Gefühl wäre?"),
		"ocean":AppLanguage.text("Du hast alle Wege freigemacht. Jetzt darf der Blick ein wenig treiben."),
		"landscapes":AppLanguage.text("Hier gibt es gerade nichts mehr zu lösen. Nur etwas anzusehen.")}
	return {"kind":AppLanguage.text("Ein kleiner Gedanke"),"text":thoughts.get(group,AppLanguage.text("Viele einzelne Wege. Ein gemeinsames Bild. Lass deinen Blick noch einen Moment darin spazieren."))}
