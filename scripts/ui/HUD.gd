extends Control
## Minimal on-screen hints and temporary messages.

@onready var hint_label: Label = $HintLabel
@onready var message_label: Label = $MessageLabel

var _message_timer: float = 0.0


func _ready() -> void:
	if message_label:
		message_label.visible = false
	_update_hints()


func _process(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0 and message_label:
			message_label.visible = false


func _update_hints() -> void:
	if not hint_label:
		return
	var mobile := OS.has_feature("mobile") or OS.get_name() == "Android"
	if mobile:
		hint_label.text = "Joystick • Look (right) • Sit/Stand • Video • Tablet"
	else:
		hint_label.text = "WASD • Mouse look • E sit/stand • Esc pause • L lights • V video URL • T tablet"


func show_message(text: String, duration: float = 2.0) -> void:
	if message_label:
		message_label.text = text
		message_label.visible = true
		_message_timer = duration
