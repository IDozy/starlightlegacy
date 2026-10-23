extends Node3D
## Apollo 11 Lunar Module Eagle: greybox EDUCATIVO, no reconstruccion exacta.
## Dos partes claramente distintas: descenso estacionario y ascenso movible.
## Al separarse, la etapa de descenso debe permanecer en su lugar.

var _descent: Node3D
var _ascent: Node3D
var _separated := false


func _ready() -> void:
	_build_model()


func stage_nodes_exist() -> bool:
	return _descent != null and _ascent != null


func descent_stage_still_on_ground() -> bool:
	return _descent != null and is_equal_approx(_descent.position.y, 0.0)


func launch_ascent_preview() -> bool:
	if _separated or not stage_nodes_exist():
		return false
	_separated = true
	# Animacion didactica, sin representar velocidad, trayectoria ni
	# telemetria reales del despegue de Apollo 11.
	var tween := create_tween()
	tween.tween_property(_ascent, "position:y", 6.0, 2.7).set_trans(Tween.TRANS_SINE)
	return true


func _build_model() -> void:
	var metal := _material(Color(0.45, 0.48, 0.51), 0.42)
	var dark := _material(Color(0.21, 0.25, 0.29), 0.12)
	var gold := _material(Color(0.70, 0.49, 0.23), 0.28)
	var foil := _material(Color(0.80, 0.64, 0.34), 0.28)
	var feet := _material(Color(0.32, 0.34, 0.35), 0.32)
	var glass := _material(Color(0.08, 0.16, 0.21), 0.10)

	_descent = Node3D.new()
	_descent.name = "DescentStage"
	add_child(_descent)

	_make_box(_descent, "FourSidedDescentHull", Vector3(0, 1.09, 0),
		Vector3(1.75, 1.03, 1.75), gold)
	_make_box(_descent, "DescentTopDeck", Vector3(0, 1.67, 0),
		Vector3(2.02, 0.13, 2.02), metal)
	_make_box(_descent, "FoilPanelFront", Vector3(0, 0.98, -0.90),
		Vector3(1.48, 0.75, 0.10), foil)
	_make_box(_descent, "FoilPanelLeft", Vector3(-0.90, 0.98, 0),
		Vector3(0.10, 0.75, 1.48), gold)
	_make_box(_descent, "FoilPanelRight", Vector3(0.90, 0.98, 0),
		Vector3(0.10, 0.75, 1.48), foil)
	_make_box(_descent, "FoilPanelBack", Vector3(0, 0.98, 0.90),
		Vector3(1.48, 0.75, 0.10), gold)

	# Apoyos y patas forman una sola plataforma fisica; cuatro puntos
	# exteriores y riostras conectadas al casco (no partes flotantes).
	for i in range(4):
		var x: float = -1.0 if (i & 1) == 0 else 1.0
		var z: float = -1.0 if (i & 2) == 0 else 1.0
		var root := Vector3(x * 0.65, 1.42, z * 0.65)
		var foot := Vector3(x * 1.58, 0.09, z * 1.58)
		_make_rod(_descent, "LandingLeg_%d" % i, root, foot, 0.07, metal)
		_make_rod(_descent, "LandingBrace_%d" % i,
			Vector3(x * 0.70, 0.77, z * 0.70),
			Vector3(x * 1.32, 0.36, z * 1.32), 0.04, metal)
		_make_disc(_descent, "Footpad_%d" % i, foot,
			0.25, 0.15, feet)

	_make_box(_descent, "LandingAccessLadder", Vector3(0, 0.79, -1.02),
		Vector3(0.38, 1.48, 0.08), metal)
	for rung in range(5):
		_make_box(_descent, "LadderRung_%d" % rung,
			Vector3(0, 0.27 + float(rung) * 0.25, -1.10),
			Vector3(0.33, 0.045, 0.08), dark)

	# La etapa superior se mueve completa; la estructura inferior nunca
	# se anima durante la separacion.
	_ascent = Node3D.new()
	_ascent.name = "AscentStage"
	add_child(_ascent)
	_make_box(_ascent, "CrewCabin", Vector3(0, 2.32, 0),
		Vector3(1.56, 1.14, 1.26), metal)
	_make_box(_ascent, "AscentTopShell", Vector3(0, 2.98, 0),
		Vector3(1.22, 0.28, 1.15), dark)
	_make_box(_ascent, "LeftWindow", Vector3(-0.43, 2.59, -0.65),
		Vector3(0.41, 0.34, 0.045), glass)
	_make_box(_ascent, "RightWindow", Vector3(0.43, 2.59, -0.65),
		Vector3(0.41, 0.34, 0.045), glass)
	_make_box(_ascent, "AscentFrontPanel", Vector3(0, 2.02, -0.66),
		Vector3(0.85, 0.31, 0.08), dark)
	_make_rod(_ascent, "CommunicationsAntenna",
		Vector3(0.51, 3.09, 0.25), Vector3(0.77, 3.91, 0.31), 0.025, metal)
	_make_disc(_ascent, "AntennaDish",
		Vector3(0.77, 3.92, 0.31), 0.16, 0.06, foil)
	_make_disc(_ascent, "AscentEngineNozzle",
		Vector3(0, 1.76, 0), 0.24, 0.28, dark)


func _material(tint: Color, metal_value: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = tint
	result.metallic = metal_value
	result.roughness = 0.74
	return result


func _make_box(parent: Node3D, part_name: String, center: Vector3,
	dimensions: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.position = center
	var geometry := BoxMesh.new()
	geometry.size = dimensions
	geometry.material = material
	instance.mesh = geometry
	parent.add_child(instance)
	return instance


func _make_rod(parent: Node3D, part_name: String,
	start: Vector3, finish: Vector3, radius: float, material: Material) -> void:
	var axis := finish - start
	if axis.length() < 0.001:
		return
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = axis.length()
	cylinder.radial_segments = 8
	cylinder.material = material
	instance.mesh = cylinder
	instance.position = (start + finish) * 0.5
	instance.quaternion = Quaternion(Vector3.UP, axis.normalized())
	parent.add_child(instance)


func _make_disc(parent: Node3D, part_name: String,
	center: Vector3, radius: float, height: float, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.position = center
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 14
	mesh.material = material
	instance.mesh = mesh
	parent.add_child(instance)
