extends Node3D
## Lunar Roving Vehicle (LRV), Apollo 15, 1971: greybox modular.
## 4 ruedas metalicas flexibles (representacion simplificada), dos
## asientos, equipo cientifico y antena. No es una copia a escala exacta.

var _wheel_roots: Array[Node3D] = []
var _frame: Node3D = null


func _ready() -> void:
	_build_model()


func has_four_wheels() -> bool:
	return _wheel_roots.size() == 4


func preview_travel(distance: float = 1.6) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:z", position.z - distance, 2.1).set_trans(Tween.TRANS_SINE)
	for wheel in _wheel_roots:
		var rotation_tween := create_tween()
		rotation_tween.tween_property(wheel, "rotation:x", wheel.rotation.x + TAU * 0.65, 2.1)


func _build_model() -> void:
	var aluminium := _mat(Color(0.61, 0.64, 0.65), 0.36)
	var dark := _mat(Color(0.20, 0.24, 0.27), 0.16)
	var wire := _mat(Color(0.45, 0.47, 0.48), 0.28)
	var gold := _mat(Color(0.65, 0.53, 0.33), 0.22)
	var cushion := _mat(Color(0.69, 0.63, 0.48), 0.03)

	_frame = Node3D.new()
	_frame.name = "ChassisAndEquipment"
	add_child(_frame)
	_box(_frame, "CentralDeck", Vector3(0, 0.78, 0.00),
		Vector3(1.35, 0.13, 2.20), aluminium)
	for side in [-1, 1]:
		var sx := float(side)
		_box(_frame, "LongitudinalRail_%d" % side, Vector3(sx * 0.64, 0.80, 0.0),
			Vector3(0.06, 0.085, 2.40), aluminium)
		for axle_z in [-0.94, 0.94]:
			_rod(_frame, "Axle_%d_%d" % [side, int(axle_z * 100)],
				Vector3(sx * 0.46, 0.44, axle_z),
				Vector3(sx * 0.96, 0.44, axle_z), 0.052, dark)
	_box(_frame, "RearScienceBox", Vector3(0, 1.08, 0.96),
		Vector3(1.03, 0.52, 0.46), gold)
	_box(_frame, "FrontElectronics", Vector3(0, 0.94, -1.00),
		Vector3(1.11, 0.30, 0.37), gold)

	# Dos asientos abiertos: no hay cabina cerrada como un rover marciano.
	for side in [-1, 1]:
		var seat_x := float(side) * 0.38
		_box(_frame, "SeatCushion_%d" % side,
			Vector3(seat_x, 1.06, 0.15), Vector3(0.62, 0.10, 0.55), cushion)
		_box(_frame, "SeatBack_%d" % side,
			Vector3(seat_x, 1.36, 0.44), Vector3(0.62, 0.68, 0.10), cushion)
		_rod(_frame, "SeatBelt_%d" % side,
			Vector3(seat_x - 0.28, 1.29, 0.44),
			Vector3(seat_x + 0.28, 1.04, -0.04), 0.018, dark)

	# Unidad de control y antena parabólica, símbolos legibles.
	_rod(_frame, "ControlColumn", Vector3(0, 0.86, -0.44),
		Vector3(0, 1.34, -0.44), 0.035, aluminium)
	_box(_frame, "TBarController", Vector3(0, 1.34, -0.46),
		Vector3(0.36, 0.045, 0.08), dark)
	_rod(_frame, "CameraMast", Vector3(0.42, 0.84, -1.15),
		Vector3(0.42, 1.97, -1.15), 0.034, aluminium)
	_box(_frame, "TV_Camera", Vector3(0.42, 2.01, -1.18),
		Vector3(0.25, 0.18, 0.34), dark)
	_rod(_frame, "HighGainMast", Vector3(-0.34, 0.88, -1.08),
		Vector3(-0.34, 2.02, -1.08), 0.035, aluminium)
	_disc(_frame, "HighGainDish", Vector3(-0.34, 2.04, -1.08), 0.34, 0.05, aluminium)

	# Las cuatro ruedas del LRV tenian estructura flexible de malla
	# metalica, no grandes neumaticos de goma inflados.
	for side in [-1, 1]:
		for axle in [-1, 1]:
			var wheel := Node3D.new()
			wheel.name = "WireMeshWheel_%s_%s" % [
				"Left" if side == -1 else "Right",
				"Front" if axle == -1 else "Rear"
			]
			wheel.position = Vector3(float(side) * 0.97, 0.43, float(axle) * 0.94)
			add_child(wheel)
			_wheel_roots.append(wheel)
			var tire := _disc(wheel, "FlexibleMeshTire", Vector3.ZERO, 0.37, 0.24, wire)
			tire.rotation_degrees.z = 90.0
			var hub := _disc(wheel, "WheelHub", Vector3(0, 0, 0), 0.15, 0.26, dark)
			hub.rotation_degrees.z = 90.0
			# Bandas chevron en el aro. Simbólicas, no una copia de la trama
			# metalúrgica original.
			for i in range(12):
				var angle := float(i) * TAU / 12.0
				var ridged := _box(wheel, "Chevron_%02d" % i,
					Vector3(0.0, cos(angle) * 0.35, sin(angle) * 0.35),
					Vector3(0.27, 0.052, 0.035), dark)
				ridged.rotation.x = angle + 0.28


func _mat(color: Color, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.78
	return m


func _box(parent: Node3D, name_of_part: String,
	pos: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var o := MeshInstance3D.new()
	o.name = name_of_part
	o.position = pos
	var m := BoxMesh.new()
	m.size = dimensions
	m.material = material
	o.mesh = m
	parent.add_child(o)
	return o


func _disc(parent: Node3D, name_of_part: String,
	pos: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var o := MeshInstance3D.new()
	o.name = name_of_part
	o.position = pos
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = 18
	m.material = material
	o.mesh = m
	parent.add_child(o)
	return o


func _rod(parent: Node3D, name_of_part: String,
	start: Vector3, end: Vector3, radius: float, material: Material) -> void:
	var d := end - start
	if d.length() < 0.001:
		return
	var o := _disc(parent, name_of_part, (start + end) * 0.5,
		radius, d.length(), material)
	o.quaternion = Quaternion(Vector3.UP, d.normalized())
