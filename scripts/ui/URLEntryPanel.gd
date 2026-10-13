extends Control
## Modal panel to enter a direct video-file URL and load it.

signal load_requested(url: String)
signal closed

@onready var line_edit: LineEdit = $Panel/VBox/URLInput
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var load_btn: Button = $Panel/VBox/HBox/LoadButton
@onready var close_btn: Button = $Panel/VBox/HBox/CloseButton
@onready var help_label: Label = $Panel/VBox/HelpLabel


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if load_btn:
		load_btn.pressed.connect(_on_load)
	if close_btn:
		close_btn.pressed.connect(_on_close)
	if line_edit:
		line_edit.text_submitted.connect(func(_t): _on_load())
	if help_label:
		help_label.text = "Direct .ogv (Ogg Theora) file URLs only.\nYouTube / Instagram / webpages are not supported."


func open_panel() -> void:
	visible = true
	if line_edit:
		line_edit.grab_focus()
	# Release mouse so user can type on desktop
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_panel() -> void:
	visible = false
	closed.emit()


func set_status(text: String, is_error: bool = false) -> void:
	if status_label:
		status_label.text = text
		status_label.modulate = Color(1.0, 0.45, 0.4) if is_error else Color(0.85, 0.95, 0.85)


func _on_load() -> void:
	if not line_edit:
		return
	var url := line_edit.text.strip_edges()
	if url.is_empty():
		set_status("Enter a URL first.", true)
		return
	set_status("Loading…")
	load_requested.emit(url)


func _on_close() -> void:
	close_panel()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()
