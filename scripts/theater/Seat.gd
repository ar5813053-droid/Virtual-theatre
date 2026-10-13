extends StaticBody3D
## Interactive cinema seat. Player can sit via interaction ray / proximity.

signal seat_occupied(seat: Node3D)
signal seat_freed(seat: Node3D)

@onready var sit_point: Marker3D = $SitPoint
@onready var highlight: MeshInstance3D = $Highlight
@onready var interaction_area: Area3D = $InteractionArea

var is_occupied: bool = false
var player_ref: CharacterBody3D = null


func _ready() -> void:
	# Collision on interactable layer
	collision_layer = 4
	collision_mask = 0
	if highlight:
		highlight.visible = false
		var hl_mat := StandardMaterial3D.new()
		hl_mat.albedo_color = Color(0.2, 0.8, 0.4, 0.6)
		hl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		highlight.material_override = hl_mat
	var seat_mat := StandardMaterial3D.new()
	seat_mat.albedo_color = Color(0.35, 0.12, 0.15)
	seat_mat.roughness = 0.85
	for child in get_children():
		if child is MeshInstance3D and child != highlight:
			child.material_override = seat_mat
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
		interaction_area.collision_mask = 2  # player layer


func on_interact(player: CharacterBody3D) -> void:
	if is_occupied:
		return
	if player and player.has_method("sit_down"):
		is_occupied = true
		player_ref = player
		player.sit_down(self, sit_point)
		seat_occupied.emit(self)
		if highlight:
			highlight.visible = false


func free_seat() -> void:
	is_occupied = false
	player_ref = null
	seat_freed.emit(self)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_occupied and highlight:
		highlight.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and highlight:
		highlight.visible = false
