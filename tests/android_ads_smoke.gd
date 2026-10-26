extends Node
# Included only by --release --test-ads --ads-smoke, in a separate package.
var notice: Label
var opened := false
func show_notice(message: String) -> void:
	if not is_instance_valid(notice):
		var layer=CanvasLayer.new(); layer.layer=100; add_child(layer)
		var panel=PanelContainer.new()
		panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		panel.offset_left=14; panel.offset_right=-14; panel.offset_top=30
		layer.add_child(panel)
		notice=Label.new(); notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		notice.add_theme_font_size_override("font_size",18)
		panel.add_child(notice)
	notice.text="AdMob · TEST ADS\n"+message
func _ready() -> void:
	show_notice("Google-Testanzeige wird geladen. / Loading a Google demo ad.")
	await get_tree().create_timer(3).timeout
	var config=JSON.parse_string(FileAccess.get_file_as_string("res://admob_runtime.json"))
	if not config is Dictionary or not config.get("test_ads",false):
		push_error("ADS SMOKE refused: not a demo-ad build"); return
	if not Engine.has_singleton("ArrowJoyAds"):
		show_notice("SDK fehlt. / Native SDK missing.")
		push_error("ADS SMOKE: native plugin missing"); return
	var native=Engine.get_singleton("ArrowJoyAds")
	native.connect("ad_opened",func(_token): opened=true)
	var game=get_tree().current_scene
	for step in range(120):
		if native.call("isReady"):
			print("ADS SMOKE: Google demo interstitial ready; exercising real controller")
			game.ads.policy.completed_paths.assign(["smoke1","smoke2","smoke3","smoke4","smoke5","smoke6"])
			game.ads.policy.active_since_ad=360
			game.ads.policy.rounds_since_ad=4
			game.ads.policy.protected_world=-1
			game.ads.transition(1,func():
				show_notice("Testanzeige geschlossen – Spiel geht weiter. / Demo ad closed – game resumed." if opened else "Keine Anzeige verfügbar. / No demo ad available.")
				print("ADS SMOKE: continuation completed"))
			return
		await get_tree().create_timer(1).timeout
	push_error("ADS SMOKE: no demo ad available within 120s")
	show_notice("Keine Google-Testanzeige empfangen. App neu starten und Verbindung prüfen. / No Google demo ad received. Restart the app and check connectivity.")
