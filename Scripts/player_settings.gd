# player_settings.gd
class_name PlayerSettings
extends Resource

## Customizable base appearance settings for a player
@export_category("Base Appearance")
@export var base_material: StandardMaterial3D = preload("res://materials/default_base.tres")
@export var base_color: Color = Color.WHITE:
	set(value):
		base_color = value.clamp()
@export_range(0.5, 2.0, 0.1) var base_scale: float = 1.0

## Path for saving/loading settings
const SAVE_PATH = "user://player_settings_%d.tres"

func save(player_id: int = 0) -> void:
	"""Save settings to file"""
	var err = ResourceSaver.save(self, SAVE_PATH % player_id)
	if err != OK:
		push_error("Failed to save player settings: ", error_string(err))

static func load_or_create(player_id: int = 0) -> PlayerSettings:
	"""Load settings or create new if they don't exist"""
	var path = SAVE_PATH % player_id
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path, "PlayerSettings", ResourceLoader.CACHE_MODE_REPLACE)
	else:
		var new_settings = PlayerSettings.new()
		new_settings.save(player_id)
		return new_settings

func apply_to_mesh(mesh_instance: MeshInstance3D) -> void:
	"""Apply these settings to a base mesh"""
	var mat = base_material.duplicate()
	mat.albedo_color = base_color
	mesh_instance.material_override = mat
	mesh_instance.scale = Vector3.ONE * base_scale

func validate() -> bool:
	"""Check if settings are valid"""
	if not is_instance_valid(base_material):
		push_warning("Invalid base material")
		return false
	if base_scale <= 0:
		push_warning("Base scale must be positive")
		return false
	return true
