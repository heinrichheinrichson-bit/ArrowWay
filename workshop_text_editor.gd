extends Window
var studio: Window
var editors := {}
var status: Label
var counter_de: Label
var counter_en: Label
var synchronizing := false
var save_feedback: Label
func label(parent: Node,text: String,size := 15) -> Label:
 var item:=Label.new(); item.text=text; item.add_theme_font_size_override("font_size",size)
 item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; parent.add_child(item); return item
func button(parent: Node,text: String,callback: Callable) -> Button:
 var item:=Button.new(); item.text=text; item.custom_minimum_size.y=42
 item.pressed.connect(callback); parent.add_child(item); return item
func _ready() -> void:
 title="Name & Abschlusstext · Deutsch und Englisch"
 transient=true; exclusive=true
 name="WorkshopTextEditor"
 auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
 size=Vector2i(1060,760); min_size=Vector2i(900,700)
 theme=studio.game.panel.theme
 var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
 add_child(margin)
 var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",12); margin.add_child(box)
 label(box,"Ein Motiv. Zwei Sprachfassungen.",25)
 label(box,"Farben und Pfeile gelten für beide Sprachen. Hier bearbeitest du die Namen und Texte.",15)
 status=label(box,"",15); status.custom_minimum_size.y=42
 var scroll:=ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; box.add_child(scroll)
 var columns:=HBoxContainer.new(); columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 columns.add_theme_constant_override("separation",24); scroll.add_child(columns)
 for language in ["de","en"]:
  var column:=VBoxContainer.new(); column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  column.size_flags_stretch_ratio=1; column.add_theme_constant_override("separation",8); columns.add_child(column)
  label(column,"DEUTSCH · Original" if language=="de" else "ENGLISH · Übersetzung",18)
  label(column,"Motivname",14)
  var title_field:=LineEdit.new(); title_field.max_length=80; title_field.custom_minimum_size.y=40
  title_field.name="TitleDE" if language=="de" else "TitleEN"
  title_field.placeholder_text="Name des Motivs" if language=="de" else "English puzzle name"
  column.add_child(title_field); editors[language+":title"]=title_field
  title_field.text_changed.connect(func(value:String): change(language,"title",value))
  label(column,"Abschlusstext",14)
  var text:=TextEdit.new(); text.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY; text.custom_minimum_size.y=242
  text.name="CompletionDE" if language=="de" else "CompletionEN"
  text.placeholder_text="Ein Gedanke, ein interessanter Fakt oder ein passendes Zitat …" if language=="de" else "A thought, an interesting fact or a fitting quote …"
  column.add_child(text); editors[language+":text"]=text
  text.text_changed.connect(func(): change(language,"text",text.text))
  var counter:=label(column,"",13)
  if language=="de": counter_de=counter
  else: counter_en=counter
  var details:=VBoxContainer.new(); details.visible=false
  var toggle:=CheckButton.new(); toggle.text="Textart & Quellenname"; column.add_child(toggle)
  toggle.toggled.connect(func(value:bool): details.visible=value)
  column.add_child(details)
  for field in ["kind","source"]:
   label(details,"Textart" if field=="kind" else "Angezeigter Quellenname",13)
   var input:=LineEdit.new(); input.custom_minimum_size.y=38
   input.text=""; details.add_child(input); editors[language+":"+field]=input
   input.text_changed.connect(func(value:String): change(language,field,value))
 var footer:=HBoxContainer.new(); footer.add_theme_constant_override("separation",10); box.add_child(footer)
 button(footer,"Vorschau beider Sprachen",preview)
 button(footer,"Englisch geprüft",func(): studio.mark_english_reviewed(); refresh())
 var spacer:=Control.new(); spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL; footer.add_child(spacer)
 button(footer,"Beide Sprachen speichern",func():
  if studio.catalog_path.is_empty(): studio.save_draft()
  else: studio.save_catalog()
  refresh()
  save_feedback.text=studio.notice.text
  save_feedback.modulate=Color("#8ff0c3") if studio.catalog_path.is_empty() or studio.catalog_state()==studio.catalog_baseline else Color("#ffd17c"))
 button(footer,"Fertig",queue_free)
 save_feedback=label(box,"",14)
 label(box,"Fertig schließt nur dieses Fenster. Nicht gespeicherte Änderungen bleiben im Entwurf.",13)
 close_requested.connect(queue_free)
 refresh()
func change(language: String,field: String,value: String) -> void:
 if synchronizing: return
 if language=="de":
  var control:Control=studio.german_control(field)
  control.text=value
  if field=="title": studio.motif.title=value
 else:
  studio.english[field]=value
  studio.reviewed_german[field]=studio.german_fields()[field] if not value.strip_edges().is_empty() else ""
 update_status()
 studio.refresh_language_status()
func refresh() -> void:
 synchronizing=true
 var german:Dictionary=studio.german_fields()
 for field in ["title","text","kind","source"]:
  editors["de:"+field].text=german[field]
  editors["en:"+field].text=studio.english.get(field,"")
 synchronizing=false
 update_status()
func update_status() -> void:
 var problems:Array=studio.language_issues()
 status.text="Deutsch und Englisch sind bereit. Speichern übernimmt beide Fassungen gemeinsam." if problems.is_empty() else " · ".join(problems.map(func(item):return item.message))
 status.modulate=Color("#8ff0c3") if problems.is_empty() else Color("#ffd17c")
 counter_de.text="%d / 600 Zeichen" % studio.completion_text.text.length()
 counter_en.text="%d / 600 Zeichen" % str(studio.english.get("text","")).length()
 counter_en.modulate=Color("#ff9999") if str(studio.english.get("text","")).length()>600 else Color("#a8b8ca")
func preview() -> void:
 var window:=Window.new(); window.title="Abschlussbild · Deutsch und Englisch"; window.size=Vector2i(1040,780)
 window.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED; window.theme=theme; add_child(window)
 var margin:=MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
 window.add_child(margin)
 var scroll:=ScrollContainer.new(); margin.add_child(scroll)
 var columns:=HBoxContainer.new(); columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL; columns.add_theme_constant_override("separation",24); scroll.add_child(columns)
 for language in ["de","en"]:
  var data:Dictionary=studio.german_fields() if language=="de" else studio.english
  var column:=VBoxContainer.new(); column.size_flags_horizontal=Control.SIZE_EXPAND_FILL; columns.add_child(column)
  label(column,"Deutsch" if language=="de" else "English",16)
  var card:=Button.new(); card.set_script(load("res://level_card.gd"))
  card.custom_minimum_size=Vector2(460,290); card.paths=studio.paths; card.title=str(data.get("title","")); card.mouse_filter=Control.MOUSE_FILTER_IGNORE
  column.add_child(card)
  label(column,str(data.get("kind","")),14)
  label(column,str(data.get("text","")),18)
  if not str(data.get("source","")).is_empty(): label(column,str(data.source),13)
 window.close_requested.connect(window.queue_free); window.popup_centered()
