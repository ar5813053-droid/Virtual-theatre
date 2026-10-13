extends Node3D
## Theater environment: geometry, lights, screen material, ambience.

signal lights_dimmed(dimmed: bool)

@onready var cinema_lights: Node3D = $CinemaLights
@onready var screen_mesh: MeshInstance3D = $Screen/ScreenMesh
@onready var ambience_player: AudioStreamPlayer = $AmbiencePlayer

var lights_are_dimmed: bool = false
var normal_energy: float = 0.6
var dimmed_energy: float = 0.08


func _ready() -> void:
	_setup_screen_material()
	_setup_ambience()
	_apply_light_state()


func _setup_screen_material() -> void:
	if not screen_mesh:
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.15, 0.15, 0.2)
	# Simple test-pattern style: dark blue with a soft center glow look via emission
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.35, 0.6)
	mat.emission_energy_multiplier = 0.8
	screen_mesh.material_override = mat


func _setup_ambience() -> void:
	if ambience_player:
		# Placeholder: no external audio asset required for Phase 1.
		# When an AudioStream is assigned in the editor it will loop quietly.
		ambience_player.volume_db = -18.0
		ambience_player.autoplay = false


func toggle_lights() -> void:
	lights_are_dimmed = not lights_are_dimmed
	_apply_light_state()
	lights_dimmed.emit(lights_are_dimmed)


func set_lights_dimmed(dimmed: bool) -> void:
	lights_are_dimmed = dimmed
	_apply_light_state()
	lights_dimmed.emit(lights_are_dimmed)


func _apply_light_state() -> void:
	if not cinema_lights:
		return
	var target := dimmed_energy if lights_are_dimmed else normal_energy
	for child in cinema_lights.get_children():
		if child is OmniLight3D:
			child.light_energy = target
		elif child is SpotLight3D:
			child.light_energy = target * 1.5
		elif child is DirectionalLight3D:
			child.light_energy = target * 0.3


func play_ambience() -> void:
	if ambience_player and ambience_player.stream:
		ambience_player.play()


func stop_ambience() -> void:
	if ambience_player:
		ambience_player.stop()
