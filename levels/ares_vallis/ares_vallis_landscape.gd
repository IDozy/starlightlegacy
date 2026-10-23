extends Node3D
## Paisaje Ares Vallis v33 importado desde Blender.
## No altera los nodos del recuerdo ni los descubrimientos de Pathfinder/Sojourner.

const LANDSCAPE_SCENE: PackedScene = preload("res://assets/models/taller/Starlight_AresVallis_Desarrollo_v33.blend.glb")
const TERRAIN_QUERY_MASK: int = 4 # Capa 3; la colision tambien usa la capa 1.
const MAX_TRIANGLE_COLLISION_SURFACES: int = 128
const FALLBACK_COLOR = Color(0.59, 0.34, 0.24)

var _terrain_mesh: MeshInstance3D = null
var _terrain_body: StaticBody3D = null
var _using_fallback: bool = false


func _ready() -> void:
	var landscape := LANDSCAPE_SCENE.instantiate() as Node3D
	if landscape == null:
		push_error("Ares Vallis: no se pudo instanciar el GLB v33.")
		_create_fallback_floor()
		return

	landscape.name = "AresVallis_v33_Visual"
	add_child(landscape)
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(landscape, meshes)
	_disable_imported_lighting(landscape)
	_fix_missing_materials(meshes)
	_terrain_mesh = _find_ground_mesh(meshes)

	if _terrain_mesh == null or not _create_terrain_collision(_terrain_mesh):
		push_warning("Ares Vallis v33: no se identifico la malla del suelo. Se usa un piso temporal para evitar caidas.")
		_create_fallback_floor()


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			output.append(instance)
	for child in node.get_children():
		_collect_meshes(child, output)


func _disable_imported_lighting(node: Node) -> void:
	# La iluminacion del nivel la controla ares_vallis.gd.
	if node is Light3D:
		(node as Light3D).visible = false
	elif node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_disable_imported_lighting(child)


func _new_mars_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0
	# Los atributos AV32_COLOR/AV33_COLOR de Blender se renderizan
	# de manera distinta en el importador GLB: usar un color estable.
	material.vertex_color_use_as_albedo = false
	return material


func _is_replaced_blender_mesh(name: String) -> bool:
	# Blender v33 creo COPIAS y oculto los originales, pero el GLB puede
	# incluir tambien esas fuentes. No dibujar ambas superficies.
	if name.begins_with("av33_"):
		return false
	if name.begins_with("av28_"):
		return false
	if name.begins_with("roca_gran_") or name.begins_with("roca_med_"):
		return false
	for old_prefix in [
		"av20_aresvallis_terreno", "av24_aresvallis_terreno",
		"av25_", "av26_", "av27_", "av29_", "av30_", "av31_", "av32_"
	]:
		if name.begins_with(old_prefix):
			return true
	return false


func _fix_missing_materials(meshes: Array[MeshInstance3D]) -> void:
	# Godot GL Compatibility puede mostrar partes casi blancas con los
	# materiales de atributos procedurales exportados desde Blender.
	# Sustituir SOLO materiales del paisaje, preservando las rocas v20
	# y las formaciones de roca que ya se veian bien.
	var sand := _new_mars_material(Color(0.56, 0.32, 0.23))
	var seam := _new_mars_material(Color(0.54, 0.31, 0.23))
	var distant := _new_mars_material(Color(0.60, 0.38, 0.30))
	var rock := _new_mars_material(Color(0.43, 0.25, 0.19))
	var fallback := _new_mars_material(FALLBACK_COLOR)
	var hidden_count := 0
	var recolored_count := 0

	for instance in meshes:
		var name := instance.name.to_lower()
		var label := name + " " + instance.mesh.resource_name.to_lower()
		if _is_replaced_blender_mesh(name):
			instance.visible = false
			hidden_count += 1
			continue

		var override_material: StandardMaterial3D = null
		if label.contains("av28_") and (label.contains("terreno") or label.contains("terrain")):
			override_material = sand
		elif name.begins_with("av33_"):
			if label.contains("cordillera") or label.contains("fondo") or label.contains("posterior"):
				override_material = distant
			elif label.contains("horizonte") or label.contains("cresta_continua"):
				override_material = seam
			elif label.contains("acantilado"):
				override_material = rock
			elif label.contains("terreno"):
				override_material = sand
		elif label.contains("terreno") and not label.contains("roca"):
			override_material = sand

		if override_material != null:
			instance.material_override = override_material
			recolored_count += 1
		elif instance.material_override == null:
			for index in range(instance.mesh.get_surface_count()):
				if instance.get_active_material(index) == null:
					instance.set_surface_override_material(index, fallback)
	print("[Ares v33] Mallas antiguas ocultas: ", hidden_count,
		" | Materiales de paisaje estabilizados: ", recolored_count)


func _find_ground_mesh(meshes: Array[MeshInstance3D]) -> MeshInstance3D:
	# La colision debe nacer del AV28 aprobado, no de un horizonte,
	# copia temporal o una malla historica de dimensiones parecidas.
	for instance in meshes:
		var name := instance.name.to_lower()
		if name.begins_with("av28_") and name.contains("terreno"):
			return instance
	# Los nombres de nodos pueden cambiar por el importador GLB.
	for instance in meshes:
		var name := instance.name.to_lower()
		var mesh_name := instance.mesh.resource_name.to_lower()
		if (name.contains("av28_") or mesh_name.contains("av28_")) and (
			name.contains("terreno") or mesh_name.contains("terreno")
		):
			return instance
	return null


func _create_terrain_collision(instance: MeshInstance3D) -> bool:
	var mesh := instance.mesh
	if mesh == null or mesh.get_surface_count() > MAX_TRIANGLE_COLLISION_SURFACES:
		return false
	var shape := mesh.create_trimesh_shape()
	if shape == null:
		return false

	# La colision hereda la transformacion original del mesh importado.
	var body := StaticBody3D.new()
	body.name = "TerrainCollision"
	body.collision_layer = 1 | TERRAIN_QUERY_MASK
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.name = "TerrainShape"
	collision.shape = shape
	body.add_child(collision)
	instance.add_child(body)
	_terrain_body = body
	return true


func _create_fallback_floor() -> void:
	_using_fallback = true
	var body := StaticBody3D.new()
	body.name = "TemporaryWalkableFloor"
	body.collision_layer = 1 | TERRAIN_QUERY_MASK
	var shape_node := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(38.0, 0.20, 34.0)
	shape_node.shape = floor_shape
	body.position = Vector3(0.0, -0.10, -2.0)
	body.add_child(shape_node)
	add_child(body)
	_terrain_body = body


func ground_height_at(world_x: float, world_z: float) -> float:
	if _terrain_body == null or not is_inside_tree():
		return 0.0
	var origin := Vector3(world_x, 1000.0, world_z)
	var end := Vector3(world_x, -1000.0, world_z)
	var query := PhysicsRayQueryParameters3D.create(origin, end, TERRAIN_QUERY_MASK)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.has("position"):
		var point: Vector3 = result["position"]
		return point.y
	return 0.0


func using_fallback_floor() -> bool:
	return _using_fallback
