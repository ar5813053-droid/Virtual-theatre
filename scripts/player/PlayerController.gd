extends CharacterBody3D
## First-person player controller for Virtual Cinema 3D
## Supports desktop (WASD + mouse) and Android (virtual joystick + touch look)

signal interaction_requested
signal pause_requested
signal lights_toggle_requested

const SPEED := 4.0
const ACCELERATION := 12.0
const FRICTION := 10.0
const MOUSE_SENSITIVITY := 0.0025
const TOUCH_SENSITIVITY := 0.004
const GRAVITY := 9.8
const MAX_PITCH := 1.4  # ~80 degrees

@export var jump_enabled: bool = false
@export var jump_velocity: float = 4.5

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var interaction_ray: RayCast3D = $CameraPivot/Camera3D/InteractionRay
@onready var standing_collision: CollisionShape3D = $StandingCollision

var is_sitting: bool = false
var current_seat: Node3D = null
var sitting_transform: Transform3D
var original_parent: Node = null

# Mobile input state
var mobile_move_vector: Vector2 = Vector2.ZERO
var is_mobile: bool = false
var touch_look_active: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO

# Mouse capture
var mouse_captured: bool = false


func _ready() -> void:
	is_mobile = OS.has_feature("mobile") or OS.get_name() == "Android"
	interaction_ray.enabled = true
	interaction_ray.target_position = Vector3(0, 0, -2.5)
	interaction_ray.collision_mask = 4  # interactable layer

	if not is_mobile:
		_capture_mouse()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if is_sitting:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif jump_enabled and Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_velocity

	# Movement input
	var input_dir := Vector2.ZERO
	if is_mobile:
		input_dir = mobile_move_vector
	else:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0.01:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if is_sitting:
		if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
			stand_up()
		return

	# Desktop mouse look
	if not is_mobile and mouse_captured and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -MAX_PITCH, MAX_PITCH)

	# Desktop interaction / pause / lights
	if not is_mobile:
		if event.is_action_pressed("interact"):
			_try_interact()
		elif event.is_action_pressed("pause"):
			pause_requested.emit()
		elif event.is_action_pressed("toggle_lights"):
			lights_toggle_requested.emit()

	# Touch look for mobile (right half of screen)
	if is_mobile and event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.4:
			touch_look_active = true
			last_touch_pos = event.position
		elif not event.pressed:
			touch_look_active = false

	if is_mobile and event is InputEventScreenDrag and touch_look_active:
		var delta_pos: Vector2 = event.position - last_touch_pos
		last_touch_pos = event.position
		rotate_y(-delta_pos.x * TOUCH_SENSITIVITY)
		camera_pivot.rotate_x(-delta_pos.y * TOUCH_SENSITIVITY)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -MAX_PITCH, MAX_PITCH)


func set_mobile_move(vec: Vector2) -> void:
	mobile_move_vector = vec.limit_length(1.0)


func _try_interact() -> void:
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider and collider.has_method("on_interact"):
			collider.on_interact(self)
			return
		# Walk up the tree for Area3D / seat nodes
		var parent = collider.get_parent() if collider else null
		while parent:
			if parent.has_method("on_interact"):
				parent.on_interact(self)
				return
			parent = parent.get_parent()
	interaction_requested.emit()


func sit_down(seat: Node3D, sit_point: Marker3D) -> void:
	if is_sitting:
		return
	is_sitting = true
	current_seat = seat
	standing_collision.disabled = true
	velocity = Vector3.ZERO

	# Store original state
	original_parent = get_parent()
	sitting_transform = global_transform

	# Move to seat
	global_transform = sit_point.global_transform
	# Slight height adjust so camera is at eye level when seated
	global_position.y += 0.15

	# Reset look a bit toward screen
	camera_pivot.rotation.x = -0.1


func stand_up() -> void:
	if not is_sitting:
		return
	is_sitting = false
	standing_collision.disabled = false

	# Place slightly in front of seat to avoid collision trap
	if current_seat and is_instance_valid(current_seat):
		var exit_offset := current_seat.global_transform.basis.z * 1.1
		global_position = current_seat.global_position + exit_offset + Vector3(0, 0.1, 0)
		# Face away from seat
		look_at(global_position + current_seat.global_transform.basis.z, Vector3.UP)
		if current_seat.has_method("free_seat"):
			current_seat.free_seat()
	else:
		global_transform = sitting_transform

	current_seat = null
	velocity = Vector3.ZERO


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true


func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false


func toggle_mouse_capture() -> void:
	if mouse_captured:
		release_mouse()
	else:
		_capture_mouse()


func get_interaction_target() -> Node:
	if interaction_ray.is_colliding():
		return interaction_ray.get_collider()
	return null
