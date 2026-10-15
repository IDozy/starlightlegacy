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


func _fix_missing_materials(meshes: Array[MeshInstance3D]) -> void:
	# Respetar albedos y materiales incrustados en el GLB.
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = FALLBACK_COLOR
	fallback.roughness = 0.98
	for instance in meshes:
		if instance.material_override != null:
			continue
		for surface_index in range(instance.mesh.get_surface_count()):
			if instance.get_active_material(surface_index) == null:
				instance.set_surface_override_material(surface_index, fallback)


func _find_ground_mesh(meshes: Array[MeshInstance3D]) -> MeshInstance3D:
	var best: MeshInstance3D = null
	var best_score := -1.0
	for instance in meshes:
		var n := instance.name.to_lower()
		var mesh_name := instance.mesh.resource_name.to_lower()
		var label := n + " " + mesh_name
		if label.contains("horizonte") or label.contains("horizon") or label.contains("roca_") or label.contains("rock_"):
			continue
		var score := -1.0
		if label.contains("terreno") or label.contains("terrain"):
			score = 100.0
			if label.contains("av28") or label.contains("av33") or label.contains("av26"):
				score += 150.0
			elif label.contains("av24"):
				score += 100.0
		if score < 0.0:
			continue
		var bounds := instance.get_aabb().size
		score += minf(80.0, maxf(bounds.x, bounds.z) * 0.10)
		if score > best_score:
			best_score = score
			best = instance
	return best


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
