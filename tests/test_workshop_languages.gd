extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
 if not ok: failures+=1; push_error(message)
func _initialize()->void: call_deferred("run")
func run()->void:
 var helper=load("res://workshop_language_service.gd").new()
 check(helper.catalog_issues().is_empty(),"Existing catalog translations load")
 var german={"title":"Sonne","text":"Ein neuer Gedanke.","kind":"Ein kleiner Gedanke","source":""}
 var record=helper.load_record("res://test.json",german)
 record.en={"title":"Sun","text":"A new thought.","kind":"A little thought","source":""}; record.reviewed_de=german.duplicate()
 check(helper.issues(record,german).is_empty(),"Reviewed bilingual record is ready")
 german.title="Neue Sonne"
 check(helper.issues(record,german).size()==1 and record.en.title=="Sun","German change flags English without deleting it")
 record.reviewed_de=german.duplicate()
 var scene=load("res://main.tscn").instantiate(); root.add_child(scene)
 scene.enter_editor(); scene.open_studio()
 var studio=scene.studio
 studio.english=record.en.duplicate(); studio.reviewed_german=record.reviewed_de.duplicate()
 studio.title_field.text=german.title; studio.completion_text.text=german.text
 studio.completion_kind.text=german.kind
 studio.open_text_editor(); await process_frame; await process_frame
 var editor=studio.text_editor
 check(editor.editors["en:title"].text=="Sun","English editor loads existing text")
 editor.change("de","title","Andere Sonne")
 check(studio.english.title=="Sun" and not studio.language_issues().is_empty(),"Editor marks outdated translation")
 editor.change("en","title","Another Sun")
 check(studio.reviewed_german.title=="Andere Sonne","English edit acknowledges current original")
 var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
 var path:String=str(catalog.levels[0].path).trim_prefix("res://")
 var base:="user://bilingual_workshop_test/"
 for file_name in [path,"collections/catalog.json","collections/taxonomy.json","collections/discoveries.json","localization/en.json"]:
  DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path((base+file_name).get_base_dir()))
  var file=FileAccess.open(base+file_name,FileAccess.WRITE); file.store_string(FileAccess.get_file_as_string("res://"+file_name)); file.close()
 DirAccess.remove_absolute(ProjectSettings.globalize_path(base+"localization/motifs.json"))
 studio.catalog_root=base; studio.bind_catalog(path)
 var before=JSON.parse_string(FileAccess.get_file_as_string(base+path))
 studio.open_text_editor(); editor.refresh()
 editor.change("en","title","Workshop translated title")
 studio.save_catalog()
 var after=JSON.parse_string(FileAccess.get_file_as_string(base+path))
 var saved=JSON.parse_string(FileAccess.get_file_as_string(base+"localization/motifs.json"))
 check(saved.entries["res://"+path].en.title=="Workshop translated title","English saves against stable motif path")
 check(after.title==before.title and after.paths==before.paths,"English edits preserve German title and arrow geometry")
 studio.bind_catalog(path)
 check(studio.english.title=="Workshop translated title","Saved English reloads")
 editor.refresh(); editor.change("de","title","Changed German title")
 studio.save_catalog(); studio.bind_catalog(path)
 check(not studio.language_issues().is_empty() and studio.english.title=="Workshop translated title","Review flag survives saving and reopening")
 studio.mark_english_reviewed()
 check(studio.language_issues().is_empty(),"Explicit review resolves stale translation")
 studio.english.title="Another Sun"
 var state=studio.workshop_state()
 check(state.english.title=="Another Sun","Draft preserves English")
 if OS.get_cmdline_user_args().has("--capture"):
  editor.preview(); await process_frame
  await create_timer(0.4).timeout
  editor.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../Werkstatt-Sprachen.png"))
 editor.queue_free(); studio.catalog_path=""; scene.queue_free(); await process_frame
 if failures==0: print("PASS bilingual workshop, review flags, draft and preview")
 quit(1 if failures else 0)
