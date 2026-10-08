extends SceneTree
const Backup := preload("res://app_state_backup.gd")
const PREFIX := "user://test_app_state_"
var failures := 0
var game: Node2D
func check(ok: bool, reason: String) -> void:
 if not ok: failures+=1; push_error(reason)
func _initialize() -> void: call_deferred("run")
func erase() -> void:
 for name in Backup.FILES+["before-restore.json","restore-journal.json","export.json","invalid.json"]:
  for suffix in ["",".incoming",".tmp"]: DirAccess.remove_absolute(PREFIX+name+suffix)
func spawn() -> Node2D:
 var scene: Node2D=load("res://main.tscn").instantiate()
 scene.storage_prefix=PREFIX; scene.journey_mode=true; scene.resume_enabled=true; scene.scan_user_exports=true
 root.add_child(scene); scene.set_process(false)
 return scene
func capture(name: String) -> void:
 var args:=OS.get_cmdline_user_args(); var index:=args.find("--capture-dir")
 if index<0: return
 await process_frame; await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(args[index+1].path_join("backup-"+name+".png"))
func run() -> void:
 erase(); AppLanguage.system_override="de_AT"
 game=spawn(); await process_frame
 game.open_home(); game.home_menu.navigate("settings"); await process_frame
 check(game.home_menu.get_node_or_null("AppStateButton")!=null,"Settings opens the App-state page")
 await capture("settings-de")
 game.home_menu.navigate("backup"); await process_frame
 check(game.home_menu.get_node_or_null("ExportAppState")!=null,"App-state page exposes export")
 check(game.home_menu.get_node_or_null("ImportAppState")!=null,"App-state page exposes restore")
 for child in game.home_menu.get_children():
  if child is Label and child.autowrap_mode != TextServer.AUTOWRAP_OFF:
   check(child.position.x+child.size.x <= game.home_menu.size.x-20,"Description stays within screen width")
 await capture("page-de")
 if DisplayServer.get_name()=="headless":
  game.app_state_backup.choose_file(true)
  var picker:FileDialog=game.app_state_backup.dialog
  check(picker.use_native_dialog and picker.access==FileDialog.ACCESS_FILESYSTEM,"Mobile picker uses native external storage access")
  check(picker.file_mode==FileDialog.FILE_MODE_SAVE_FILE and picker.current_file.ends_with(".json"),"Export uses a dated JSON save dialog")
  picker.canceled.emit(); await process_frame
  check(not game.app_state_backup.busy,"Canceling export releases the picker")
 game.set_language("en"); await process_frame
 check(game.home_menu.screen=="backup","Language changes preserve the backup page")
 await capture("page-en")
 game.feedback.set_enabled(false)
 game.completed.assign([1]); game.unlocked=1
 game.favorite_paths.assign([game.level_path(1)])
 game.arrows[0].removed=true; game.cleared=1; game.session_in_progress=true
 game.clock_time=83.5; game.mistakes=3
 game.board_navigation.zoom=1.8; game.board_navigation.center+=Vector2(24,18); game.board_navigation.apply_view()
 var saved_center:Vector2=game.board_navigation.center
 game.ads.policy.rounds_since_ad=7; game.ads.policy.active_since_ad=447.5
 game.ads.policy.seen_worlds.assign([1,4]); game.ads.policy.protected_world=4
 game.ads.test_mode=true; game.ads.simulate_ad_free=true
 var stats:=ConfigFile.new(); stats.load(PREFIX+"progress.cfg")
 stats.set_value("statistics","total_play_time",1234.5); stats.save(PREFIX+"progress.cfg")
 var saved:Dictionary=game.app_state_backup.export_to(PREFIX+"export.json")
 check(saved.has("ok"),"A complete export succeeds")
 var result:=Backup.read_document(PREFIX+"export.json")
 check(result.has("data"),"Export can be read and passes checksums and structural validation")
 if not result.has("data"): push_error(str(result)); quit(1); return
 var original: Dictionary=result.data
 var summary:=Backup.summary(original)
 check(summary.completed==1 and summary.favorites==1 and summary.started==1,"Preview summarizes actual saved state")
 for kind in ["format","version","hash","missing","traversal","config","session"]:
  var bad:=original.duplicate(true)
  match kind:
   "format": bad.format="another.app"
   "version": bad.version=99
   "hash": bad.files['settings.cfg'].text+='broken'
   "missing": bad.files.erase('sessions.json')
   "traversal": bad.files['../other.cfg']=bad.files['settings.cfg']
   "config":
    bad.files['settings.cfg'].text='[language]\nselection=42\n'
    bad.files['settings.cfg'].sha256=bad.files['settings.cfg'].text.sha256_text()
   "session":
    var states:Dictionary=JSON.parse_string(bad.files['sessions.json'].text)
    states.states.values()[0].removed=[0,0]
    bad.files['sessions.json'].text=JSON.stringify(states)
    bad.files['sessions.json'].sha256=bad.files['sessions.json'].text.sha256_text()
  var before_hash:=FileAccess.get_sha256(PREFIX+"progress.cfg")
  check(game.app_state_backup.restore(bad).has("error"),"Reject malformed import: "+kind)
  check(FileAccess.get_sha256(PREFIX+"progress.cfg")==before_hash,"Rejected import changes no progress: "+kind)
 game.app_state_backup.inspect_file(PREFIX+"export.json")
 check(game.get_node_or_null("AppStateRestoreConfirmation")!=null,"Import requires a concrete preview and explicit confirmation")
 var confirm:ConfirmationDialog=game.get_node("AppStateRestoreConfirmation")
 check(confirm.dialog_text.contains("Solved puzzles: 1"),"English restore preview is localized")
 await capture("confirm-en")
 confirm.canceled.emit(); await process_frame
 game.completed.clear(); game.favorite_paths.clear(); game.feedback.set_enabled(true); game.set_language("de")
 game.session_store.states.clear(); game.reset(); game.session_in_progress=false
 game.clock_time=0; game.mistakes=0
 game.ads.policy.rounds_since_ad=0; game.ads.policy.active_since_ad=0
 game.ads.policy.seen_worlds.clear(); game.ads.test_mode=false; game.ads.simulate_ad_free=false
 check(game.app_state_backup.snapshot().has("data"),"Changed state is saved")
 var previous:Dictionary=Backup.snapshot_files(PREFIX)
 check(game.app_state_backup.restore(original).has("ok"),"Complete restore succeeds")
 check(Backup.read_document(PREFIX+"before-restore.json").has("data"),"Previous state is automatically saved")
 var safety:Dictionary=Backup.read_document(PREFIX+"before-restore.json").data
 check(Backup.summary(safety).completed==0,"Safety backup preserves state before import")
 for name in original.files:
  check(FileAccess.get_file_as_string(PREFIX+name)==original.files[name].text,"Restore exact persistent bytes: "+name)
 game.reload_app_state(); await process_frame; await process_frame
 game=root.get_child(root.get_child_count()-1)
 check(AppLanguage.selection=="en" and not game.feedback.enabled,"Restored language and sound take effect immediately")
 check(game.completed==[1] and game.favorite_paths==[game.level_path(1)],"Restored completion and favorites take effect")
 var restored_stats:=ConfigFile.new(); restored_stats.load(PREFIX+"progress.cfg")
 check(restored_stats.get_value("statistics","total_play_time")==1234.5,"Additional persistent statistics are preserved without filtering")
 check(game.arrows[0].removed and game.cleared==1 and game.mistakes==3 and is_equal_approx(game.clock_time,83.5),"Unfinished puzzle state survives reload")
 check(is_equal_approx(game.board_navigation.zoom,1.8) and game.board_navigation.center.distance_to(saved_center)<0.01,"Puzzle zoom and pan survive restore")
 check(game.ads.policy.rounds_since_ad==7 and is_equal_approx(game.ads.policy.active_since_ad,447.5),"Ad counters survive restore")
 check(game.ads.policy.seen_worlds==[1,4] and game.ads.policy.protected_world==4,"Stable world protection survives JSON persistence")
 check(game.ads.test_mode and game.ads.simulate_ad_free,"Saved ad test preferences restored")
 check(game.home_menu.get_node_or_null("UndoAppStateImport")!=null,"Previous state is accessible from backup page")
 await capture("restored-en")
 var undo_data:Dictionary=Backup.read_document(PREFIX+"before-restore.json").data
 check(game.app_state_backup.restore(undo_data).has("ok"),"Automatic pre-import backup can be restored")
 game.reload_app_state(); await process_frame; await process_frame
 game=root.get_child(root.get_child_count()-1)
 check(game.completed.is_empty() and game.favorite_paths.is_empty() and game.feedback.enabled and AppLanguage.selection=="de","Undo restores the previous complete app state")
 check(game.cleared==0 and game.ads.policy.rounds_since_ad==0,"Undo restores puzzle state and ad counters")
 check(game.app_state_backup.restore(original).has("ok"),"The same external backup can be imported again")
 game.reload_app_state(); await process_frame; await process_frame
 game=root.get_child(root.get_child_count()-1)
 # Recover an interrupted import before any startup writer gets to run.
 game.queue_session(); game.session_store.flush(); game.ads.initialized=false
 game.session_store.dirty=false; game.queue_free(); await process_frame
 var rollback:Dictionary=Backup.snapshot_files(PREFIX)
 Backup.write_text(PREFIX+"restore-journal.json",JSON.stringify(rollback))
 Backup.write_text(PREFIX+"settings.cfg",previous.files['settings.cfg'].text)
 game=spawn(); await process_frame
 check(AppLanguage.selection=="en","Startup recovers settings after an interrupted multi-file import")
 check(not FileAccess.file_exists(PREFIX+"restore-journal.json"),"Recovery journal removed only after successful rollback")
 # A failed safety backup must leave all application files untouched.
 DirAccess.remove_absolute(PREFIX+"before-restore.json")
 DirAccess.make_dir_absolute(PREFIX+"before-restore.json")
 var protected_hash:=FileAccess.get_sha256(PREFIX+"settings.cfg")
 check(game.app_state_backup.restore(previous).has("error"),"Abort if safety backup cannot be created")
 check(FileAccess.get_sha256(PREFIX+"settings.cfg")==protected_hash,"No application state changed after safety backup failure")
 DirAccess.remove_absolute(PREFIX+"before-restore.json")
 game.queue_session(); game.session_store.flush(); game.ads.initialized=false; game.session_store.dirty=false
 game.queue_free(); await process_frame
 erase(); AppLanguage.system_override=""
 print("PASS complete app-state export, validation, preview/cancel, import, reload, automatic backup and interrupted-restore recovery" if failures==0 else str(failures)+" FAILURES")
 quit(1 if failures else 0)
