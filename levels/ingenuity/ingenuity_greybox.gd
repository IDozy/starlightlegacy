extends Node3D
## Ingenuity — modelo greybox 3D ilustrativo. No es simulación aerodinámica.
## El recuerdo representa el vuelo inicial de 2021 e informa del cierre 2024.
## Cuatro patas, panel solar, DOS rotores coaxiales contrarrotatorios.

var _airframe: Node3D
var _upper_rotor: Node3D
var _lower_rotor: Node3D
var _thin_air_prepared := false
var _stable_hover := false
var _scout_landed := false


func _ready() -> void:
	_build_model()


func has_twin_counter_rotors() -> bool:
	return _upper_rotor != null and _lower_rotor != null and _upper_rotor != _lower_rotor


func has_four_legs() -> bool:
	if _airframe == null:
		return false
	var count := 0
	for child in _airframe.get_children():
		if child.name.begins_with("LandingLeg_"):
			count += 1
	return count == 4


func prepare_for_thin_air() -> bool:
	if _thin_air_prepared or not has_twin_counter_rotors() or not has_four_legs():
		return false
	_thin_air_prepared = true
	return true


func begin_controlled_hover() -> bool:
	if not _thin_air_prepared or _stable_hover or _scout_landed:
		return false
	_stable_hover = true
	# Visual educativo: giro opuesto + traslado simple, sin física real.
	_upper_rotor.rotation_degrees.y += 75.0
	_lower_rotor.rotation_degrees.y -= 75.0
	_airframe.position.y = 1.30
	return true


func complete_scout_and_land() -> bool:
	if not _stable_hover or _scout_landed:
		return false
	_scout_landed = true
	_stable_hover = false
	_airframe.position = Vector3(1.0, 0.0, -0.45)
	return true


func is_grounded_after_scout() -> bool:
	return _airframe != null and _scout_landed and is_zero_approx(_airframe.position.y)


func _build_model() -> void:
	var gold := _material(Color(0.73, 0.51, 0.21))
	var dark := _material(Color(0.12, 0.16, 0.20))
	var metal := _material(Color(0.58, 0.59, 0.56))
	var solar := _material(Color(0.10, 0.22, 0.39))
	var carbon := _material(Color(0.15, 0.19, 0.24))
	_airframe = Node3D.new()
	_airframe.name = "IngenuityAirframe"
	add_child(_airframe)
	_box(_airframe, "BatteryAndAvionics", Vector3(0, 0.62, 0), Vector3(0.70, 0.45, 0.49), gold)
	_box(_airframe, "CameraModule", Vector3(0, 0.53, -0.30), Vector3(0.24, 0.20, 0.13), dark)
	_box(_airframe, "SolarPanel", Vector3(0, 1.78, 0), Vector3(1.17, 0.05, 0.70), solar)
	_box(_airframe, "RotorMast", Vector3(0, 1.38, 0), Vector3(0.09, 0.80, 0.09), metal)
	for i in range(4):
		var leg_x := -1.0 if i % 2 == 0 else 1.0
		var leg_z := -1.0 if i < 2 else 1.0
		var leg := Node3D.new()
		leg.name = "LandingLeg_%02d" % i
		_airframe.add_child(leg)
		_box(leg, "Strut", Vector3(leg_x * 0.49, 0.29, leg_z * 0.36),
			Vector3(0.09, 0.77, 0.09), metal)
		_box(leg, "Foot", Vector3(leg_x * 0.87, 0.075, leg_z * 0.65),
			Vector3(0.20, 0.08, 0.17), metal)
	_upper_rotor = Node3D.new()
	_upper_rotor.name = "UpperRotor"
	_upper_rotor.position.y = 1.59
	_airframe.add_child(_upper_rotor)
	_lower_rotor = Node3D.new()
	_lower_rotor.name = "LowerRotor"
	_lower_rotor.position.y = 1.28
	_airframe.add_child(_lower_rotor)
	for i in range(2):
		var angle := float(i) * PI
		var blade_pos := Vector3(cos(angle) * 0.46, 0.0, sin(angle) * 0.46)
		_box(_upper_rotor, "UpperBlade_%d" % i, blade_pos,
			Vector3(0.93, 0.035, 0.19), carbon)
		_box(_lower_rotor, "LowerBlade_%d" % i, blade_pos,
			Vector3(0.93, 0.035, 0.19), carbon)
	_upper_rotor.rotation_degrees.y = 0.0
	_lower_rotor.rotation_degrees.y = 90.0


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	return mat


func _box(parent: Node3D, part_name: String, pos: Vector3, dims: Vector3,
	mat: StandardMaterial3D) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	var shape := BoxMesh.new()
	shape.size = dims
	shape.material = mat
	part.mesh = shape
	part.position = pos
	parent.add_child(part)
