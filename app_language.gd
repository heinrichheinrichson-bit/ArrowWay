class_name AppLanguage
extends RefCounted

# Puzzle files, progress keys and workshop documents always keep their authored
# values. Only presentation is translated; the shipped catalogue works offline.
static var selection := "system"
static var locale := "de"
static var messages: Dictionary = {}
static var originals: Dictionary = {}
static var private_workshop := false
static var system_override := ""
static var registered := false

static func resolved_language(choice: String, system: String) -> String:
	if choice in ["de", "en"]: return choice
	return "de" if system.to_lower().replace("-", "_").get_slice("_", 0) == "de" else "en"

static func initialize(prefix: String, workshop := false) -> void:
	ensure_loaded()
	private_workshop = workshop
	var preferences := ConfigFile.new()
	preferences.load(prefix + "settings.cfg")
	selection = str(preferences.get_value("language", "selection", "system"))
	if not selection in ["system", "de", "en"]: selection = "system"
	apply_locale()

static func ensure_loaded() -> void:
	if registered: return
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://localization/en.json"))
	if not data is Dictionary or not data.get("messages") is Dictionary:
		push_error("arrow.joy English translation catalogue is missing.")
		return
	messages = data.messages
	var translation := Translation.new()
	translation.locale = "en"
	for source: String in messages:
		var english: String = messages[source]
		translation.add_message(source, english)
		originals[english] = source
		if not source.contains("%"):
			translation.add_message(source.to_upper(), english.to_upper())
			originals[english.to_upper()] = source.to_upper()
	TranslationServer.add_translation(translation)
	var german := Translation.new()
	german.locale = "de"
	# Godot's default fallback locale is English. Identity messages prevent its
	# automatic Control translation from showing English in the German UI.
	for source: String in messages:
		german.add_message(source, source)
		if not source.contains("%"): german.add_message(source.to_upper(), source.to_upper())
	for source in {"Cancel":"Abbrechen", "Close":"Schließen", "Yes":"Ja", "No":"Nein"}:
		german.add_message(source, {"Cancel":"Abbrechen", "Close":"Schließen", "Yes":"Ja", "No":"Nein"}[source])
	TranslationServer.add_translation(german)
	registered = true

static func apply_locale() -> void:
	var system := system_override if not system_override.is_empty() else OS.get_locale()
	locale = "de" if private_workshop else resolved_language(selection, system)
	TranslationServer.set_locale(locale)

static func choose(choice: String, prefix: String) -> Error:
	if not choice in ["system", "de", "en"]: return ERR_INVALID_PARAMETER
	var preferences := ConfigFile.new()
	preferences.load(prefix + "settings.cfg")
	preferences.set_value("language", "selection", choice)
	var error := preferences.save(prefix + "settings.cfg")
	if error != OK: return error
	selection = choice
	apply_locale()
	return OK

static func refresh_system() -> bool:
	if selection != "system" or private_workshop: return false
	var before := locale
	apply_locale()
	return before != locale

static func text(source: String) -> String:
	if locale != "en" or source.is_empty(): return source
	ensure_loaded()
	return str(messages.get(source, TranslationServer.translate(source)))

static func original(displayed: String) -> String:
	return str(originals.get(displayed, displayed))

static func fields(data: Dictionary) -> Dictionary:
	var localized := data.duplicate(true)
	for field in ["title", "text", "kind", "source", "description", "subtitle"]:
		if localized.get(field) is String: localized[field] = text(localized[field])
	return localized
