extends Control
## Virtual joystick (left) + interact button (bottom-right) for Android.
## Keeps controls away from screen edges for comfort and system gestures.

signal move_input(vector: Vector2)
signal interact_pressed
signal pause_pressed
signal lights_pressed

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var interact_btn: Button = $InteractButton
@onready var pause_btn: Button = $PauseButton
@onready var lights_btn: Button = $LightsButton

var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var max_radius: float = 60.0


func _ready() -> void:
	visible = OS.has_feature("mobile") or OS.get_name() == "Android"
	if joystick_base:
		joystick_center = joystick_base.size * 0.5
		max_radius = min(joystick_base.size.x, joystick_base.size.y) * 0.4
	if interact_btn:
		interact_btn.pressed.connect(func(): interact_pressed.emit())
	if pause_btn:
		pause_btn.pressed.connect(func(): pause_pressed.emit())
	if lights_btn:
		lights_btn.pressed.connect(func(): lights_pressed.emit())


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Only start joystick if touch is inside the base
		if joystick_base and _is_inside_control(joystick_base, event.position):
			joystick_active = true
			joystick_touch_index = event.index
			_update_knob(event.position)
	else:
		if event.index == joystick_touch_index:
			joystick_active = false
			joystick_touch_index = -1
			_reset_knob()
			move_input.emit(Vector2.ZERO)


func _handle_drag(event: InputEventScreenDrag) -> void:
	if joystick_active and event.index == joystick_touch_index:
		_update_knob(event.position)


func _update_knob(screen_pos: Vector2) -> void:
	if not joystick_base or not joystick_knob:
		return
	var local := joystick_base.get_global_transform_with_canvas().affine_inverse() * screen_pos
	var offset: Vector2 = local - joystick_center
	if offset.length() > max_radius:
		offset = offset.normalized() * max_radius
	joystick_knob.position = joystick_center + offset - joystick_knob.size * 0.5
	var strength := offset / max_radius
	# Godot forward is -Z, so invert Y for stick (up = negative Z)
	move_input.emit(Vector2(strength.x, -strength.y))


func _reset_knob() -> void:
	if joystick_knob and joystick_base:
		joystick_knob.position = joystick_center - joystick_knob.size * 0.5


func _is_inside_control(ctrl: Control, screen_pos: Vector2) -> bool:
	var rect := ctrl.get_global_rect()
	return rect.has_point(screen_pos)
