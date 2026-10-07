extends CharacterBody3D

signal interaction_prompt_changed(prompt: String)
signal inspection_state_changed(is_inspecting: bool, title: String, description: String)

@export var move_speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var inspection_sensitivity: float = 0.01
@export var interaction_distance: float = 3.0

@onready var head: Node3D = $Head
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var inspection_pivot: Node3D = $Head/Camera3D/InspectionPivot

var _current_interactable: Node = null
var _inspected_object: Node = null
var _inspection_visual: Node3D = null
var _is_inspecting := false
var _control_locked := false


func _ready() -> void:
	add_to_group("player_controller")
	interaction_ray.target_position = Vector3(0.0, 0.0, -interaction_distance)
	_capture_mouse()


func _unhandled_input(event: InputEvent) -> void:
	if _control_locked:
		return

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			_capture_mouse()
			return

	if _is_inspecting:
		_handle_inspection_input(event)
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and _current_interactable != null:
			var main_node := get_parent()
			if main_node != null and main_node.has_method("set_interaction_debug"):
				main_node.call(
					"set_interaction_debug",
					"1 · E detectada → %s" % _current_interactable.name
				)

			_current_interactable.call("interact", self)
			return

		if event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				_release_mouse()
			else:
				_capture_mouse()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if _control_locked or _is_inspecting:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)
		move_and_slide()
		return

	_update_interaction_target()

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


func set_control_locked(locked: bool) -> void:
	_control_locked = locked
	if locked:
		_set_current_interactable(null)


func can_open_knowledge() -> bool:
	return not _control_locked and not _is_inspecting


func start_inspection(interactable: Node) -> void:
	if _is_inspecting or interactable == null:
		return

	if not interactable.has_method("create_inspection_visual"):
		return

	var visual := interactable.call("create_inspection_visual") as Node3D
	if visual == null:
		return

	_is_inspecting = true
	_inspected_object = interactable
	_set_current_interactable(null)

	inspection_pivot.rotation = Vector3.ZERO
	inspection_pivot.add_child(visual)
	_inspection_visual = visual

	if interactable.has_method("set_world_visible"):
		interactable.call("set_world_visible", false)

	var title := "Objeto"
	var description := ""

	if interactable.has_method("get_inspection_title"):
		title = str(interactable.call("get_inspection_title"))

	if interactable.has_method("get_inspection_description"):
		description = str(interactable.call("get_inspection_description"))

	_register_discovery(interactable)
	inspection_state_changed.emit(true, title, description)


func stop_inspection() -> void:
	if not _is_inspecting:
		return

	if _inspected_object != null and is_instance_valid(_inspected_object):
		if _inspected_object.has_method("set_world_visible"):
			_inspected_object.call("set_world_visible", true)

	if _inspection_visual != null and is_instance_valid(_inspection_visual):
		_inspection_visual.queue_free()

	_inspection_visual = null
	_inspected_object = null
	_is_inspecting = false
	inspection_pivot.rotation = Vector3.ZERO

	inspection_state_changed.emit(false, "", "")


func _handle_inspection_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		inspection_pivot.rotate_y(-event.relative.x * inspection_sensitivity)
		inspection_pivot.rotate_x(-event.relative.y * inspection_sensitivity)
		inspection_pivot.rotation.x = clamp(
			inspection_pivot.rotation.x,
			deg_to_rad(-80.0),
			deg_to_rad(80.0)
		)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_ESCAPE:
			stop_inspection()


func _update_interaction_target() -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_set_current_interactable(null)
		return

	interaction_ray.force_raycast_update()
	var collider := interaction_ray.get_collider()
	var new_interactable: Node = null

	if collider is Node:
		var collider_node := collider as Node
		if collider_node.has_method("get_interaction_prompt") and collider_node.has_method("interact"):
			new_interactable = collider_node

	_set_current_interactable(new_interactable)


func _set_current_interactable(interactable: Node) -> void:
	if interactable == _current_interactable:
		return

	_current_interactable = interactable

	if _current_interactable == null:
		interaction_prompt_changed.emit("")
	else:
		interaction_prompt_changed.emit(str(_current_interactable.call("get_interaction_prompt")))


func _register_discovery(interactable: Node) -> void:
	if not interactable.has_method("get_discovery_data"):
		return

	var discovery = interactable.call("get_discovery_data")
	if not (discovery is Dictionary) or discovery.is_empty():
		return

	var registry := get_node_or_null("/root/KnowledgeRegistry")
	if registry == null or not registry.has_method("register_discovery"):
		return

	registry.call(
		"register_discovery",
		str(discovery.get("id", "")),
		str(discovery.get("title", "Descubrimiento")),
		str(discovery.get("category", "Conocimiento")),
		str(discovery.get("summary", ""))
	)


func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_set_current_interactable(null)
