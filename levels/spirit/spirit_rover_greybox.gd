extends Node3D
## Spirit MER-A: greybox educativo reemplazable, NO réplica dimensional.
## Seis ruedas, mástil de cámaras, paneles solares y brazo de instrumentos.
## El rover real quedó atrapado en Troy; nunca se liberó de ese lugar.

var _slip_warning := false
var _stationary_science := false
var _wheel_group: Node3D


func _ready() -> void:
	_build_model()


func has_six_wheels() -> bool:
	if _wheel_group == null:
		return false
	for side in ["L", "R"]:
		for index in range(3):
			if _wheel_group.get_node_or_null("Wheel_%s%d" % [side, index]) == null:
				return false
	return true


func indicate_slip() -> void:
	_slip_warning = true
	var warning := get_node_or_null("SpiritHardware/WarningMarker") as MeshInstance3D
	if warning != null:
		warning.visible = true


func enter_stationary_science() -> void:
	_stationary_science = true
	var mast := get_node_or_null("SpiritHardware/CameraMast") as Node3D
	if mast != null:
		create_tween().tween_property(mast, "rotation_degrees:y", 20.0, 0.8)


func _build_model() -> void:
	var frame := Node3D.new()
	frame.name = "SpiritHardware"
	add_child(frame)
	var metal := _material(Color(0.62, 0.59, 0.51))
	var dark := _material(Color(0.13, 0.16, 0.20))
	var solar := _material(Color(0.08, 0.17, 0.29))
	var gold := _material(Color(0.72, 0.54, 0.30))
	var red := _material(Color(0.91, 0.32, 0.18))
	_box(frame, "RoverChassis", Vector3(0, 0.70, 0), Vector3(1.38, 0.32, 1.12), gold)
	_box(frame, "ElectronicsBay", Vector3(0, 0.97, 0.12), Vector3(0.78, 0.25, 0.65), metal)
	for side in [-1, 1]:
		var wing := _box(frame, "SolarPanel_%s" % ("L" if side < 0 else "R"),
			Vector3(float(side) * 1.05, 1.04, 0.05), Vector3(1.04, 0.06, 1.18), solar)
		wing.rotation_degrees.z = -7.0 * float(side)
	_wheel_group = Node3D.new()
	_wheel_group.name = "Wheels"
	frame.add_child(_wheel_group)
	for side in ["L", "R"]:
		var side_sign := -1.0 if side == "L" else 1.0
		for index in range(3):
			var z_pos := (float(index) - 1.0) * 0.54
			var wheel := MeshInstance3D.new()
			wheel.name = "Wheel_%s%d" % [side, index]
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.25
			cylinder.bottom_radius = 0.25
			cylinder.height = 0.13
			cylinder.radial_segments = 12
			cylinder.material = dark
			wheel.mesh = cylinder
			wheel.position = Vector3(side_sign * 0.82, 0.27, z_pos)
			wheel.rotation_degrees.z = 90.0
			_wheel_group.add_child(wheel)
			_rod(frame, "Suspension_%s%d" % [side, index],
				Vector3(side_sign * 0.49, 0.67, z_pos * 0.7),
				wheel.position, 0.042, metal)
	var mast := Node3D.new()
	mast.name = "CameraMast"
	mast.position = Vector3(0, 1.02, -0.24)
	frame.add_child(mast)
	_rod(mast, "MastPost", Vector3.ZERO, Vector3(0, 0.95, 0), 0.055, metal)
	_box(mast, "StereoCameraHead", Vector3(0, 1.02, 0), Vector3(0.55, 0.22, 0.21), dark)
	_box(mast, "LeftPancam", Vector3(-0.19, 1.04, -0.14), Vector3(0.12, 0.11, 0.09), metal)
	_box(mast, "RightPancam", Vector3(0.19, 1.04, -0.14), Vector3(0.12, 0.11, 0.09), metal)
	_rod(frame, "InstrumentArm", Vector3(0.38, 0.67, -0.45),
		Vector3(0.70, 0.24, -1.07), 0.045, metal)
	_box(frame, "ScienceInstrumentTurret", Vector3(0.70, 0.24, -1.07),
		Vector3(0.30, 0.18, 0.24), dark)
	_rod(frame, "AntennaMast", Vector3(-0.25, 1.06, 0.28),
		Vector3(-0.36, 1.54, 0.37), 0.04, metal)
	var dish := _box(frame, "Antenna", Vector3(-0.36, 1.54, 0.37),
		Vector3(0.38, 0.06, 0.36), metal)
	dish.rotation_degrees.x = 25.0
	var warning := _box(frame, "WarningMarker", Vector3(0.0, 1.28, 0.31),
		Vector3(0.24, 0.14, 0.12), red)
	warning.visible = false


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.74
	return material


func _box(parent: Node3D, part_name: String, center: Vector3,
	size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	mesh.position = center
	var geometry := BoxMesh.new()
	geometry.size = size
	geometry.material = material
	mesh.mesh = geometry
	parent.add_child(mesh)
	return mesh


func _rod(parent: Node3D, part_name: String, start: Vector3,
	finish: Vector3, radius: float, material: Material) -> void:
	var length_vector := finish - start
	if length_vector.length() < 0.001:
		return
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	mesh.position = (start + finish) * 0.5
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length_vector.length()
	cylinder.radial_segments = 8
	cylinder.material = material
	mesh.mesh = cylinder
	mesh.quaternion = Quaternion(Vector3.UP, length_vector.normalized())
	parent.add_child(mesh)
