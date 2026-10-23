extends Node3D
## InSight (2018-2022), maqueta de sismómetro SEIS y módulo fijo.
## No crea datos de sismos NASA, ni inventa el éxito del calorímetro HP3.

var _lander: Node3D
var _seismometer: Node3D
var _shield: MeshInstance3D
var _seis_placed := false
var _noise_checked := false


func _ready() -> void:
	_build_model()


func has_stationary_lander() -> bool:
	return _lander != null and _seismometer != null


func place_seismometer() -> bool:
	if _seis_placed or not has_stationary_lander():
		return false
	_seis_placed = true
	_seismometer.position = Vector3(-1.7, 0.0, 0.0)
	return true


func check_environmental_noise() -> bool:
	if not _seis_placed or _noise_checked:
		return false
	_noise_checked = true
	_shield.visible = true
	return true


func instrument_is_protected() -> bool:
	return _seis_placed and _noise_checked and _shield != null and _shield.visible


func _build_model() -> void:
	var golden := _mat(Color(0.77, 0.61, 0.26))
	var dark := _mat(Color(0.20, 0.27, 0.32))
	var blue := _mat(Color(0.10, 0.21, 0.35))
	var shield_mat := _mat(Color(0.78, 0.75, 0.67))
	_lander = Node3D.new()
	_lander.name = "StationaryLander"
	add_child(_lander)
	_box(_lander, "LanderDeck", Vector3(0, 0.75, 0), Vector3(1.4, 0.33, 1.3), golden)
	for i in range(3):
		var angle := TAU * float(i) / 3.0
		_box(_lander, "LandingLeg_%d" % i, Vector3(cos(angle) * 0.87, 0.34, sin(angle) * 0.87),
			Vector3(0.16, 0.70, 0.16), dark)
	for i in range(2):
		var x := -1.5 if i == 0 else 1.5
		_box(_lander, "SolarWing_%d" % i, Vector3(x, 0.70, 0), Vector3(1.5, 0.08, 1.5), blue)
	_box(_lander, "RoboticInstrumentArm", Vector3(-0.70, 1.20, 0),
		Vector3(1.02, 0.10, 0.12), dark)
	_seismometer = Node3D.new()
	_seismometer.name = "SEISSeismometer"
	add_child(_seismometer)
	_box(_seismometer, "SEISSensor", Vector3(0, 0.20, 0), Vector3(0.64, 0.40, 0.64), golden)
	_shield = MeshInstance3D.new()
	_shield.name = "WindAndThermalShield"
	_seismometer.add_child(_shield)
	var dome := SphereMesh.new()
	dome.radius = 0.50
	dome.height = 0.37
	dome.material = shield_mat
	_shield.mesh = dome
	_shield.position.y = 0.43
	_shield.visible = false


func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	return mat


func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3,
	mat: StandardMaterial3D) -> void:
	var part := MeshInstance3D.new()
	part.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	part.mesh = mesh
	part.position = pos
	parent.add_child(part)
