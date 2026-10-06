extends CharacterBody3D

@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

@onready var head: Node3D = $Head

var _mouse_captured := true


func _ready() -> void:
	_capture_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _mouse_captured:
			_release_mouse()
		else:
			_capture_mouse()

	if event is InputEventMouseButton and event.pressed and not _mouse_captured:
		_capture_mouse()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	var input_vector := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vector.y += 1.0

	input_vector = input_vector.normalized()

	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)

	move_and_slide()


func _capture_mouse() -> void:
	_mouse_captured = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _release_mouse() -> void:
	_mouse_captured = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
