extends Node3D
## Main scene bootstrap. Wires player, theater, UI and manager.

@onready var player: CharacterBody3D = $Player
@onready var theater: Node3D = $Theater
@onready var cinema_manager: Node = $CinemaManager
@onready var mobile_controls: Control = $UI/MobileControls
@onready var pause_menu: Control = $UI/PauseMenu
@onready var hud: Control = $UI/HUD


func _ready() -> void:
	# Ensure player is in group for seat proximity
	if player:
		player.add_to_group("player")
		# Collision layers
		player.collision_layer = 2
		player.collision_mask = 1  # world

	# Wire mobile controls
	if mobile_controls:
		if mobile_controls.has_signal("move_input"):
			mobile_controls.move_input.connect(_on_mobile_move)
		if mobile_controls.has_signal("interact_pressed"):
			mobile_controls.interact_pressed.connect(_on_mobile_interact)
		if mobile_controls.has_signal("pause_pressed"):
			mobile_controls.pause_pressed.connect(_on_mobile_pause)
		if mobile_controls.has_signal("lights_pressed"):
			mobile_controls.lights_pressed.connect(_on_mobile_lights)

	# Wire pause menu
	if pause_menu:
		if pause_menu.has_signal("resume_requested"):
			pause_menu.resume_requested.connect(_on_resume)

	# Start with lights on
	if theater and theater.has_method("set_lights_dimmed"):
		theater.set_lights_dimmed(false)


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
