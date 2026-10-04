extends SceneTree

var failures := 0
var scene: Node2D

func require(condition: bool, message: String) -> void:
	if not condition: failures+=1; push_error(message)

func _initialize() -> void: call_deferred("run")

func touch(index: int, position: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index=index; event.position=root.get_final_transform()*position; event.pressed=down
	Input.parse_input_event(event)
	await process_frame

func drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index=index; event.position=root.get_final_transform()*position
	Input.parse_input_event(event)
	await process_frame

func pinch(factor: float, translation := Vector2.ZERO) -> void:
	var mid: Vector2=scene.board_clip.global_position+scene.board_clip.size*0.5
	await touch(0,mid-Vector2(65,0),true)
	await touch(1,mid+Vector2(65,0),true)
	await drag(0,mid-Vector2(65*factor,0)+translation)
	await drag(1,mid+Vector2(65*factor,0)+translation)
	await touch(0,mid-Vector2(65*factor,0)+translation,false)
	await touch(1,mid+Vector2(65*factor,0)+translation,false)

func run() -> void:
	scene=load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_zoom_"
	root.add_child(scene)
	root.size=Vector2i(540,1170)
	await process_frame
	var nav=scene.board_navigation
	var mid: Vector2=scene.board_clip.global_position+scene.board_clip.size*0.5
	var anchor: Vector2=scene.board.get_global_transform().affine_inverse()*mid
	await pinch(2.0)
	require(is_equal_approx(nav.zoom,2.0),"Native two-finger pinch doubles motif scale")
	require((scene.board.get_global_transform()*anchor).distance_to(mid)<1,"Zoom keeps the artwork under the fingers")
	require(not scene.arrows.any(func(a): return a.escaping or a.flash>0),"Pinch launches and blocks no arrows")
	var before: Vector2=scene.board.position
	await touch(0,mid,true); await drag(0,mid+Vector2(65,0)); await touch(0,mid+Vector2(65,0),false)
	require(scene.board.position.x>before.x+40,"One finger pans the enlarged artwork")
	require(not scene.arrows.any(func(a): return a.escaping or a.flash>0),"Panning never becomes a puzzle tap")
	# A pinch that moves its midpoint also pans while zooming.
	nav.reset_view(); await pinch(2.0,Vector2(-45,0))
	require((scene.board.get_global_transform()*anchor).distance_to(mid+Vector2(-45,0))<1,"Two-finger gesture zooms and pans together")
	await pinch(100.0)
	require(is_equal_approx(nav.zoom,4.0),"Zoom is capped at four times fitted size")
	await touch(0,mid,true); await drag(0,mid+Vector2(8000,8000)); await touch(0,mid+Vector2(8000,8000),false)
	var half: Vector2=scene.board_clip.size/(2*nav.fit_scale*nav.zoom)
	for axis in 2:
		if half[axis]*2<nav.bounds.size[axis]:
			require(nav.center[axis]>=nav.bounds.position[axis]+half[axis]-0.01 and nav.center[axis]<=nav.bounds.end[axis]-half[axis]+0.01,"Pan bounds keep motif within reach")
	var original=scene.arrows
	var hit_targets: Array[Dictionary]=[ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(100,200),Vector2(200,200)]),Color.GREEN)]
	scene.arrows=hit_targets
	require(scene.pick(Vector2(150,200+17/scene.board.scale.x))==0 and scene.pick(Vector2(150,200+19/scene.board.scale.x))==-1,"Zoom keeps the expanded hit target at a fixed screen distance")
	scene.arrows=original
	await pinch(0.01)
	require(is_equal_approx(nav.zoom,1.0) and nav.center.is_equal_approx(nav.bounds.get_center()),"Pinching back restores the full centered artwork")
	await touch(0,mid,true); await drag(0,mid+Vector2(30,0)); await touch(0,mid+Vector2(30,0),false)
	require(not scene.arrows.any(func(a): return a.escaping or a.flash>0),"An unzoomed swipe is not an arrow tap")
	# After the pinch, a normal single-finger tap still reaches a scaled arrow.
	await pinch(2.0)
	var chosen: int=ArrowPuzzle.solution(scene.arrows)[0]
	var point: Vector2=scene.board.get_global_transform()*scene.arrows[chosen].points[0]
	# Center the chosen point in view, then use actual native touch plus emulated mouse.
	nav.center=scene.arrows[chosen].points[0]; nav.apply_view()
	point=scene.board.get_global_transform()*scene.arrows[chosen].points[0]
	await touch(0,point,true)
	require(not scene.arrows[chosen].escaping,"Touch-down waits for gesture classification")
	await touch(0,point,false)
	require(scene.arrows[chosen].escaping and scene.arrows.filter(func(a): return a.escaping).size()==1,"One zoomed tap fires precisely one arrow")
	scene.open_home(); await process_frame
	var remembered_zoom: float=nav.zoom
	await touch(0,Vector2(120,150),true); await touch(1,Vector2(180,150),true)
	await drag(0,Vector2(100,150)); await drag(1,Vector2(200,150))
	await touch(0,Vector2(100,150),false); await touch(1,Vector2(200,150),false)
	require(is_equal_approx(nav.zoom,remembered_zoom),"Menu gestures do not affect the board behind it")
	scene.close_home()
	require(is_equal_approx(nav.zoom,remembered_zoom),"Returning to a puzzle retains its zoom")
	scene.reset()
	require(is_equal_approx(nav.zoom,1.0),"Restart restores the fitted view")
	await pinch(2.0)
	for arrow in ArrowPuzzle.solution(scene.arrows):
		scene.click_at(scene.arrows[arrow].points[0]); scene._process(2.0)
	require(scene.win_time>=0 and is_equal_approx(nav.zoom,1.0),"Completion reveals the entire artwork even after zooming")
	if OS.get_cmdline_user_args().has("--capture"):
		scene.reset(); await pinch(2.0,Vector2(-45,0))
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://previews/mobile-zoom.png")
	for name in ["progress.cfg","settings.cfg","library.cfg"]: DirAccess.remove_absolute(scene.storage_prefix+name)
	print("PASS board navigation: native pinch, anchor, pan, bounds, tap isolation, overlays, reset and completion" if failures==0 else "%d FAILURES" % failures)
	quit(0 if failures==0 else 1)
