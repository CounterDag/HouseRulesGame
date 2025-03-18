extends StaticBody3D

signal tile_interacted(grid_position: Vector2i)

@export var grid_position: Vector2i = Vector2i.ZERO
@export var base_material: StandardMaterial3D:
	set(value):
		base_material = value
		_apply_material_immediately()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready():
	print("TILE READY AT ", grid_position)
	_apply_material_immediately()
	# Ensure mesh exists
	if !mesh_instance.mesh:
		mesh_instance.mesh = BoxMesh.new()
		mesh_instance.mesh.size = Vector3.ONE

func _apply_material_immediately():
	if mesh_instance and base_material:
		print("Applying ", base_material.resource_path, " to ", grid_position)
		var mat = base_material.duplicate()
		mat.resource_local_to_scene = true
		mesh_instance.material_override = mat

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		tile_interacted.emit(grid_position)
