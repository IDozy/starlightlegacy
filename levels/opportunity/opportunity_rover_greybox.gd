extends Node3D
## Greybox Opportunity MER-B. Usa piezas provisionales del gemelo Spirit.
## Reemplazable sin afectar la historia. NO es una réplica dimensional.

const TWIN := preload("res://levels/spirit/spirit_rover_greybox.tscn")
var _twin: Node3D = null
var _warning: MeshInstance3D = null
var _light_observed := false
var _power_guard_enabled := false

func _ready() -> void:
	_twin = TWIN.instantiate() as Node3D
	_twin.name = "MERHardware"
	add_child(_twin)
	_warning = MeshInstance3D.new()
	_warning.name = "LowLightWarning"
	var geometry := BoxMesh.new()
	geometry.size = Vector3(0.30, 0.18, 0.17)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.47, 0.15)
	material.emission_enabled = true
	material.emission = Color(0.28, 0.11, 0.02)
	geometry.material = material
	_warning.mesh = geometry
	_warning.position = Vector3(0.0, 1.26, 0.2)
	_warning.visible = false
	add_child(_warning)

func has_six_wheels() -> bool:
	return _twin != null and _twin.has_method("has_six_wheels") and bool(_twin.call("has_six_wheels"))

func observe_low_light() -> void:
	_light_observed = true
	if _warning != null:
		_warning.visible = true

func protect_power_budget() -> void:
	_power_guard_enabled = true
	if _warning != null:
		_warning.scale = Vector3(1.2, 1.0, 1.0)
