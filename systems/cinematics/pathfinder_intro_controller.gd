extends Node3D
## Reconstrucción cinematográfica in-engine del aterrizaje de Pathfinder.
## Todos los objetos visibles son proxies sin colisión: NO alteran el terreno
## v33, el rover interactivo, las historias ni el progreso del Archivo NASA.

signal cinematic_finished(skipped: bool)

const DURATION := 15.5
const LANDING_END := 7.25
const PETALS_END := 10.25
const ROVER_END := 13.0
const CAMERA_BLEND := 2.5

var _playing := false
var _finished := false
var _elapsed := 0.0
var _stage := -1
var _lander: Node3D
var _rover: Node3D
var _player: CharacterBody3D
var _gameplay_hud: CanvasLayer
var _player_camera: Camera3D
var _camera: Camera3D
var _landing_pose: Node3D
var _rover_pose: Node3D
var _rover_goal: Vector3
var _rover_start: Vector3
var _parachute: MeshInstance3D
var _rocket_flare: MeshInstance3D
var _airbags: Array[MeshInstance3D] = []
var _petals: Dictionary = {}
var _canopy_rods: Array[MeshInstance3D] = []
var _overlay: CanvasLayer
var _caption: Label
var _subtitle: Label
var _hint: Label


func _ready() -> void:
	set_process(false)


func is_playing() -> bool:
	return _playing


func elapsed_seconds() -> float:
	return _elapsed


func begin(lander: Node3D, rover: Node3D, player: CharacterBody3D,
	gameplay_hud: CanvasLayer) -> void:
	if _playing or _finished:
		return
	if lander == null or rover == null or player == null or gameplay_hud == null:
		_finish(true)
		return
	_player_camera = player.get_node_or_null("Head/Camera3D") as Camera3D
	if _player_camera == null:
		_finish(true)
		return
	_lander = lander
	_rover = rover
	_player = player
	_gameplay_hud = gameplay_hud
	_build_camera()
	_build_lander_proxy()
	_build_rover_proxy()
	_build_overlay()
	_lander.visible = false
	_rover.visible = false
	_gameplay_hud.visible = false
	_player.call("set_control_locked", true)
	_camera.make_current()
	_playing = true
	set_process(true)
	_apply_frame(0.0)


func skip_intro() -> void:
	if _playing:
		_finish(true)


func _unhandled_input(event: InputEvent) -> void:
	if not _playing or not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE or event.keycode == KEY_E:
		skip_intro()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed = minf(_elapsed + delta, DURATION)
	_apply_frame(_elapsed)
	if _elapsed >= DURATION:
		_finish(false)


func _apply_frame(seconds: float) -> void:
	var target := _lander.global_position
	var altitude := _altitude(seconds)
	_landing_pose.global_position = target + Vector3.UP * altitude
	_update_parachute_and_bags(seconds)
	_update_petals(seconds)
	_update_rover(seconds)
	_update_shot(seconds)
	var phase := _phase(seconds)
	if phase != _stage:
		_stage = phase
		_update_titles(phase)


func _altitude(seconds: float) -> float:
	# Dos rebotes breves de una secuencia real de muchos rebotes. Animatic,
	# no recreación física/telemetría de Pathfinder.
	if seconds < 2.7:
		return lerpf(11.0, 6.0, smoothstep(0.0, 2.7, seconds))
	if seconds < 4.0:
		return lerpf(6.0, 0.50, smoothstep(2.7, 4.0, seconds))
	if seconds < 4.7:
		return lerpf(0.50, 2.35, smoothstep(4.0, 4.7, seconds))
	if seconds < 5.4:
		return lerpf(2.35, 0.27, smoothstep(4.7, 5.4, seconds))
	if seconds < 5.95:
		return lerpf(0.27, 0.90, smoothstep(5.4, 5.95, seconds))
	if seconds < 6.6:
		return lerpf(0.90, 0.0, smoothstep(5.95, 6.6, seconds))
	return 0.0


func _update_parachute_and_bags(seconds: float) -> void:
	var canopy_open := seconds < 3.0
	_parachute.visible = canopy_open
	for rod in _canopy_rods:
		rod.visible = canopy_open
	_rocket_flare.visible = seconds >= 2.15 and seconds < 3.25
	if _rocket_flare.visible:
		_rocket_flare.scale.y = 0.55 + 0.2 * sin(seconds * 18.0)
	var bag_size := 0.0
	if seconds < 2.5:
		bag_size = 0.04
	elif seconds < 3.25:
		bag_size = lerpf(0.04, 1.0, smoothstep(2.5, 3.25, seconds))
	elif seconds < LANDING_END:
		bag_size = 1.0
	else:
		bag_size = lerpf(1.0, 0.04, smoothstep(LANDING_END, 8.35, seconds))
	for bag in _airbags:
		bag.visible = bag_size > 0.05
		bag.scale = Vector3.ONE * bag_size


func _update_petals(seconds: float) -> void:
	var open_factor := smoothstep(7.95, 9.85, seconds)
	for name in _petals.keys():
		var data: Dictionary = _petals[name]
		var node: MeshInstance3D = data["node"]
		node.position = (data["closed_position"] as Vector3).lerp(data["open_position"] as Vector3, open_factor)
		node.rotation_degrees = (data["closed_rotation"] as Vector3).lerp(
			data["open_rotation"] as Vector3, open_factor
		)
	for name in ["SolarPanel", "Mast", "CameraHead"]:
		var node := _landing_pose.get_node_or_null(name) as MeshInstance3D
		if node != null:
			node.visible = seconds >= 8.6
	if seconds >= PETALS_END:
		_landing_pose.visible = false
		_lander.visible = true


func _update_rover(seconds: float) -> void:
	if _rover_pose == null:
		if seconds >= ROVER_END:
			_rover.visible = true
		return
	_rover_pose.visible = seconds >= PETALS_END and seconds < ROVER_END
	if _rover_pose.visible:
		var move_factor := smoothstep(PETALS_END, ROVER_END, seconds)
		_rover_pose.global_position = _rover_start.lerp(_rover_goal, move_factor)
	if seconds >= ROVER_END:
		_rover.visible = true


func _phase(seconds: float) -> int:
	if seconds < 2.7:
		return 0
	if seconds < 4.0:
		return 1
	if seconds < 7.25:
		return 2
	if seconds < 10.25:
		return 3
	if seconds < 13.0:
		return 4
	return 5


func _update_titles(phase: int) -> void:
	match phase:
		0:
			_caption.text = "4 DE JULIO DE 1997 · ARES VALLIS, MARTE"
			_subtitle.text = "Pathfinder desciende protegido por paracaídas."
		1:
			_caption.text = "DESCENSO FINAL"
			_subtitle.text = "Los retrocohetes frenan la nave. Los airbags amortiguan el impacto."
		2:
			_caption.text = "ATERRIZAJE CON AIRBAGS"
			_subtitle.text = "Rebota sobre la superficie marciana antes de detenerse."
		3:
			_caption.text = "PATHFINDER ABRE SUS PÉTALOS"
			_subtitle.text = "Los airbags se desinflan y el módulo despliega sus paneles."
		4:
			_caption.text = "EN LOS SOLES SIGUIENTES · SOJOURNER"
			_subtitle.text = "El rover sale por la rampa trasera para investigar el terreno."
		5:
			_caption.text = "EL RECUERDO CONTINÚA CONTIGO"
			_subtitle.text = "Explora Ares Vallis y descubre lo que quedó en Marte."


func _update_shot(seconds: float) -> void:
	var land := _lander.global_position
	var rover_pos := _rover_goal
	if seconds < 4.0:
		var craft := _landing_pose.global_position
		var pos := land + Vector3(-8.0, 5.4 + _altitude(seconds) * 0.55, 11.0)
		_aim_camera(pos, craft + Vector3.UP * 0.7)
	elif seconds < LANDING_END:
		_aim_camera(land + Vector3(-6.6, 4.1, 9.0),
			_landing_pose.global_position + Vector3.UP * 0.5)
	elif seconds < PETALS_END:
		var turn := smoothstep(LANDING_END, PETALS_END, seconds)
		var pos := (land + Vector3(-5.0, 3.4, 6.1)).lerp(
			land + Vector3(3.8, 2.8, 5.4), turn)
		_aim_camera(pos, land + Vector3.UP * 0.95)
	elif seconds < ROVER_END:
		var turn := smoothstep(PETALS_END, ROVER_END, seconds)
		var pos := (land + Vector3(3.8, 2.8, 5.4)).lerp(
			rover_pos + Vector3(3.0, 2.1, 4.0), turn)
		var focus := (land + Vector3(0, 0.7, -1.0)).lerp(
			rover_pos + Vector3.UP * 0.4, turn)
		_aim_camera(pos, focus)
	else:
		var from_pos := rover_pos + Vector3(3.0, 2.1, 4.0)
		var from_transform := Transform3D(Basis.IDENTITY, from_pos).looking_at(
			rover_pos + Vector3.UP * 0.4, Vector3.UP)
		var end_transform := _player_camera.global_transform
		var mix := smoothstep(ROVER_END, ROVER_END + CAMERA_BLEND, seconds)
		var blended_basis := Basis(Quaternion(from_transform.basis).slerp(
			Quaternion(end_transform.basis), mix))
		_camera.global_transform = Transform3D(
			blended_basis,
			from_pos.lerp(end_transform.origin, mix)
		)


func _aim_camera(origin: Vector3, focus: Vector3) -> void:
	_camera.global_position = origin
	_camera.look_at(focus, Vector3.UP)


func _finish(skipped: bool) -> void:
	if _finished:
		return
	_finished = true
	_playing = false
	set_process(false)
	if is_instance_valid(_lander):
		_lander.visible = true
	if is_instance_valid(_rover):
		_rover.visible = true
	if is_instance_valid(_gameplay_hud):
		_gameplay_hud.visible = true
	if is_instance_valid(_player_camera):
		_player_camera.make_current()
	if is_instance_valid(_player):
		_player.call("set_control_locked", false)
	if is_instance_valid(_overlay):
		_overlay.visible = false
	if is_instance_valid(_landing_pose):
		_landing_pose.queue_free()
	if is_instance_valid(_rover_pose):
		_rover_pose.queue_free()
	cinematic_finished.emit(skipped)


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "IntroCamera"
	_camera.fov = 66.0
	_camera.near = 0.05
	add_child(_camera)


func _build_lander_proxy() -> void:
	_landing_pose = Node3D.new()
	_landing_pose.name = "LandingReconstruction"
	add_child(_landing_pose)
	_landing_pose.global_transform = _lander.global_transform
	for child in _lander.get_children():
		if not (child is MeshInstance3D):
			continue
		var source := child as MeshInstance3D
		var mesh := source.duplicate(0) as MeshInstance3D
		mesh.name = str(source.name)
		_landing_pose.add_child(mesh)
		if not mesh.name.begins_with("Petal"):
			continue
		var closed_pos := Vector3(0.0, 0.75, 0.0)
		var closed_rot := Vector3.ZERO
		match mesh.name:
			"PetalLeft":
				closed_pos = Vector3(-0.20, 0.64, 0.0)
				closed_rot = Vector3(0.0, 0.0, -88.0)
			"PetalRight":
				closed_pos = Vector3(0.20, 0.64, 0.0)
				closed_rot = Vector3(0.0, 0.0, 88.0)
			"PetalRear":
				closed_pos = Vector3(0.0, 0.64, 0.18)
				closed_rot = Vector3(88.0, 0.0, 0.0)
		_petals[mesh.name] = {
			"node": mesh,
			"open_position": mesh.position,
			"open_rotation": mesh.rotation_degrees,
			"closed_position": closed_pos,
			"closed_rotation": closed_rot
		}
	var bag_material := StandardMaterial3D.new()
	bag_material.albedo_color = Color(0.83, 0.73, 0.59)
	bag_material.roughness = 0.93
	var bag_mesh := SphereMesh.new()
	bag_mesh.radius = 0.76
	bag_mesh.height = 1.52
	bag_mesh.material = bag_material
	for i in range(6):
		var bag := MeshInstance3D.new()
		bag.name = "ImpactAirbag_%d" % i
		bag.mesh = bag_mesh
		var angle := TAU * float(i) / 6.0
		bag.position = Vector3(cos(angle) * 0.77, 0.28, sin(angle) * 0.70)
		_landing_pose.add_child(bag)
		_airbags.append(bag)
	var parachute_mesh := SphereMesh.new()
	parachute_mesh.radius = 2.25
	parachute_mesh.height = 0.55
	parachute_mesh.radial_segments = 20
	var parachute_mat := StandardMaterial3D.new()
	parachute_mat.albedo_color = Color(0.94, 0.86, 0.75)
	parachute_mat.roughness = 0.88
	parachute_mesh.material = parachute_mat
	_parachute = MeshInstance3D.new()
	_parachute.name = "ParachuteSilhouette"
	_parachute.mesh = parachute_mesh
	_parachute.position = Vector3(0.0, 4.2, 0.0)
	_landing_pose.add_child(_parachute)
	for i in range(4):
		var cord := MeshInstance3D.new()
		cord.name = "Suspension_%d" % i
		var rod := CylinderMesh.new()
		rod.top_radius = 0.013
		rod.bottom_radius = 0.013
		rod.height = 3.3
		var cord_mat := StandardMaterial3D.new()
		cord_mat.albedo_color = Color(0.80, 0.75, 0.69)
		rod.material = cord_mat
		cord.mesh = rod
		cord.position = Vector3((-0.65 if i % 2 == 0 else 0.65), 2.55,
			(-0.65 if i < 2 else 0.65))
		_landing_pose.add_child(cord)
		_canopy_rods.append(cord)
	_rocket_flare = MeshInstance3D.new()
	_rocket_flare.name = "BrakingRocketGlow"
	var rocket_mesh := SphereMesh.new()
	rocket_mesh.radius = 0.33
	rocket_mesh.height = 1.8
	var rocket_mat := StandardMaterial3D.new()
	rocket_mat.albedo_color = Color(1.0, 0.58, 0.19)
	rocket_mat.emission_enabled = true
	rocket_mat.emission = Color(0.94, 0.41, 0.11)
	rocket_mesh.material = rocket_mat
	_rocket_flare.mesh = rocket_mesh
	_rocket_flare.position = Vector3(0.0, -0.65, 0.0)
	_landing_pose.add_child(_rocket_flare)


func _build_rover_proxy() -> void:
	var source_root := _rover.get_node_or_null("RoverVisual") as Node3D
	if source_root == null:
		return
	_rover_pose = Node3D.new()
	_rover_pose.name = "SojournerDeploymentReconstruction"
	add_child(_rover_pose)
	_rover_pose.global_transform = source_root.global_transform
	_copy_visible_meshes(source_root, source_root, _rover_pose)
	_rover_goal = source_root.global_position
	_rover_start = _lander.global_position + Vector3(0.7, 0.22, -1.15)
	_rover_pose.global_position = _rover_start
	_rover_pose.visible = false


func _copy_visible_meshes(node: Node3D, relative_to: Node3D, parent: Node3D) -> void:
	for child in node.get_children():
		if not (child is Node3D):
			continue
		var item := child as Node3D
		if item is MeshInstance3D and item.is_visible_in_tree():
			var original := item as MeshInstance3D
			var copy := MeshInstance3D.new()
			copy.name = "Preview_" + str(original.name)
			copy.mesh = original.mesh
			copy.material_override = original.material_override
			copy.transform = relative_to.global_transform.affine_inverse() * original.global_transform
			if copy.mesh != null:
				for surface_index in range(copy.mesh.get_surface_count()):
					var override := original.get_surface_override_material(surface_index)
					if override != null:
						copy.set_surface_override_material(surface_index, override)
			parent.add_child(copy)
		_copy_visible_meshes(item, relative_to, parent)


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "CinematicHUD"
	_overlay.layer = 80
	add_child(_overlay)
	for bottom in [false, true]:
		var bar := ColorRect.new()
		bar.name = "BottomLetterbox" if bottom else "TopLetterbox"
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.86 if bottom else 0.0
		bar.anchor_bottom = 1.0 if bottom else 0.14
		bar.color = Color(0.012, 0.017, 0.027, 0.96)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.add_child(bar)
	_caption = Label.new()
	_caption.name = "ShotTitle"
	_caption.anchor_left = 0.06
	_caption.anchor_top = 0.015
	_caption.anchor_right = 0.94
	_caption.anchor_bottom = 0.075
	_caption.add_theme_font_size_override("font_size", 23)
	_caption.add_theme_color_override("font_color", Color(0.99, 0.74, 0.42))
	_overlay.add_child(_caption)
	_subtitle = Label.new()
	_subtitle.name = "ShotCaption"
	_subtitle.anchor_left = 0.06
	_subtitle.anchor_top = 0.88
	_subtitle.anchor_right = 0.94
	_subtitle.anchor_bottom = 0.95
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_font_size_override("font_size", 18)
	_subtitle.add_theme_color_override("font_color", Color(0.92, 0.91, 0.88))
	_overlay.add_child(_subtitle)
	_hint = Label.new()
	_hint.name = "SkipHint"
	_hint.anchor_left = 0.71
	_hint.anchor_top = 0.065
	_hint.anchor_right = 0.97
	_hint.anchor_bottom = 0.12
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.text = "E / Esc · Omitir"
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color(0.82, 0.78, 0.72))
	_overlay.add_child(_hint)
