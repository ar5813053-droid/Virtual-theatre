extends Node3D
## 3D tablet prop attached to player camera socket + 2D control overlay for reliable touch.

signal visibility_changed(shown: bool)
signal open_url_panel

@export var video_manager_path: NodePath = NodePath("../../VideoManager")

@onready var mesh_root: Node3D = $MeshRoot
@onready var screen_quad: MeshInstance3D = $MeshRoot/ScreenQuad

var _vm: Node
var _ui: Control
var _visible: bool = false
var _player: CharacterBody3D


func _ready() -> void:
	visible = false
	_visible = false
	call_deferred("_bind")


func _bind() -> void:
	var root := get_tree().current_scene
	if root:
		_vm = root.get_node_or_null("VideoManager")
		_player = root.get_node_or_null("Player") as CharacterBody3D
		_ui = root.get_node_or_null("UI/TabletUI") as Control
	if not _vm and not video_manager_path.is_empty():
		_vm = get_node_or_null(video_manager_path)

	# Attach to player tablet socket if available
	if _player and _player.has_method("get_tablet_socket"):
		var socket: Marker3D = _player.get_tablet_socket()
		if socket:
			reparent(socket)
			transform = Transform3D.IDENTITY

	if _ui and _ui.has_signal("close_requested"):
		_ui.close_requested.connect(hide_tablet)
	if _ui and _ui.has_signal("open_url_requested"):
		_ui.open_url_requested.connect(func(): open_url_panel.emit())


func toggle() -> void:
	if _visible:
		hide_tablet()
	else:
		show_tablet()


func show_tablet() -> void:
	_visible = true
	visible = true
	if _ui:
		_ui.visible = true
		if _ui.has_method("bind_video_manager"):
			_ui.bind_video_manager(_vm)
		if _ui.has_method("refresh"):
			_ui.refresh()
	# Desktop: free mouse for UI
	if _player and _player.has_method("release_mouse"):
		_player.release_mouse()
	visibility_changed.emit(true)


func hide_tablet() -> void:
	_visible = false
	visible = false
	if _ui:
		_ui.visible = false
	if _player and not (OS.has_feature("mobile") or OS.get_name() == "Android"):
		if _player.has_method("_capture_mouse"):
			_player._capture_mouse()
	visibility_changed.emit(false)


func is_tablet_visible() -> bool:
	return _visible
