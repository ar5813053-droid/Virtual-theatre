extends Node
## Applies VideoManager texture to the theater ScreenMesh.
## Attached under Theater or Main; finds ScreenMesh and VideoManager.

@export var screen_mesh_path: NodePath = NodePath("Screen/ScreenMesh")
@export var video_manager_path: NodePath = NodePath("../../VideoManager")

var _mesh: MeshInstance3D
var _vm: Node
var _mat: StandardMaterial3D
var _placeholder_color := Color(0.15, 0.15, 0.2)


func _ready() -> void:
	call_deferred("_bind")


func _bind() -> void:
	_mesh = get_node_or_null(screen_mesh_path) as MeshInstance3D
	if not _mesh:
		# Try absolute from scene root
		var root := get_tree().current_scene
		if root:
			_mesh = root.get_node_or_null("Theater/Screen/ScreenMesh") as MeshInstance3D
	_vm = get_node_or_null(video_manager_path)
	if not _vm:
		var root2 := get_tree().current_scene
		if root2:
			_vm = root2.get_node_or_null("VideoManager")

	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = _placeholder_color
	_mat.emission_enabled = true
	_mat.emission = Color(0.2, 0.35, 0.6)
	_mat.emission_energy_multiplier = 0.6
	# Video UV often needs vertical flip depending on platform
	_mat.uv1_scale = Vector3(1, -1, 1)
	_mat.uv1_offset = Vector3(0, 1, 0)
	if _mesh:
		_mesh.material_override = _mat


func _process(_delta: float) -> void:
	if not _mesh or not _vm:
		return
	var tex: Texture2D = null
	if _vm.has_method("get_video_texture"):
		tex = _vm.get_video_texture()
	if tex and _vm.get("state") != null:
		var st = _vm.state
		# PLAYING=2, PAUSED=3 in VideoManager.State
		if st == 2 or st == 3:
			_mat.albedo_texture = tex
			_mat.albedo_color = Color.WHITE
			_mat.emission_enabled = false
			return
	# Placeholder when idle / loading / error
	if _mat.albedo_texture != null:
		_mat.albedo_texture = null
		_mat.albedo_color = _placeholder_color
		_mat.emission_enabled = true
