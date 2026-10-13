extends Node
## Central coordinator for cinema state, pause, and cross-scene signals.

signal pause_changed(is_paused: bool)

@onready var player: CharacterBody3D = null
@onready var theater: Node3D = null
@onready var pause_ui: Control = null
@onready var mobile_ui: Control = null
@onready var hud: Control = null

var is_paused: bool = false


func _ready() -> void:
	# Deferred lookup so scene tree is ready
	call_deferred("_bind_nodes")


func _bind_nodes() -> void:
	var root := get_tree().current_scene
	if not root:
		return
	player = root.get_node_or_null("Player")
	theater = root.get_node_or_null("Theater")
	pause_ui = root.get_node_or_null("UI/PauseMenu")
	mobile_ui = root.get_node_or_null("UI/MobileControls")
	hud = root.get_node_or_null("UI/HUD")

	if player:
		if player.has_signal("pause_requested"):
			player.pause_requested.connect(toggle_pause)
		if player.has_signal("lights_toggle_requested"):
			player.lights_toggle_requested.connect(_on_lights_toggle)

	if theater and theater.has_signal("lights_dimmed"):
		theater.lights_dimmed.connect(_on_lights_dimmed)

	_update_ui_visibility()


func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_changed.emit(is_paused)

	if player:
		if is_paused:
			player.release_mouse()
		else:
			if not (OS.has_feature("mobile") or OS.get_name() == "Android"):
				player._capture_mouse()

	if pause_ui:
		pause_ui.visible = is_paused
		# Ensure pause UI processes while tree is paused
		pause_ui.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	_update_ui_visibility()


func resume() -> void:
	if is_paused:
		toggle_pause()


func _on_lights_toggle() -> void:
	if theater and theater.has_method("toggle_lights"):
		theater.toggle_lights()


func _on_lights_dimmed(dimmed: bool) -> void:
	if hud and hud.has_method("show_message"):
		hud.show_message("Lights dimmed" if dimmed else "Lights restored", 1.5)


func _update_ui_visibility() -> void:
	var mobile := OS.has_feature("mobile") or OS.get_name() == "Android"
	if mobile_ui:
		mobile_ui.visible = mobile and not is_paused
	if hud:
		hud.visible = not is_paused
