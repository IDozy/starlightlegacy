@tool
extends Node3D
## Sojourner importado desde BlendSwap (CC0). El GLB exportado contiene
## tambien "ground" y "Rocks": se extrae SOLO la jerarquia SojournerRover.
## Mantener el rover procedural original como respaldo si falla la importacion.

const SOURCE_PATH: String = "res://assets/models/taller/Sojourner_v01.glb"
const SOURCE_ROVER_NODE: String = "SojournerRover"
const IMPORTED_NODE_NAME: String = "SojournerImportedModel"
const TARGET_HORIZONTAL_SIZE: float = 0.82
const WHEEL_CONTACT_Y: float = 0.0
# En el GLB original el extremo del brazo perforador apunta al eje +X.
# El recorrido hacia Yogi se hace hacia -Z local de RoverVisual.
const MODEL_YAW_DEGREES: float = 90.0
const LEGACY_PARTS := [
	"Body", "SolarPanel", "APXS",
	"WheelFL", "WheelML", "WheelRL",
	"WheelFR", "WheelMR", "WheelRR",
]


func _ready() -> void:
	# No se guardan instancias temporales en el .tscn; se generan tanto
	# en el editor (@tool) como durante el juego.
	_show_legacy(true)
	_load_imported_rover()


func _load_imported_rover() -> void:
	if not ResourceLoader.exists(SOURCE_PATH):
		push_warning("Sojourner: no se encuentra el GLB; se usa el rover provisional.")
		return

	var source := load(SOURCE_PATH) as PackedScene
	if source == null:
		push_warning("Sojourner: el GLB no pudo cargarse; se usa el rover provisional.")
		return

	var container := source.instantiate() as Node3D
	if container == null:
		push_warning("Sojourner: no se pudo crear el GLB; se usa el rover provisional.")
		return

	var rover := container.get_node_or_null(SOURCE_ROVER_NODE) as Node3D
	if rover == null:
		container.free()
		push_warning("Sojourner: falta SojournerRover en el GLB; se usa el modelo provisional.")
		return

	# Solo SojournerRover sale del GLB. Ground y Rocks se liberan sin
	# adjuntarse al nivel; asi no duplicamos el terreno de Ares Vallis.
	container.remove_child(rover)
	add_child(rover)
	container.free()
	rover.name = IMPORTED_NODE_NAME

	var bounds := _model_bounds(rover)
	var largest_dimension: float = maxf(bounds.size.x, bounds.size.z)
	if largest_dimension <= 0.0001:
		remove_child(rover)
		rover.free()
		push_warning("Sojourner: malla vacia; se usa el modelo provisional.")
		return

	# Las coordenadas del .blend original incluyen un offset de escenario
	# y escala propia. Ajustar la geometria al soporte del reto APXS,
	# conservando todas las ruedas, brazos y piezas en sus relaciones.
	var factor: float = TARGET_HORIZONTAL_SIZE / largest_dimension
	var center := bounds.position + bounds.size * 0.5
	# Orientacion original: +X = frente (brazo perforador).
	# Girar +90 grados sobre Y convierte ese frente en -Z, hacia Yogi.
	var yaw_basis := Basis(Vector3.UP, deg_to_rad(MODEL_YAW_DEGREES))
	var turned_center := yaw_basis * center
	rover.rotation_degrees = Vector3(0.0, MODEL_YAW_DEGREES, 0.0)
	rover.scale = Vector3.ONE * factor
	rover.position = Vector3(
		-turned_center.x * factor,
		WHEEL_CONTACT_Y - bounds.position.y * factor,
		-turned_center.z * factor
	)
	_apply_missing_material_palette(rover)
	_show_legacy(false)
	print("[Sojourner] Modelo GLB integrado. Piezas de suelo/rocas excluidas. Tamano: ",
		rover.scale, " / base Y: ", WHEEL_CONTACT_Y)



# El GLB v01 contiene nombres de 9 materiales, pero en glTF omite los
# factores PBR y no incluye imagenes. Godot interpreta las superficies
# sin color como blancas: se restauran tonos coherentes sin editar mallas.
# Si una version futura ya incorpora texturas, se respeta su material.
func _apply_missing_material_palette(rover: Node3D) -> void:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(rover, meshes)
	var replacements: Dictionary = {}
	var replaced_count := 0
	for instance in meshes:
		for surface_index in range(instance.mesh.get_surface_count()):
			var source_material := instance.mesh.surface_get_material(surface_index)
			# Una nueva exportacion que si tenga textura no debe recolorearse.
			if source_material is BaseMaterial3D:
				var base := source_material as BaseMaterial3D
				if base.albedo_texture != null:
					continue
			var palette_key := ""
			if source_material != null:
				palette_key = source_material.resource_name.to_lower()
			var settings := _palette_for_material(palette_key)
			if settings.is_empty():
				# Algunos importadores pierden el nombre del material; el GLB v01
				# mantiene nombres de piezas y orden de superficies estables.
				palette_key = _fallback_palette_key(instance.name, surface_index)
				settings = _palette_for_material(palette_key)
			if settings.is_empty():
				continue
			if not replacements.has(palette_key):
				var restored := StandardMaterial3D.new()
				restored.resource_name = "SL_" + palette_key
				restored.albedo_color = settings["color"]
				restored.metallic = settings["metallic"]
				restored.roughness = settings["roughness"]
				restored.vertex_color_use_as_albedo = false
				replacements[palette_key] = restored
			instance.set_surface_override_material(surface_index, replacements[palette_key])
			replaced_count += 1
	print("[Sojourner] Materiales reparados: ", replaced_count, " superficies. ",
		"No se cambio ninguna malla.")


func _fallback_palette_key(mesh_name: String, surface_index: int) -> String:
	if mesh_name == IMPORTED_NODE_NAME or mesh_name == "SojournerRover":
		match surface_index:
			0:
				return "rover_metal"
			1:
				return "rover_gold_flat"
			2:
				return "white_plastic"
			3:
				return "solarpanels"
			4:
				return "rover_gold_foil"
	if mesh_name.begins_with("RoverFrontWheel."):
		return "rover_metal_wheels" if surface_index == 1 else "rover_metal"
	if mesh_name.begins_with("RoverWheelsConnector."):
		return "black_plastic" if surface_index == 1 else "rover_metal"
	if mesh_name.begins_with("Rover"):
		return "rover_metal"
	return ""


func _palette_for_material(source_name: String) -> Dictionary:
	# Los nombres proceden directamente de los materiales del GLB v01.
	match source_name:
		"rover_metal":
			return {"color": Color(0.38, 0.36, 0.32), "metallic": 0.42, "roughness": 0.65}
		"rover_metal_wheels":
			return {"color": Color(0.24, 0.23, 0.22), "metallic": 0.28, "roughness": 0.82}
		"black_plastic":
			return {"color": Color(0.11, 0.12, 0.13), "metallic": 0.06, "roughness": 0.84}
		"rover_gold_flat":
			return {"color": Color(0.68, 0.49, 0.24), "metallic": 0.20, "roughness": 0.76}
		"white_plastic":
			return {"color": Color(0.77, 0.73, 0.64), "metallic": 0.0, "roughness": 0.79}
		"solarpanels":
			return {"color": Color(0.045, 0.095, 0.19), "metallic": 0.08, "roughness": 0.45}
		"rover_gold_foil":
			return {"color": Color(0.78, 0.58, 0.27), "metallic": 0.34, "roughness": 0.62}
	return {}


## Corrige la altura del aspecto visual usando el terreno real debajo de
## las seis ruedas, NO la altura del centro del StaticBody (que puede caer
## sobre una pendiente distinta). No modifica hitboxes ni mecanica APXS.
## Se llama tras alinear el reto y en cada paso W/S del jugador.
func snap_to_terrain() -> void:
	if not is_inside_tree():
		return
	var stage := get_parent().get_parent()
	if stage == null:
		return
	var landscape := stage.get_node_or_null("AresVallisLandscape_v33")
	if landscape == null or not landscape.has_method("ground_height_at"):
		return
	var rover := get_node_or_null(IMPORTED_NODE_NAME) as Node3D
	if rover == null:
		return
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(rover, meshes)
	var corrections: Array[float] = []
	for wheel in meshes:
		if not wheel.name.begins_with("RoverFrontWheel."):
			continue
		var local_box := wheel.get_aabb()
		# El minimo vertical de la llanta se calcula con las ocho esquinas
		# transformadas, sin depender de la orientacion de su malla.
		var min_y := INF
		var ground_xz := wheel.global_transform * (local_box.position + local_box.size * 0.5)
		for idx in range(8):
			var local_corner := local_box.position + Vector3(
				local_box.size.x if (idx & 1) != 0 else 0.0,
				local_box.size.y if (idx & 2) != 0 else 0.0,
				local_box.size.z if (idx & 4) != 0 else 0.0
			)
			var world_corner := wheel.global_transform * local_corner
			min_y = minf(min_y, world_corner.y)
		var ground_y: float = float(landscape.call("ground_height_at", ground_xz.x, ground_xz.z))
		corrections.append(ground_y - min_y)
	if corrections.size() != 6:
		push_warning("Sojourner: no encontre las seis ruedas para apoyar el modelo.")
		return
	# La suspension importada tiene ruedas a alturas ligeramente distintas;
	# el promedio minimiza la separacion visible sin desmontarlas.
	var correction := 0.0
	for amount in corrections:
		correction += amount
	correction /= float(corrections.size())
	position.y += clampf(correction - 0.005, -0.15, 0.15)



func _show_legacy(should_show: bool) -> void:
	for part_name in LEGACY_PARTS:
		var node := get_node_or_null(part_name) as Node3D
		if node != null:
			node.visible = should_show


func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)


func _model_bounds(rover: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(rover, meshes)
	var result := AABB()
	var initialized := false
	var inverse_root := rover.global_transform.affine_inverse()
	for instance in meshes:
		var box := instance.get_aabb()
		var relative_transform := inverse_root * instance.global_transform
		for corner_index in range(8):
			var point := box.position + Vector3(
				box.size.x if (corner_index & 1) != 0 else 0.0,
				box.size.y if (corner_index & 2) != 0 else 0.0,
				box.size.z if (corner_index & 4) != 0 else 0.0
			)
			var transformed_point := relative_transform * point
			if not initialized:
				result = AABB(transformed_point, Vector3.ZERO)
				initialized = true
			else:
				result = result.expand(transformed_point)
	return result
