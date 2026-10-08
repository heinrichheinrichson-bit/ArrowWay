extends Node

const FORMAT := "arrow.joy.app-state"
const VERSION := 1
const MAX_BYTES := 16 * 1024 * 1024
const FILES: Array[String] = ["settings.cfg", "progress.cfg", "library.cfg", "sessions.json", "sessions.json.bak", "ads.json", "ads.json.bak"]
var game: Node2D
var busy := false
var dialog: FileDialog

static func write_text(path: String, text: String) -> int:
 var file := FileAccess.open(path, FileAccess.WRITE)
 if file == null: return FileAccess.get_open_error()
 file.store_string(text); file.flush()
 var error := file.get_error()
 file.close()
 return error

static func replace_text(path: String, text: String) -> int:
 var error := write_text(path+".incoming", text)
 if error != OK: return error
 if FileAccess.file_exists(path):
  error = DirAccess.remove_absolute(path)
  if error != OK: return error
 return DirAccess.rename_absolute(path+".incoming", path)

static func read_document(path: String) -> Dictionary:
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null: return {"error":AppLanguage.text("Die Datei konnte nicht geöffnet werden.")}
 if file.get_length() > MAX_BYTES: return {"error":AppLanguage.text("Die Sicherungsdatei ist zu groß.")}
 var parser := JSON.new()
 if parser.parse(file.get_as_text()) != OK: return {"error":AppLanguage.text("Die Datei enthält keine gültige Sicherung.")}
 return validate(parser.data)

static func number(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and value >= 0

static func strings(value: Variant) -> bool:
 if not (value is Array or value is PackedStringArray): return false
 for item in value:
  if not item is String: return false
 return true

static func valid_config(name: String, text: String) -> bool:
 var config := ConfigFile.new()
 if config.parse(text) != OK: return false
 if name == "settings.cfg":
  return config.get_value("language","selection","system") in ["system","de","en"] and config.get_value("audio","enabled",true) is bool
 if name == "library.cfg": return strings(config.get_value("library","favorites",[]))
 if not strings(config.get_value("game","completed_paths",[])): return false
 for key in ["journey_seen","journey_access_groups","journey_legacy_paths","completed_custom"]:
  if not strings(config.get_value("game",key,[])): return false
 for key in ["unlocked","level","journey_version"]:
  if not number(config.get_value("game",key,0)): return false
 if not config.get_value("game","custom_level","") is String: return false
 var completed = config.get_value("game","completed",[])
 if not (completed is Array or completed is PackedInt32Array): return false
 for value in completed:
  if not number(value) or float(value) != int(value): return false
 return config.get_value("game","journey_migrated",true) is bool

static func valid_json(name: String, text: String) -> bool:
 var parser := JSON.new()
 if parser.parse(text) != OK or not parser.data is Dictionary: return false
 var data: Dictionary = parser.data
 if data.get("version") != 1 or not strings(data.get("completed_paths",[])): return false
 if name.begins_with("ads"):
  if not data.get("seen_worlds",[]) is Array: return false
  for value in data.get("seen_worlds",[]):
   if not number(value): return false
  for key in ["rounds_since_ad","active_since_ad"]:
   if not number(data.get(key,0)): return false
  return data.get("ad_free",false) is bool and data.get("test_mode",false) is bool and data.get("simulate_ad_free",false) is bool and (data.get("protected_world",-1) is int or data.get("protected_world",-1) is float)
 if not data.get("active_path","") is String or not data.get("states") is Dictionary: return false
 for path in data.states:
  var state = data.states[path]
  if not path is String or not state is Dictionary: return false
  if not state.get("fingerprint") is String or not number(state.get("count")) or state.count > 100000: return false
  if not state.get("removed") is Array or not state.get("escaping") is Array: return false
  var used := {}
  for index in state.removed:
   if not number(index) or float(index) != int(index) or index >= state.count or used.has(int(index)): return false
   used[int(index)] = true
  for item in state.escaping:
   if not item is Array or item.size() != 2 or not number(item[0]) or float(item[0]) != int(item[0]) or item[0] >= state.count or used.has(int(item[0])) or not number(item[1]): return false
   used[int(item[0])] = true
  for key in ["clock","mistakes","zoom"]:
   if not number(state.get(key)): return false
  if not state.get("started") is bool: return false
  var center = state.get("center")
  if not center is Array or center.size()!=2: return false
  for value in center:
   if not (value is int or value is float) or not is_finite(float(value)): return false
 return true

static func validate(data: Variant) -> Dictionary:
 var invalid := {"error":AppLanguage.text("Die Sicherung ist beschädigt oder unvollständig.")}
 if not data is Dictionary or data.get("format") != FORMAT: return {"error":AppLanguage.text("Diese Datei ist keine arrow.joy-Sicherung.")}
 if data.get("version") != VERSION: return {"error":AppLanguage.text("Diese Sicherung benötigt eine andere App-Version.")}
 if not data.get("created_utc") is String or not data.get("app_version") is String or not data.get("files") is Dictionary: return invalid
 var total := 0
 for name in data.files:
  if not name in FILES: return invalid
  var record = data.files[name]
  if not record is Dictionary or not record.get("text") is String or not record.get("sha256") is String: return invalid
  total += record.text.to_utf8_buffer().size()
  if total > MAX_BYTES or record.text.sha256_text() != record.sha256: return invalid
  if name.ends_with(".cfg"):
   if not valid_config(name,record.text): return invalid
  elif not valid_json(name,record.text): return invalid
 if JSON.stringify(data).to_utf8_buffer().size() > MAX_BYTES: return {"error":AppLanguage.text("Die Sicherungsdatei ist zu groß.")}
 for required in ["settings.cfg","progress.cfg","library.cfg","sessions.json","ads.json"]:
  if not data.files.has(required): return invalid
 return {"data":data}

static func snapshot_files(prefix: String) -> Dictionary:
 var files := {}
 for name in FILES:
  var path := prefix+name
  if FileAccess.file_exists(path):
   var text := FileAccess.get_file_as_string(path)
   files[name] = {"text":text,"sha256":text.sha256_text()}
 return {"format":FORMAT,"version":VERSION,"created_utc":Time.get_datetime_string_from_system(true),"app_version":str(ProjectSettings.get_setting("application/config/version")),"files":files}

func snapshot() -> Dictionary:
 game.queue_session(); game.session_store.flush()
 if game.session_store.last_error != OK: return {"error":AppLanguage.text("Der aktuelle App-Stand konnte nicht gespeichert werden.")}
 if game.save_progress() != OK or game.ads.save() != OK:
  return {"error":AppLanguage.text("Der aktuelle App-Stand konnte nicht gespeichert werden.")}
 var settings := ConfigFile.new(); settings.load(game.storage_prefix+"settings.cfg")
 settings.set_value("audio","enabled",game.feedback.enabled)
 settings.set_value("language","selection",AppLanguage.selection)
 if settings.save(game.storage_prefix+"settings.cfg") != OK: return {"error":AppLanguage.text("Der aktuelle App-Stand konnte nicht gespeichert werden.")}
 var library := ConfigFile.new(); library.load(game.storage_prefix+"library.cfg")
 library.set_value("library","favorites",game.favorite_paths)
 if library.save(game.storage_prefix+"library.cfg") != OK: return {"error":AppLanguage.text("Der aktuelle App-Stand konnte nicht gespeichert werden.")}
 return validate(snapshot_files(game.storage_prefix))

static func summary(data: Dictionary) -> Dictionary:
 var progress := ConfigFile.new(); progress.parse(data.files['progress.cfg'].text)
 var library := ConfigFile.new(); library.parse(data.files['library.cfg'].text)
 var sessions: Dictionary = JSON.parse_string(data.files['sessions.json'].text)
 var started := 0
 for state in sessions.states.values():
  if state.started and state.removed.size() < state.count: started += 1
 return {"completed":progress.get_value("game","completed_paths",[]).size(),"favorites":library.get_value("library","favorites",[]).size(),"started":started,"date":data.created_utc.replace("T"," ")+" UTC"}

static func apply_files(prefix: String, files: Dictionary) -> int:
 for name in FILES:
  var path := prefix+name
  if files.has(name):
   var error := replace_text(path,files[name].text)
   if error != OK: return error
  elif FileAccess.file_exists(path):
   var error := DirAccess.remove_absolute(path)
   if error != OK: return error
 return OK

static func recover(prefix: String) -> int:
 var path := prefix+"restore-journal.json"
 if not FileAccess.file_exists(path): return OK
 var result := read_document(path)
 if result.has("error"): return ERR_FILE_CORRUPT
 var error := apply_files(prefix,result.data.files)
 if error != OK: return error
 return DirAccess.remove_absolute(path)

func restore(data: Dictionary) -> Dictionary:
 var checked := validate(data)
 if checked.has("error"): return checked
 var before := snapshot()
 if before.has("error"): return before
 var prefix: String = game.storage_prefix
 var encoded := JSON.stringify(before.data)
 var error := replace_text(prefix+"before-restore.json",encoded)
 if error != OK: return {"error":AppLanguage.text("Die automatische Sicherung konnte nicht erstellt werden. Es wurde nichts geändert.")}
 error = replace_text(prefix+"restore-journal.json",encoded)
 if error != OK: return {"error":AppLanguage.text("Die Wiederherstellung konnte nicht vorbereitet werden. Es wurde nichts geändert.")}
 error = apply_files(prefix,data.files)
 if error == OK: error = DirAccess.remove_absolute(prefix+"restore-journal.json")
 if error != OK:
  var rollback := recover(prefix)
  return {"error":AppLanguage.text("Die Wiederherstellung ist fehlgeschlagen. Der vorherige Stand bleibt gesichert.") if rollback != OK else AppLanguage.text("Die Wiederherstellung ist fehlgeschlagen. Dein bisheriger Stand wurde wiederhergestellt.")}
 # Old in-memory writers must not overwrite imported files during scene disposal.
 game.session_store.dirty = false
 game.app_state_reloading = true
 game.ads.initialized = false
 return {"ok":true}

func export_to(path: String) -> Dictionary:
 var result := snapshot()
 if result.has("error"): return result
 var encoded := JSON.stringify(result.data,"\t")
 if encoded.to_utf8_buffer().size() > MAX_BYTES: return {"error":AppLanguage.text("Die Sicherungsdatei ist zu groß.")}
 if write_text(path,encoded) != OK: return {"error":AppLanguage.text("Die Sicherung konnte dort nicht gespeichert werden.")}
 return {"ok":true}

func style_dialog(window: AcceptDialog) -> void:
 var theme: Theme = game.panel.theme.duplicate()
 theme.default_font_size = 17
 var panel := StyleBoxFlat.new()
 panel.bg_color = Color("#101a2e")
 panel.border_color = Color("#34455c")
 panel.set_border_width_all(1); panel.set_corner_radius_all(14)
 panel.set_content_margin_all(18)
 theme.set_stylebox("panel","AcceptDialog",panel)
 var border: StyleBoxFlat = ThemeDB.get_default_theme().get_stylebox("embedded_border","Window").duplicate()
 border.bg_color = Color("#101a2e")
 border.border_color = Color("#34455c")
 border.set_border_width_all(1); border.set_corner_radius_all(14)
 theme.set_stylebox("embedded_border","Window",border)
 window.theme = theme
 window.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 window.get_label().custom_minimum_size.x = 280

func message(text: String) -> void:
 var notice := AcceptDialog.new()
 notice.exclusive = true
 notice.title = AppLanguage.text("App-Stand")
 notice.dialog_text = text
 notice.ok_button_text = AppLanguage.text("Schließen")
 game.add_child(notice)
 style_dialog(notice)
 notice.confirmed.connect(notice.queue_free); notice.canceled.connect(notice.queue_free)
 notice.popup_centered(Vector2i(mini(430,game.get_window().size.x-40),240))

func choose_file(exporting: bool) -> void:
 if busy or game.authoring: return
 busy = true
 dialog = FileDialog.new()
 dialog.name = "AppStateFileDialog"
 dialog.access = FileDialog.ACCESS_FILESYSTEM
 dialog.use_native_dialog = true
 dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if exporting else FileDialog.FILE_MODE_OPEN_FILE
 dialog.title = AppLanguage.text("App-Stand sichern") if exporting else AppLanguage.text("App-Stand wiederherstellen")
 dialog.add_filter("*.json",AppLanguage.text("arrow.joy-Sicherung"),"application/json")
 if exporting: dialog.current_file = "arrow.joy-App-Stand-"+Time.get_datetime_string_from_system().replace(":","-")+".json"
 if OS.get_name() != "Android": dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
 game.add_child(dialog)
 dialog.canceled.connect(func(): busy=false; dialog.queue_free())
 dialog.file_selected.connect(func(path: String):
  busy=false; dialog.queue_free()
  if exporting:
   var result := export_to(path)
   message(result.get("error",AppLanguage.text("Dein vollständiger App-Stand wurde gesichert.")))
  else: inspect_file.call_deferred(path))
 dialog.popup_centered(Vector2i(mini(760,game.get_window().size.x-40),mini(620,game.get_window().size.y-80)))

func inspect_file(path: String) -> void:
 if busy: return
 var result := read_document(path)
 if result.has("error"): message(result.error); return
 busy=true
 var info := summary(result.data)
 var confirm := ConfirmationDialog.new()
 confirm.exclusive = true
 confirm.name = "AppStateRestoreConfirmation"
 confirm.title = AppLanguage.text("App-Stand wiederherstellen?")
 confirm.ok_button_text = AppLanguage.text("Wiederherstellen")
 confirm.cancel_button_text = AppLanguage.text("Abbrechen")
 confirm.dialog_text = AppLanguage.text("Sicherung vom %s\n\nGelöste Rätsel: %d\nLieblingsbilder: %d\nAngefangene Rätsel: %d\n\nDieser Stand ersetzt deinen aktuellen App-Stand. Zuvor wird er automatisch gesichert.") % [info.date,info.completed,info.favorites,info.started]
 game.add_child(confirm)
 style_dialog(confirm)
 confirm.canceled.connect(func(): busy=false; confirm.queue_free())
 confirm.confirmed.connect(func():
  busy=false
  var applied := restore(result.data)
  confirm.queue_free()
  if applied.has("error"): message(applied.error)
  else: game.reload_app_state.call_deferred())
 confirm.popup_centered(Vector2i(mini(440,game.get_window().size.x-40),350))
