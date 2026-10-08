extends RefCounted
const FILE := "localization/motifs.json"
const FIELDS := ["title","text","kind","source"]
const LABELS := {"title":"Name","text":"Abschlusstext","kind":"Textart","source":"Quellenname"}
var root := "res://"
var messages := {}
var records := {}
var records_loaded := false
func read(path: String) -> Dictionary:
 if not FileAccess.file_exists(root+path): return {}
 var data=JSON.parse_string(FileAccess.get_file_as_string(root+path))
 return data if data is Dictionary else {}
func original_fields(title: String, discovery: Dictionary) -> Dictionary:
 return {"title":title.strip_edges(),"text":str(discovery.get("text","")).strip_edges(),"kind":str(discovery.get("kind","Ein kleiner Gedanke")).strip_edges(),"source":str(discovery.get("source","")).strip_edges()}
func load_record(path: String, german: Dictionary) -> Dictionary:
 if not records_loaded:
  records=read(FILE).get("entries",{}); records_loaded=true
 var saved:Dictionary=records.get("res://"+path.trim_prefix("res://"),{})
 if messages.is_empty():
  messages=read("localization/en.json").get("messages",{})
  if messages.is_empty(): messages=JSON.parse_string(FileAccess.get_file_as_string("res://localization/en.json")).messages
 var result:Dictionary={"de":german.duplicate(),"en":{},"reviewed_de":{}}
 for field in FIELDS:
  if saved.get("en",{}).has(field):
   result.en[field]=str(saved.en[field])
   result.reviewed_de[field]=str(saved.get("reviewed_de",{}).get(field,""))
  else:
   result.en[field]=str(messages.get(german[field],"")) if not str(german[field]).is_empty() else ""
   result.reviewed_de[field]=german[field] if not result.en[field].is_empty() else ""
 return result
func issues(record: Dictionary, german: Dictionary) -> Array[Dictionary]:
 var result:Array[Dictionary]=[]
 for field in FIELDS:
  if field=="source" and str(german.get(field,"")).is_empty(): continue
  var english:String=str(record.get("en",{}).get(field,"")).strip_edges()
  if english.is_empty(): result.append({"field":field,"message":LABELS[field]+": Englisch fehlt"}); continue
  if english.length()>(80 if field=="title" else 600): result.append({"field":field,"message":LABELS[field]+": Englisch ist zu lang"}); continue
  if record.get("reviewed_de",{}).get(field,"") != german.get(field,""): result.append({"field":field,"message":LABELS[field]+": Englisch bitte prüfen"})
 return result
func with_record(path: String, record: Dictionary) -> Dictionary:
 var data:=read(FILE)
 if not data.get("entries") is Dictionary: data={"version":1,"entries":{}}
 data.entries["res://"+path.trim_prefix("res://")]=record.duplicate(true)
 return data
func catalog_issues() -> Array[Dictionary]:
 var result:Array[Dictionary]=[]
 var state:=read("collections/taxonomy.json")
 var discoveries:Dictionary=read("collections/discoveries.json").get("entries",{})
 for item in state.get("assignments",[]):
  var path:String=item.path
  var document:=read(path.trim_prefix("res://"))
  var german:=original_fields(str(document.get("title",item.title)),discoveries.get(path,{}))
  var record:=load_record(path,german)
  var problems:=issues(record,german)
  if not problems.is_empty(): result.append({"path":path,"title":german.title,"issues":problems})
 return result
