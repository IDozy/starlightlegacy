extends Node3D
## Sky Crane de Perseverance. Maqueta didáctica, NO recreación de vuelo.
## Modelo aislado para sustituir después; estados deterministas para los tests.
## El rover toca suelo ANTES de cortar cables; la etapa se aleja luego.

var _descent_stage: Node3D = null
var _rover: Node3D = null
var _tethers: Node3D = null
var _safe_site_selected := false
var _rover_lowered := false
var _touchdown_confirmed := false
var _cables_cut := false
var _stage_flew_away := false


func _ready() -> void:
	_build_model()


func rig_parts_exist() -> bool:
	return _descent_stage != null and _rover != null and _tethers != null


func select_safe_site() -> bool:
	if not rig_parts_exist() or _safe_site_selected:
		return false
	_safe_site_selected = true
	return true


func lower_rover_with_cables() -> bool:
	if not _safe_site_selected or _rover_lowered or not rig_parts_exist():
		return false
	_rover_lowered = true
	# La maqueta cambia al estado final de descenso sin interpolación física.
	_rover.position.y = 0.40
	for tether in _tethers.get_children():
		if tether is MeshInstance3D:
			tether.scale.y = 1.25
			tether.position.y = 2.53
	return true


func confirm_touchdown() -> bool:
	if not _rover_lowered or _touchdown_confirmed:
		return false
	_touchdown_confirmed = true
	return true


func cut_cables_and_fly_away() -> bool:
	if not _touchdown_confirmed or _cables_cut or not rig_parts_exist():
		return false
	_cables_cut = true
	_tethers.visible = false
	_stage_flew_away = true
	# Demostración visual de la etapa que se aleja. No recrea el choque real.
	var tween := create_tween()
	tween.tween_property(_descent_stage, "position", Vector3(5.5, 6.0, -3.0), 2.0)
	return true


func rover_remains_landed() -> bool:
	return _rover != null and _touchdown_confirmed and is_equal_approx(_rover.position.y, 0.40)


func _build_model() -> void:
	var metal := _material(Color(0.55, 0.58, 0.60))
	var dark := _material(Color(0.19, 0.23, 0.27))
	var copper := _material(Color(0.77, 0.38, 0.16))
	var cable := _material(Color(0.83, 0.75, 0.55))
	var tyre := _material(Color(0.10, 0.11, 0.12))

	_descent_stage = Node3D.new()
	_descent_stage.name = "PoweredDescentStage"
	add_child(_descent_stage)
	_box(_descent_stage, "EightEngineFrame", Vector3(0, 4.68, 0),
		Vector3(3.25, 0.35, 2.45), metal)
	_box(_descent_stage, "CentralThrusterHull", Vector3(0, 4.98, 0),
		Vector3(1.45, 0.45, 1.10), dark)
	# Representación simplificada de ocho motores, sin jets simulados.
	for i in range(8):
		var x := -1.32 if i % 2 == 0 else 1.32
		var z := -0.98 + 0.65 * float(i / 2)
		_box(_descent_stage, "LandingEngine_%02d" % i,
			Vector3(x, 4.32, z), Vector3(0.23, 0.37, 0.23), copper)

	_rover = Node3D.new()
	_rover.name = "PerseveranceRover"
	_rover.position.y = 1.72
	add_child(_rover)
	_box(_rover, "RoverChassis", Vector3(0, 0.61, 0),
		Vector3(1.86, 0.48, 1.25), copper)
	_box(_rover, "ScienceDeck", Vector3(0, 1.02, 0),
		Vector3(1.25, 0.21, 0.87), dark)
	_box(_rover, "CameraMast", Vector3(0.24, 1.53, -0.12),
		Vector3(0.16, 0.91, 0.16), metal)
	_box(_rover, "CameraHead", Vector3(0.24, 1.99, -0.12),
		Vector3(0.52, 0.19, 0.27), dark)
	for side in [-1.0, 1.0]:
		for axis in range(3):
			var wheel := MeshInstance3D.new()
			wheel.name = "Wheel_%s_%02d" % ["L" if side < 0 else "R", axis]
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.29
			cylinder.bottom_radius = 0.29
			cylinder.height = 0.22
			cylinder.radial_segments = 12
			cylinder.material = tyre
			wheel.mesh = cylinder
			wheel.rotation_degrees.z = 90
			wheel.position = Vector3(side * 1.08, 0.29, float(axis - 1) * 0.53)
			_rover.add_child(wheel)

	_tethers = Node3D.new()
	_tethers.name = "SuspensionCables"
	add_child(_tethers)
	for i in range(3):
		var rope := MeshInstance3D.new()
		rope.name = "Cable_%02d" % i
		var rod := CylinderMesh.new()
		rod.top_radius = 0.027
		rod.bottom_radius = 0.027
		rod.height = 1.75
		rod.material = cable
		rope.mesh = rod
		rope.position = Vector3(float(i - 1) * 0.65, 3.22, -0.17)
		_tethers.add_child(rope)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	return material


func _box(parent: Node3D, name: String, pos: Vector3, dims: Vector3,
	material: StandardMaterial3D) -> void:
	var part := MeshInstance3D.new()
	part.name = name
	var mesh := BoxMesh.new()
	mesh.size = dims
	mesh.material = material
	part.mesh = mesh
	part.position = pos
	parent.add_child(part)
