extends Node3D

# La geometría arquitectónica se importa desde Blender; la lógica del taller
# y sus elementos interactivos continúan siendo nodos propios de Godot.
const WORKSHOP_MODEL := preload("res://assets/models/taller/Taller_NASA_v02.glb")
@export var use_imported_workshop: bool = true

# Blender: 14 x 20 m, Z alto=1 m, plataforma alta=6.4 m,
# rampa de 4.2 x 3.8 m. Godot invierte el signo del eje Y de Blender en Z.
const MODEL_WIDTH: float = 14.0
const MODEL_DEPTH: float = 20.0
const UPPER_DEPTH: float = 6.4
const UPPER_HEIGHT: float = 1.0
const RAMP_WIDTH: float = 4.2
const RAMP_LENGTH: float = 3.8
const PROPS_OFFSET_Z: float = 5.0
const TEST_AREA_EXTRA_OFFSET_Z: float = 1.5
# Desplazamiento conjunto de mesa y equipo hacia la puerta lateral izquierda.
# La puerta de Blender está aproximadamente en X=-6.8, Z=+2.0; el tablero
# queda a X=-4.85, Z=+1.90, dejando espacio entre mesa y pared.
const WORKBENCH_LOWER_OFFSET := Vector3(-4.85, 0.0, 5.60)
const GRANDFATHER_UPPER_POSITION := Vector3(4.45, 1.0, -4.90)
# Protección invisible por encima del pasamanos visible; no cruza la rampa.
const UPPER_SAFETY_HEIGHT: float = 2.60
const UPPER_SAFETY_CENTER_Y: float = UPPER_HEIGHT + UPPER_SAFETY_HEIGHT * 0.5

const INSPECTABLE_OBJECT := preload("res://systems/interaction/inspectable_object.tscn")
const GRANDFATHER := preload("res://systems/dialogue/grandfather_placeholder.tscn")
const RESCUE_ROVER_PROJECT := preload("res://systems/gameplay/rescue_rover_project.tscn")
const QUATERNIUS_SOLAR_PANEL := preload("res://assets/third_party/quaternius/ultimate_space_kit/Environment/GLTF/SolarPanel_Ground.gltf")
const KENNEY_COMPUTER_WIDE := preload("res://assets/third_party/kenney/space_station_kit/Models/GLB format/computer-wide.glb")
const KENNEY_CONTAINER_WIDE := preload("res://assets/third_party/kenney/space_station_kit/Models/GLB format/container-wide.glb")
const KENNEY_DISPLAY_WALL := preload("res://assets/third_party/kenney/space_station_kit/Models/GLB format/display-wall.glb")
const KENNEY_WALL_DETAIL := preload("res://assets/third_party/kenney/space_station_kit/Models/GLB format/wall-detail.glb")
const KENNEY_CHAIR := preload("res://assets/third_party/kenney/space_station_kit/Models/GLB format/chair.glb")
const KENNEY_TABLE_DISPLAY_SMALL := preload("res://assets/third_party/kenney/space_station_kit/Models/GLB format/table-display-small.glb")
const KENNEY_WALL_SWITCH := preload("res://assets/third_party/kenney/space_station_kit/Models/GLB format/wall-switch.glb")

const FLOOR_COLOR := Color(0.115, 0.135, 0.17)
const WALL_COLOR := Color(0.48, 0.44, 0.37)
const WALL_LOWER_COLOR := Color(0.20, 0.23, 0.27)
const WOOD_COLOR := Color(0.34, 0.19, 0.10)
const METAL_COLOR := Color(0.26, 0.31, 0.35)
const TEST_MAT_COLOR := Color(0.075, 0.095, 0.12)
const TEST_BORDER_COLOR := Color(0.78, 0.43, 0.16)
const MARKING_COLOR := Color(0.92, 0.68, 0.24)
const PANEL_COLOR := Color(0.16, 0.19, 0.22)


func _ready() -> void:
	_build_lighting()
	if use_imported_workshop:
		_build_imported_room()
	else:
		_build_room()

	# Mantener los hijos directamente bajo Workshop: main.gd espera
	# $Workshop/RescueRoverProject y no se debe alterar esa ruta.
	var previous_children := get_children()
	_build_workshop_props()
	if use_imported_workshop:
		_reposition_legacy_props(previous_children)


func _build_imported_room() -> void:
	var model := WORKSHOP_MODEL.instantiate() as Node3D
	if model == null:
		push_error("No se pudo instanciar el modelo 3D del taller.")
		return
	model.name = "Taller_NASA_v02_Visual"
	add_child(model)

	# Colisiones sencillas, independientes de la geometría decorativa del GLB.
	# La superficie de la losa inferior coincide con Y=0.
	_create_collision_box(
		"ImportedLowerFloor", Vector3(0.0, -0.125, 0.0),
		Vector3(MODEL_WIDTH - 0.25, 0.25, MODEL_DEPTH - 0.25)
	)

	var upper_front_z := -(MODEL_DEPTH * 0.5 - UPPER_DEPTH)
	var upper_back_z := -MODEL_DEPTH * 0.5
	_create_collision_box(
		"ImportedUpperPlatform",
		Vector3(0.0, UPPER_HEIGHT * 0.5, (upper_front_z + upper_back_z) * 0.5),
		Vector3(MODEL_WIDTH - 0.25, UPPER_HEIGHT, UPPER_DEPTH)
	)

	# La rampa del GLB fue ajustada manualmente en Blender para acabar
	# exactamente a Y=0 y Y=1; esta cuña de colisión sigue esa pendiente.
	_create_ramp_collision(upper_front_z)

	# La puerta central queda libre; las colisiones de pared son laterales.
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0.0 else "Right"
		_create_collision_box(
			"ImportedWall" + suffix,
			Vector3(side * (MODEL_WIDTH * 0.5 - 0.12), 2.9, 0.0),
			Vector3(0.24, 5.8, MODEL_DEPTH - 0.15)
		)

	# Cerramiento del extremo del PRIMER NIVEL, contrario al portón de arriba.
	# La apertura del nivel superior queda libre para el futuro exterior.
	# Cubierta color marfil y zócalo azul a juego con el GLB.
	var back_z := MODEL_DEPTH * 0.5 - 0.20
	_create_static_box(
		"ImportedBackWall", Vector3(0.0, 2.9, back_z),
		Vector3(MODEL_WIDTH - 0.30, 5.8, 0.20), Color(0.86, 0.83, 0.77)
	)
	_create_visual_box(
		"ImportedBackWallLower", Vector3(0.0, 0.55, back_z - 0.115),
		Vector3(MODEL_WIDTH - 0.34, 1.10, 0.035), Color(0.31, 0.43, 0.53)
	)
	_create_visual_box(
		"ImportedBackWallStripe", Vector3(0.0, 2.34, back_z - 0.136),
		Vector3(MODEL_WIDTH - 0.40, 0.085, 0.040), TEST_BORDER_COLOR
	)

	# La barrera física es más alta que el salto del personaje. No se
	# dibuja: mantiene la estética de las barandas bajas de Blender.
	# Los dos tramos frontales dejan abierto el centro para la rampa.
	var gap_half := RAMP_WIDTH * 0.5 + 0.42
	var end_x := MODEL_WIDTH * 0.5 - 0.50
	var rail_length := end_x - gap_half
	var rail_center := (end_x + gap_half) * 0.5
	for side in [-1.0, 1.0]:
		var suffix := "Left" if side < 0.0 else "Right"
		for z in [upper_front_z - 0.18, upper_back_z + 0.45]:
			var end_name := "RampEdge" if z > upper_back_z + 1.0 else "GarageEdge"
			_create_collision_box(
				"ImportedRail" + end_name + suffix,
				Vector3(side * rail_center, UPPER_SAFETY_CENTER_Y, z),
				Vector3(rail_length, UPPER_SAFETY_HEIGHT, 0.10)
			)

		# Mismo límite invisible junto a cada baranda lateral alta.
		var side_rail_back_z := upper_back_z + 0.45
		var side_rail_front_z := upper_front_z - 0.90
		_create_collision_box(
			"ImportedSideSafety" + suffix,
			Vector3(
				side * end_x, UPPER_SAFETY_CENTER_Y,
				(side_rail_back_z + side_rail_front_z) * 0.5
			),
			Vector3(0.10, UPPER_SAFETY_HEIGHT, side_rail_front_z - side_rail_back_z)
		)


func _create_collision_box(
	body_name: String, center: Vector3, dimensions: Vector3
) -> void:
	var body := StaticBody3D.new()
	body.name = body_name
	body.position = center
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _create_ramp_collision(upper_front_z: float) -> void:
	var bottom_z := upper_front_z + RAMP_LENGTH
	var half_width := RAMP_WIDTH * 0.5
	# ConvexPolygonShape3D proporciona una cuña maciza para evitar que el
	# jugador atraviese la rampa. La pendiente es de ~14.7 grados.
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(-half_width, -0.20, bottom_z),
		Vector3( half_width, -0.20, bottom_z),
		Vector3(-half_width, -0.20, upper_front_z),
		Vector3( half_width, -0.20, upper_front_z),
		Vector3(-half_width, 0.0, bottom_z),
		Vector3( half_width, 0.0, bottom_z),
		Vector3(-half_width, UPPER_HEIGHT, upper_front_z),
		Vector3( half_width, UPPER_HEIGHT, upper_front_z)
	])
	var body := StaticBody3D.new()
	body.name = "ImportedRampCollision"
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _reposition_legacy_props(previous_children: Array[Node]) -> void:
	# Todos los props se crearon directamente bajo Workshop para conservar
	# sus rutas, diálogos, colisiones y señales.
	for child in get_children():
		if not (child is Node3D) or previous_children.has(child):
			continue
		var prop := child as Node3D
		var prop_name := str(prop.name)

		if prop_name == "Grandfather":
			# Segundo nivel, junto a la baranda derecha.
			prop.position = GRANDFATHER_UPPER_POSITION
			prop.rotation_degrees = Vector3(0.0, -115.0, 0.0)
		elif prop_name.begins_with("Workbench") or prop_name == "PrototypeDevice":
			# Mesa completa en el primer nivel (sin elevar piezas).
			# Todas las partes y el objeto interactivo mantienen sus
			# desplazamientos relativos a la mesa original.
			prop.position += WORKBENCH_LOWER_OFFSET
		else:
			var extra_z := 0.0
			if prop_name == "RescueRoverProject":
				extra_z = TEST_AREA_EXTRA_OFFSET_Z
			prop.position.z += PROPS_OFFSET_Z + extra_z

	# El gran panel negro detrás de la mesa procede del prototipo antiguo.
	# No pertenece al mobiliario aprobado: se retira (incluida su colisión).
	var old_backboard := get_node_or_null("WorkbenchBackboard")
	if old_backboard != null:
		old_backboard.queue_free()

	# Decoraciones antiguas asociadas a coordenadas de paredes de 12x10 m:
	# esconderlas hasta ubicarlas en la nueva arquitectura 14x20 m.
	for path in ["WorkbenchWallDisplay", "WorkshopWallDetailLeft", "EnergyWallSwitch"]:
		var decoration := get_node_or_null(path) as Node3D
		if decoration != null:
			decoration.visible = false

func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = (
		Color(0.63, 0.76, 0.88) if use_imported_workshop
		else Color(0.035, 0.043, 0.058)
	)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.46, 0.42)
	environment.ambient_light_energy = 0.78 if use_imported_workshop else 0.50
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_color = Color(1.0, 0.86, 0.70)
	sun.light_energy = 0.95 if use_imported_workshop else 0.48
	sun.shadow_enabled = true
	add_child(sun)

	var bench_light := OmniLight3D.new()
	bench_light.name = "BenchLight"
	bench_light.position = (
		Vector3(-4.75, 2.55, 1.90) if use_imported_workshop
		else Vector3(-0.4, 2.55, -3.35)
	)
	bench_light.omni_range = 5.0
	bench_light.light_color = Color(1.0, 0.68, 0.43)
	bench_light.light_energy = 1.65
	bench_light.shadow_enabled = true
	add_child(bench_light)

	var test_light := OmniLight3D.new()
	test_light.name = "TestAreaLight"
	test_light.position = (
		Vector3(1.55, 2.75, 6.05) if use_imported_workshop
		else Vector3(1.55, 2.75, -0.45)
	)
	test_light.omni_range = 4.6
	test_light.light_color = Color(0.62, 0.78, 0.92)
	test_light.light_energy = 1.15
	test_light.shadow_enabled = true
	add_child(test_light)


func _build_room() -> void:
	_create_static_box("Floor", Vector3(0.0, -0.1, 0.0), Vector3(12.0, 0.2, 10.0), FLOOR_COLOR)
	_create_static_box("BackWall", Vector3(0.0, 2.0, -5.0), Vector3(12.0, 4.0, 0.2), WALL_COLOR)
	_create_static_box("LeftWall", Vector3(-6.0, 2.0, 0.0), Vector3(0.2, 4.0, 10.0), WALL_COLOR)
	_create_static_box("RightWall", Vector3(6.0, 2.0, 0.0), Vector3(0.2, 4.0, 10.0), WALL_COLOR)

	# Front wall leaves a central opening that will later become the workshop entrance.
	_create_static_box("FrontWallLeft", Vector3(-4.0, 2.0, 5.0), Vector3(4.0, 4.0, 0.2), WALL_COLOR)
	_create_static_box("FrontWallRight", Vector3(4.0, 2.0, 5.0), Vector3(4.0, 4.0, 0.2), WALL_COLOR)
	_create_static_box("FrontWallTop", Vector3(0.0, 3.5, 5.0), Vector3(4.0, 1.0, 0.2), WALL_COLOR)

	# Dark lower wall band keeps the workshop from reading as a white test room.
	_create_visual_box("BackWallLower", Vector3(0.0, 0.55, -4.88), Vector3(11.7, 1.05, 0.04), WALL_LOWER_COLOR)
	_create_visual_box("LeftWallLower", Vector3(-5.88, 0.55, 0.0), Vector3(0.04, 1.05, 9.7), WALL_LOWER_COLOR)
	_create_visual_box("RightWallLower", Vector3(5.88, 0.55, 0.0), Vector3(0.04, 1.05, 9.7), WALL_LOWER_COLOR)

	# Thin orange workshop stripe.
	_create_visual_box("BackAccentStripe", Vector3(0.0, 1.12, -4.84), Vector3(11.6, 0.055, 0.035), TEST_BORDER_COLOR)
	_create_visual_box("LeftAccentStripe", Vector3(-5.84, 1.12, 0.0), Vector3(0.035, 0.055, 9.6), TEST_BORDER_COLOR)
	_create_visual_box("RightAccentStripe", Vector3(5.84, 1.12, 0.0), Vector3(0.035, 0.055, 9.6), TEST_BORDER_COLOR)


func _build_workshop_props() -> void:
	_build_workbench()
	# El nuevo GLB ya contiene las marcas del suelo: no duplicar
	# la alfombra negra ni los bloques de la prueba antigua.
	if not use_imported_workshop:
		_build_test_area()
	_build_kenney_storage()

	var prototype_device := INSPECTABLE_OBJECT.instantiate()
	prototype_device.name = "PrototypeDevice"
	prototype_device.position = Vector3(-0.58, 1.03, -3.62)
	add_child(prototype_device)

	_add_kenney_workbench_props()

	var rescue_rover := RESCUE_ROVER_PROJECT.instantiate()
	rescue_rover.name = "RescueRoverProject"
	rescue_rover.position = Vector3(1.55, 0.02, -0.35)
	rescue_rover.rotation_degrees = Vector3(0.0, -12.0, 0.0)
	add_child(rescue_rover)

	_add_quaternius_decor()

	var grandfather := GRANDFATHER.instantiate()
	grandfather.position = Vector3(3.55, 0.0, -2.95)
	grandfather.rotation_degrees = Vector3(0.0, -42.0, 0.0)
	add_child(grandfather)


func _build_workbench() -> void:
	# Human-scale workshop bench: 2.4 m wide, 0.75 m deep, 0.90 m high.
	_create_static_box("WorkbenchTop", Vector3(0.0, 0.90, -3.7), Vector3(2.40, 0.08, 0.75), WOOD_COLOR)
	_create_static_box("WorkbenchLegFL", Vector3(-1.05, 0.44, -3.40), Vector3(0.08, 0.88, 0.08), METAL_COLOR)
	_create_static_box("WorkbenchLegFR", Vector3(1.05, 0.44, -3.40), Vector3(0.08, 0.88, 0.08), METAL_COLOR)
	_create_static_box("WorkbenchLegRL", Vector3(-1.05, 0.44, -4.00), Vector3(0.08, 0.88, 0.08), METAL_COLOR)
	_create_static_box("WorkbenchLegRR", Vector3(1.05, 0.44, -4.00), Vector3(0.08, 0.88, 0.08), METAL_COLOR)
	_create_static_box("WorkbenchLowerShelf", Vector3(0.0, 0.24, -3.70), Vector3(2.05, 0.06, 0.56), METAL_COLOR)
	_create_static_box("WorkbenchBackboard", Vector3(0.0, 1.28, -4.04), Vector3(2.20, 0.68, 0.05), PANEL_COLOR)



func _add_kenney_workbench_props() -> void:
	_add_kenney_visual(
		"WorkbenchComputer",
		KENNEY_COMPUTER_WIDE,
		Vector3(0.58, 0.94, -3.66),
		Vector3(0.0, 180.0, 0.0),
		Vector3.ONE * 0.62
	)

	_add_kenney_body(
		"WorkbenchChair",
		KENNEY_CHAIR,
		Vector3(0.72, 0.0, -3.02),
		Vector3(0.0, 165.0, 0.0),
		Vector3.ONE * 1.18,
		Vector3(0.38, 0.66, 0.44),
		Vector3(0.0, 0.33, 0.0)
	)

	_add_kenney_visual(
		"WorkbenchWallDisplay",
		KENNEY_DISPLAY_WALL,
		Vector3(0.45, 1.48, -4.76),
		Vector3(0.0, 0.0, 0.0),
		Vector3.ONE * 1.45
	)

	_add_kenney_visual(
		"WorkshopWallDetailLeft",
		KENNEY_WALL_DETAIL,
		Vector3(-2.45, 1.18, -4.76),
		Vector3(0.0, 0.0, 0.0),
		Vector3.ONE * 1.20
	)

	_add_kenney_visual(
		"EnergyWallSwitch",
		KENNEY_WALL_SWITCH,
		Vector3(5.76, 1.25, 1.35),
		Vector3(0.0, -90.0, 0.0),
		Vector3.ONE * 1.80
	)


func _build_test_area() -> void:
	# Rubberized 2.4 x 1.8 m test mat.
	_create_visual_box("TestMat", Vector3(1.55, 0.012, -0.35), Vector3(2.40, 0.024, 1.80), TEST_MAT_COLOR)

	# Perimeter markings.
	_create_visual_box("TestBorderFront", Vector3(1.55, 0.028, 0.54), Vector3(2.40, 0.018, 0.045), TEST_BORDER_COLOR)
	_create_visual_box("TestBorderRear", Vector3(1.55, 0.028, -1.24), Vector3(2.40, 0.018, 0.045), TEST_BORDER_COLOR)
	_create_visual_box("TestBorderLeft", Vector3(0.37, 0.028, -0.35), Vector3(0.045, 0.018, 1.80), TEST_BORDER_COLOR)
	_create_visual_box("TestBorderRight", Vector3(2.73, 0.028, -0.35), Vector3(0.045, 0.018, 1.80), TEST_BORDER_COLOR)

	# Center line and impact target.
	_create_visual_box("TestCenterLine", Vector3(1.55, 0.031, -0.35), Vector3(0.035, 0.018, 1.18), MARKING_COLOR)
	_create_visual_box("ImpactTargetH", Vector3(1.55, 0.034, -0.95), Vector3(0.72, 0.018, 0.035), MARKING_COLOR)
	_create_visual_box("ImpactTargetV", Vector3(1.55, 0.034, -0.95), Vector3(0.035, 0.018, 0.50), MARKING_COLOR)

	# Low test platform: visual context for the controlled drop test.
	_create_static_box("DropPlatformBase", Vector3(0.65, 0.11, -1.02), Vector3(0.64, 0.22, 0.54), METAL_COLOR)
	_create_static_box("DropPlatformTop", Vector3(0.65, 0.24, -1.02), Vector3(0.74, 0.05, 0.62), TEST_BORDER_COLOR)

	# Small hazard stripes on the platform edge.
	for index in range(5):
		var stripe_x: float = 0.39 + float(index) * 0.13
		_create_visual_box(
			"DropStripe_%d" % index,
			Vector3(stripe_x, 0.272, -0.72),
			Vector3(0.065, 0.012, 0.035),
			MARKING_COLOR
		)



func _build_kenney_storage() -> void:
	# Real Kenney props replace the previous block shelving.
	_add_kenney_body(
		"PartsContainerA",
		KENNEY_CONTAINER_WIDE,
		Vector3(-5.18, 0.0, -1.45),
		Vector3(0.0, 12.0, 0.0),
		Vector3.ONE * 0.68,
		Vector3(0.42, 0.48, 0.42),
		Vector3(0.0, 0.24, 0.0)
	)
	_add_kenney_body(
		"PartsContainerB",
		KENNEY_CONTAINER_WIDE,
		Vector3(-5.12, 0.0, -2.05),
		Vector3(0.0, -8.0, 0.0),
		Vector3.ONE * 0.68,
		Vector3(0.42, 0.48, 0.42),
		Vector3(0.0, 0.24, 0.0)
	)
	_add_kenney_body(
		"PartsContainerC",
		KENNEY_CONTAINER_WIDE,
		Vector3(-4.72, 0.0, -2.58),
		Vector3(0.0, 20.0, 0.0),
		Vector3.ONE * 0.62,
		Vector3(0.38, 0.44, 0.38),
		Vector3(0.0, 0.22, 0.0)
	)

	# A small utility console anchors the energy corner next to the solar panel.
	_add_kenney_body(
		"EnergyConsole",
		KENNEY_TABLE_DISPLAY_SMALL,
		Vector3(4.02, 0.24, 1.42),
		Vector3(0.0, -104.0, 0.0),
		Vector3.ONE * 0.78,
		Vector3(0.66, 0.32, 0.64),
		Vector3(0.0, -0.07, 0.0)
	)

func _create_static_box(
	box_name: String,
	box_position: Vector3,
	box_size: Vector3,
	color: Color
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = box_position

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	box_mesh.material = material

	mesh_instance.mesh = box_mesh
	body.add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box_size
	collision_shape.shape = box_shape
	body.add_child(collision_shape)

	add_child(body)
	return body


func _create_visual_box(
	box_name: String,
	box_position: Vector3,
	box_size: Vector3,
	color: Color
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = box_name
	mesh_instance.position = box_position

	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	box_mesh.material = material

	mesh_instance.mesh = box_mesh
	add_child(mesh_instance)
	return mesh_instance



func _add_kenney_visual(
	prop_name: String,
	scene: PackedScene,
	prop_position: Vector3,
	prop_rotation: Vector3,
	prop_scale: Vector3
) -> Node3D:
	var prop := scene.instantiate() as Node3D
	prop.name = prop_name
	prop.position = prop_position
	prop.rotation_degrees = prop_rotation
	prop.scale = prop_scale
	add_child(prop)
	return prop


func _add_kenney_body(
	prop_name: String,
	scene: PackedScene,
	prop_position: Vector3,
	prop_rotation: Vector3,
	prop_scale: Vector3,
	collision_size: Vector3,
	collision_position: Vector3
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = prop_name
	body.position = prop_position
	body.rotation_degrees = prop_rotation

	var prop := scene.instantiate() as Node3D
	prop.scale = prop_scale
	body.add_child(prop)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = collision_size
	collision.position = collision_position
	collision.shape = shape
	body.add_child(collision)

	add_child(body)
	return body


func _add_quaternius_decor() -> void:
	# Solar panel moved to a dedicated energy/storage corner.
	var solar_body := StaticBody3D.new()
	solar_body.name = "WorkshopSolarPanel"
	solar_body.position = Vector3(4.82, 0.02, 1.28)
	solar_body.rotation_degrees = Vector3(0.0, -104.0, 0.0)

	var solar_panel := QUATERNIUS_SOLAR_PANEL.instantiate() as Node3D
	solar_panel.scale = Vector3.ONE * 0.64
	solar_body.add_child(solar_panel)

	var solar_collision := CollisionShape3D.new()
	var solar_shape := BoxShape3D.new()
	solar_shape.size = Vector3(0.95, 0.78, 1.08)
	solar_collision.position = Vector3(0.0, 0.36, 0.04)
	solar_collision.shape = solar_shape
	solar_body.add_child(solar_collision)

	add_child(solar_body)
