extends Control
## Simple pause overlay. Process mode set to WHEN_PAUSED by CinemaManager.

signal resume_requested
signal quit_requested

@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var quit_btn: Button = $Panel/VBox/QuitButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if resume_btn:
		resume_btn.pressed.connect(func(): resume_requested.emit())
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)


func _on_quit() -> void:
	# On mobile / desktop: just quit the application for Phase 1
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
