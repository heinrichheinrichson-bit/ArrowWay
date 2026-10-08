extends SceneTree
func _initialize() -> void:
 for item in ["mark", "icon", "adaptive_foreground", "adaptive_background", "adaptive_monochrome"]:
  var image := Image.new()
  var error := image.load_svg_from_string(FileAccess.get_file_as_string("res://branding/"+item+".svg"))
  if error != OK: quit(1); return
  image.save_png("res://branding/"+item+".png")
 quit()
