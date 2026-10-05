extends RefCounted

static func calculate(safe: Rect2, cutouts: Array, window_position: Vector2, transform: Transform2D, viewport: Rect2) -> Rect2:
	var inverse:=transform.affine_inverse()
	var result:=viewport
	if safe.has_area():
		result=viewport.intersection(Rect2(inverse*(safe.position-window_position),safe.size/transform.get_scale()))
	if not result.has_area(): result=viewport
	for cutout in cutouts:
		var rect:=Rect2(inverse*(Vector2(cutout.position)-window_position),Vector2(cutout.size)/transform.get_scale())
		if rect.intersects(viewport) and rect.position.y<viewport.position.y+viewport.size.y*0.25:
			var bottom:=maxf(result.position.y,rect.end.y)
			result.size.y-=bottom-result.position.y
			result.position.y=bottom
	return result

static func for_game(game: Node) -> Rect2:
	var viewport: Rect2=game.get_viewport_rect()
	if game.safe_area_override.has_area(): return viewport.intersection(game.safe_area_override)
	if not OS.has_feature("mobile"): return viewport
	return calculate(Rect2(DisplayServer.get_display_safe_area()),DisplayServer.get_display_cutouts(),Vector2(DisplayServer.window_get_position()),game.get_viewport().get_final_transform(),viewport)
