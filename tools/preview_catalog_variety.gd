extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var groups:={}
 var taxonomy=JSON.parse_string(FileAccess.get_file_as_string("res://collections/taxonomy.json"))
 var assignments:={}
 var titles:={}
 for world in taxonomy.worlds:
  for category in world.categories:titles[category.id]=category.title
 for item in taxonomy.assignments:assignments[item.path]=item
 var recipes=JSON.parse_string(FileAccess.get_file_as_string("res://collections/variety_recipes.json")).entries
 for item in recipes:
  var category:String=assignments.get(item.path,{}).get("category_id",item.category)
  if not groups.has(category):groups[category]=[]
  groups[category].append(item)
 var rounder:=Node2D.new();rounder.set_script(load("res://main.gd"))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../Katalog-Variationen"))
 for category in groups:
  var entries:Array=groups[category]
  for page in range(ceili(entries.size()/9.0)):
   var viewport:=SubViewport.new();viewport.size=Vector2i(1500,1840);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
   var background:=ColorRect.new();background.color=Color("#071020");background.size=viewport.size;viewport.add_child(background)
   var heading:=Label.new();heading.text="arrow.joy · "+str(titles.get(category,category))+" · "+str(page+1);heading.position=Vector2(25,10);heading.add_theme_font_size_override("font_size",26);viewport.add_child(heading)
   for index in range(mini(9,entries.size()-page*9)):
    var item:Dictionary=entries[page*9+index]
    var data=JSON.parse_string(FileAccess.get_file_as_string("res://../../work/catalog-variety/baked/"+item.path.get_file()))
    var preview:=Node2D.new();preview.set_script(load("res://motif_preview.gd"));preview.rounder=rounder;preview.motif=CustomMotif.decode(data.motif);preview.arrows=CustomMotif.decode_paths(data.paths,preview.motif)
    preview.scale=Vector2.ONE*.87;preview.position=Vector2(index%3*500+15,index/3*590-70);viewport.add_child(preview)
    var title:=Label.new();title.text=item.title;title.position=Vector2(index%3*500+12,index/3*590+570);title.size.x=476;title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",20);viewport.add_child(title)
   for frame in range(6):await process_frame
   await RenderingServer.frame_post_draw
   viewport.get_texture().get_image().save_png("res://../Katalog-Variationen/"+category+"-"+str(page+1)+".png");viewport.queue_free();print("PREVIEW ",category," ",page+1)
 rounder.free();quit()
