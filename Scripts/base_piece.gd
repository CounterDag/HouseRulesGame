# base_piece.gd
class_name BasePiece
extends Node3D

## Emitted when the piece is selected
signal piece_selected(piece: BasePiece)
## Emitted after movement completes
signal piece_moved(new_position: Vector2i)
## Emitted when captured
signal piece_captured

@export_category("Core Properties")
@export var piece_type: String = "base"
@export var team: int = 0  # 0 = White, 1 = Black

@export_category("Visual Components")
@export var body_mesh: Mesh
@export var eyes_mesh: Mesh
@export var base_mesh: Mesh
@export var team_material: StandardMaterial3D

@export_category("Movement Settings")
@export var move_height: float = 0.5
@export var move_duration: float = 0.3

var current_grid_pos: Vector2i
var has_moved: bool = false
var is_selected: bool = false:
	set(value):
		is_selected = value
		update_material()

@onready var body: MeshInstance3D = $Body
@onready var eyes: MeshInstance3D = $Eyes
@onready var base: MeshInstance3D = $PieceBase/Base
@onready var collision: CollisionShape3D = $StaticBody3D/CollisionShape3D

func _ready():
	initialize_meshes()
	update_material()

func initialize_meshes():
	body.mesh = body_mesh
	eyes.mesh = eyes_mesh
	base.mesh = base_mesh
	if body_mesh:
		collision.shape = body_mesh.create_trimesh_shape()

func apply_appearance(team_mat: Material, base_settings: Resource):
	var body_mat = team_mat.duplicate()
	body_mat.albedo_color = body_mat.albedo_color
	body.material_override = body_mat
	
	var base_mat = base_settings.base_material.duplicate()
	base_mat.albedo_color = base_settings.base_color
	base.material_override = base_mat
	base.scale = Vector3.ONE * base_settings.base_scale
	
	var eyes_mat = base_settings.base_material.duplicate()
	eyes_mat.albedo_color = base_settings.base_color
	eyes.material_override = base_mat
	eyes.scale = Vector3.ONE * base_settings.base_scale

func update_material():
	if is_selected:
		body.material_override = team_material.duplicate()
	else:
		body.material_override = team_material

func move_to(target_position: Vector2i) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_QUAD)
	var target_world_pos = get_parent().grid_to_world(target_position)
	
	tween.tween_property(self, "position:y", move_height, move_duration/3)
	tween.parallel().tween_property(self, "global_position:x", target_world_pos.x, move_duration)
	tween.parallel().tween_property(self, "global_position:z", target_world_pos.z, move_duration)
	tween.tween_property(self, "position:y", 0.0, move_duration/3)
	
	await tween.finished
	current_grid_pos = target_position
	has_moved = true
	piece_moved.emit(target_position)

func capture():
	piece_captured.emit()
	queue_free()

func get_data() -> Dictionary:
	return {
		"type": piece_type,
		"team": team,
		"position": current_grid_pos,
		"has_moved": has_moved
	}

func get_valid_moves(board: GameBoard, check_safety: bool = true) -> Array:
	return []

func _on_input_event(_camera, event: InputEvent, _pos, _norm, _shape):
	if event is InputEventMouseButton and event.pressed:
		piece_selected.emit(self)
