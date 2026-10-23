extends Node3D
## Viking 1 lander, Chryse Planitia 1976. Greybox reemplazable.
## Tres patas, cuerpo hexagonal, dos camaras, dos fuentes RTG,
## antena de alta ganancia y brazo recolector. No reproduce medidas exactas.

var _sampler_arm: Node3D


func _ready() -> void:
	_build_lander()


func has_three_feet() -> bool:
	return (
		get_node_or_null("LanderHardware/LandingFoot_0") != null
		and get_node_or_null("LanderHardware/LandingFoot_1") != null
		and get_node_or_null("LanderHardware/LandingFoot_2") != null
	)


func deploy_sampler_preview() -> void:
	if _sampler_arm == null:
		return
	var tween := create_tween()
	tween.tween_property(_sampler_arm, "rotation_degrees:y", -36.0, 1.2)


func _build_lander() -> void:
	var metal := _material(Color(0.69, 0.71, 0.67), 0.48)
	var gold := _material(Color(0.69, 0.54, 0.31), 0.26)
	var dark := _material(Color(0.25, 0.26, 0.25), 0.28)
	var white := _material(Color(0.82, 0.80, 0.70), 0.12)
	var lens := _material(Color(0.06, 0.13, 0.19), 0.15)
	var frame := Node3D.new()
	frame.name = "LanderHardware"
	add_child(frame)

	# Un prisma de seis lados (no otro rover con carroceria rectangular).
	var hull := MeshInstance3D.new()
	hull.name = "HexagonalEquipmentBay"
	var hull_mesh := CylinderMesh.new()
	hull_mesh.top_radius = 1.05
	hull_mesh.bottom_radius = 1.05
	hull_mesh.height = 0.62
	hull_mesh.radial_segments = 6
	hull_mesh.material = metal
	hull.mesh = hull_mesh
	hull.position = Vector3(0, 1.04, 0)
	hull.rotation_degrees.y = 30.0
	frame.add_child(hull)
	_box(frame, "TopScienceDeck", Vector3(0, 1.40, 0),
		Vector3(1.48, 0.12, 1.16), gold)

	# NASA: tres patas en formacion triangular, no cuatro.
	for i in range(3):
		var angle := -PI / 2.0 + float(i) * TAU / 3.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		var start := direction * 0.58 + Vector3(0, 1.24, 0)
		var end := direction * 1.63 + Vector3(0, 0.14, 0)
		_rod(frame, "LandingLeg_%d" % i, start, end, 0.073, metal)
		_rod(frame, "Brace_%d" % i,
			direction * 0.69 + Vector3(0, 0.83, 0),
			direction * 1.37 + Vector3(0, 0.30, 0), 0.035, dark)
		_disc(frame, "LandingFoot_%d" % i, end, 0.29, 0.13, dark)

	# Viking no usaba paneles solares: se alimentaba con RTG.
	for side in [-1, 1]:
		var x := float(side)
		_disc(frame, "RTGShield_%d" % side,
			Vector3(x * 0.82, 1.51, 0.42), 0.28, 0.60, white)
		_box(frame, "RTGSupport_%d" % side,
			Vector3(x * 0.77, 1.12, 0.42),
			Vector3(0.30, 0.13, 0.40), gold)

	# Dos camaras escaneadoras de imagen cilindrica sobre la cubierta.
	for i in range(2):
		var camera_x: float = -0.43 if i == 0 else 0.43
		_disc(frame, "PanoramicCamera_%d" % i,
			Vector3(camera_x, 1.82, -0.45), 0.12, 0.67, white)
		_box(frame, "CameraLens_%d" % i,
			Vector3(camera_x, 2.02, -0.56),
			Vector3(0.16, 0.13, 0.05), lens)

	_rod(frame, "HighGainAntennaMast",
		Vector3(0.55, 1.50, 0.36), Vector3(0.96, 2.40, 0.43), 0.043, metal)
	var dish := _disc(frame, "HighGainDish",
		Vector3(0.96, 2.42, 0.43), 0.36, 0.065, white)
	dish.rotation_degrees.x = 70.0
	_rod(frame, "WeatherBoom", Vector3(-0.70, 1.39, 0.10),
		Vector3(-1.31, 2.26, 0.12), 0.025, metal)
	_box(frame, "WeatherSensors", Vector3(-1.32, 2.29, 0.12),
		Vector3(0.28, 0.11, 0.15), dark)

	_sampler_arm = Node3D.new()
	_sampler_arm.name = "SoilSamplingArm"
	_sampler_arm.position = Vector3(0, 1.13, -0.68)
	frame.add_child(_sampler_arm)
	_rod(_sampler_arm, "SamplerBoom", Vector3(0, 0, 0),
		Vector3(0, -0.68, -1.29), 0.055, dark)
	_box(_sampler_arm, "SoilScoop", Vector3(0, -0.73, -1.37),
		Vector3(0.42, 0.14, 0.28), metal)
	_box(frame, "BiologySamplePort", Vector3(-0.30, 1.50, -0.27),
		Vector3(0.25, 0.10, 0.20), dark)
	_box(frame, "ChemicalAnalysisPort", Vector3(0.31, 1.50, -0.27),
		Vector3(0.25, 0.10, 0.20), dark)


func _material(color: Color, metal_amount: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal_amount
	material.roughness = 0.66
	return material


func _box(parent: Node3D, part_name: String, center: Vector3,
	dimensions: Vector3, material: Material) -> void:
	var o := MeshInstance3D.new()
	o.name = part_name
	o.position = center
	var geometry := BoxMesh.new()
	geometry.size = dimensions
	geometry.material = material
	o.mesh = geometry
	parent.add_child(o)


func _disc(parent: Node3D, part_name: String, center: Vector3,
	radius: float, height: float, material: Material) -> MeshInstance3D:
	var o := MeshInstance3D.new()
	o.name = part_name
	o.position = center
	var geometry := CylinderMesh.new()
	geometry.top_radius = radius
	geometry.bottom_radius = radius
	geometry.height = height
	geometry.radial_segments = 18
	geometry.material = material
	o.mesh = geometry
	parent.add_child(o)
	return o


func _rod(parent: Node3D, part_name: String, origin: Vector3,
	end: Vector3, radius: float, material: Material) -> void:
	var d := end - origin
	if d.length() < 0.001:
		return
	var rod := _disc(parent, part_name, (origin + end) * 0.5,
		radius, d.length(), material)
	rod.quaternion = Quaternion(Vector3.UP, d.normalized())
