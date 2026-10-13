extends Node3D
## Main scene bootstrap. Wires player, theater, UI, video, and tablet.

@onready var player: CharacterBody3D = $Player
@onready var theater: Node3D = $Theater
@onready var cinema_manager: Node = $CinemaManager
@onready var video_manager: Node = $VideoManager
@onready var mobile_controls: Control = $UI/MobileControls
@onready var pause_menu: Control = $UI/PauseMenu
@onready var hud: Control = $UI/HUD
@onready var url_panel: Control = $UI/URLEntryPanel
@onready var tablet_ui: Control = $UI/TabletUI
@onready var tablet: Node3D = $Tablet


func _ready() -> void:
	if player:
		player.add_to_group("player")
		player.collision_layer = 2
		player.collision_mask = 1
		if mobile_controls and player.has_method("set_mobile_controls_ref"):
			player.set_mobile_controls_ref(mobile_controls)
		if player.has_signal("video_panel_requested"):
			player.video_panel_requested.connect(_open_url_panel)
		if player.has_signal("tablet_toggle_requested"):
			player.tablet_toggle_requested.connect(_toggle_tablet)

	if mobile_controls:
		if mobile_controls.has_signal("move_input"):
			mobile_controls.move_input.connect(_on_mobile_move)
		if mobile_controls.has_signal("interact_pressed"):
			mobile_controls.interact_pressed.connect(_on_mobile_interact)
		if mobile_controls.has_signal("pause_pressed"):
			mobile_controls.pause_pressed.connect(_on_mobile_pause)
		if mobile_controls.has_signal("lights_pressed"):
			mobile_controls.lights_pressed.connect(_on_mobile_lights)
		if mobile_controls.has_signal("video_pressed"):
			mobile_controls.video_pressed.connect(_open_url_panel)
		if mobile_controls.has_signal("tablet_pressed"):
			mobile_controls.tablet_pressed.connect(_toggle_tablet)

	if pause_menu and pause_menu.has_signal("resume_requested"):
		pause_menu.resume_requested.connect(_on_resume)

	if url_panel:
		if url_panel.has_signal("load_requested"):
			url_panel.load_requested.connect(_on_url_load)
		if url_panel.has_signal("closed"):
			url_panel.closed.connect(_on_url_panel_closed)

	if video_manager:
		if video_manager.has_signal("error_message"):
			video_manager.error_message.connect(_on_video_error)
		if video_manager.has_signal("info_message"):
			video_manager.info_message.connect(_on_video_info)
		if video_manager.has_signal("media_loaded"):
			video_manager.media_loaded.connect(_on_media_loaded)

	if tablet and tablet.has_signal("open_url_panel"):
		tablet.open_url_panel.connect(_open_url_panel)

	if theater and theater.has_method("set_lights_dimmed"):
		theater.set_lights_dimmed(false)

	if hud and hud.has_method("_update_hints"):
		hud._update_hints()


func _on_mobile_move(vec: Vector2) -> void:
	if player and player.has_method("set_mobile_move"):
		player.set_mobile_move(vec)


func _on_mobile_interact() -> void:
	if not player:
		return
	if player.is_sitting:
		player.stand_up()
	else:
		player._try_interact()


func _on_mobile_pause() -> void:
	if cinema_manager and cinema_manager.has_method("toggle_pause"):
		cinema_manager.toggle_pause()


func _on_mobile_lights() -> void:
	if theater and theater.has_method("toggle_lights"):
		theater.toggle_lights()


func _on_resume() -> void:
	if cinema_manager and cinema_manager.has_method("resume"):
		cinema_manager.resume()


func _open_url_panel() -> void:
	if url_panel and url_panel.has_method("open_panel"):
		url_panel.open_panel()
	if player and player.has_method("release_mouse"):
		player.release_mouse()


func _on_url_load(url: String) -> void:
	if video_manager and video_manager.has_method("play_url"):
		video_manager.play_url(url)


func _on_url_panel_closed() -> void:
	if player and not (OS.has_feature("mobile") or OS.get_name() == "Android"):
		# Only recapture if tablet UI is not open
		var tablet_open := tablet and tablet.has_method("is_tablet_visible") and tablet.is_tablet_visible()
		if not tablet_open and player.has_method("_capture_mouse"):
			player._capture_mouse()


func _toggle_tablet() -> void:
	if tablet and tablet.has_method("toggle"):
		tablet.toggle()


func _on_video_error(msg: String) -> void:
	if url_panel and url_panel.has_method("set_status"):
		url_panel.set_status(msg, true)
	if hud and hud.has_method("show_message"):
		hud.show_message("Video error", 2.0)


func _on_video_info(msg: String) -> void:
	if url_panel and url_panel.has_method("set_status"):
		url_panel.set_status(msg, false)
	if hud and hud.has_method("show_message"):
		hud.show_message(msg, 1.5)


func _on_media_loaded(_url: String) -> void:
	if url_panel and url_panel.has_method("set_status"):
		url_panel.set_status("Playing on cinema screen.")
	# Auto-dim lights for cinema feel
	if theater and theater.has_method("set_lights_dimmed"):
		theater.set_lights_dimmed(true)
