extends Control
## Virtual joystick (left) + interact button (bottom-right) for Android.
## Keeps controls away from screen edges for comfort and system gestures.

signal move_input(vector: Vector2)
signal interact_pressed
signal pause_pressed
signal lights_pressed
signal video_pressed
signal tablet_pressed

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var interact_btn: Button = $InteractButton
@onready var pause_btn: Button = $PauseButton
@onready var lights_btn: Button = $LightsButton
@onready var video_btn: Button = get_node_or_null("VideoButton")
@onready var tablet_btn: Button = get_node_or_null("TabletButton")

var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var max_radius: float = 60.0


func _ready() -> void:
	visible = OS.has_feature("mobile") or OS.get_name() == "Android"
	if joystick_base:
		# Size may be zero until layout; recompute on first frame if needed
		call_deferred("_init_joystick_geometry")
	if interact_btn:
		interact_btn.pressed.connect(func(): interact_pressed.emit())
	if pause_btn:
		pause_btn.pressed.connect(func(): pause_pressed.emit())
	if lights_btn:
		lights_btn.pressed.connect(func(): lights_pressed.emit())
	if video_btn:
		video_btn.pressed.connect(func(): video_pressed.emit())
	if tablet_btn:
		tablet_btn.pressed.connect(func(): tablet_pressed.emit())


func _init_joystick_geometry() -> void:
	if not joystick_base:
		return
	joystick_center = joystick_base.size * 0.5
	max_radius = min(joystick_base.size.x, joystick_base.size.y) * 0.4
	_reset_knob()


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
	# Knob visual follows finger
	joystick_knob.position = joystick_center + offset - joystick_knob.size * 0.5

	# Map to player input matching desktop Input.get_vector convention:
	#   forward (stick up)  -> negative Y  -> player uses Vector3(x,0,y) with -Z forward
	#   back    (stick down)-> positive Y
	#   right   (stick right)-> positive X
	# Screen Y increases downward, so stick-up gives offset.y < 0 (already correct for forward).
	# Do NOT negate Y — previous code used -strength.y which inverted forward/back.
	var strength := offset / max_radius
	var input_vec := Vector2(strength.x, strength.y)
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()
	move_input.emit(input_vec)


func _reset_knob() -> void:
	if joystick_knob and joystick_base:
		joystick_knob.position = joystick_center - joystick_knob.size * 0.5


func _is_inside_control(ctrl: Control, screen_pos: Vector2) -> bool:
	var rect := ctrl.get_global_rect()
	return rect.has_point(screen_pos)


## True while the active joystick touch is held (so camera look ignores it).
func is_joystick_touch(index: int) -> bool:
	return joystick_active and index == joystick_touch_index
