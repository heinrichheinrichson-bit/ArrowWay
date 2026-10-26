extends Node
# Included only by --release --test-ads --ads-smoke, in a separate package.
func _ready() -> void:
	await get_tree().create_timer(3).timeout
	var config=JSON.parse_string(FileAccess.get_file_as_string("res://admob_runtime.json"))
	if not config is Dictionary or not config.get("test_ads",false):
		push_error("ADS SMOKE refused: not a demo-ad build"); return
	if not Engine.has_singleton("ArrowJoyAds"):
		push_error("ADS SMOKE: native plugin missing"); return
	var native=Engine.get_singleton("ArrowJoyAds")
	var game=get_tree().current_scene
	for step in range(120):
		if native.call("isReady"):
			print("ADS SMOKE: Google demo interstitial ready; exercising real controller")
			game.ads.policy.completed_paths.assign(["smoke1","smoke2","smoke3","smoke4","smoke5","smoke6"])
			game.ads.policy.active_since_ad=360
			game.ads.policy.rounds_since_ad=4
			game.ads.policy.protected_world=-1
			game.ads.transition(1,func(): print("ADS SMOKE: continuation completed"))
			return
		await get_tree().create_timer(1).timeout
	push_error("ADS SMOKE: no demo ad available within 120s")
