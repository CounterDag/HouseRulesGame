class_name GameBoard
extends Node3D

## Signals
signal tile_interacted(grid_position: Vector2i)
signal piece_added(piece: BasePiece)

## Board Configuration
@export_category("Board Settings")
@export var grid_size: Vector2i = Vector2i(8, 8)
@export var tile_scene: PackedScene
@export var tile_spacing: float = 2.0

@export_category("Materials")
@export var light_tile_material: StandardMaterial3D
@export var dark_tile_material: StandardMaterial3D

@export_category("JSON Setup")
@export var default_setup_path: String = "res://setups/standard.json"

## Internal State
var _pieces: Dictionary = {}  # Key: Vector2i, Value: BasePiece
var _tiles: Dictionary = {}    # Key: Vector2i, Value: StaticBody3D

#region Core Functions
func _ready():
	print("Initializing game board...")
	_create_tile_grid()
	_position_board_center()
	load_setup_from_json()

func _create_tile_grid():
	for x in grid_size.x:
		for y in grid_size.y:
			var tile = tile_scene.instantiate()
			tile.grid_position = Vector2i(x, y)
			
			tile.position = Vector3(
				x * tile_spacing,
				0,
				y * tile_spacing
			)
			
			if (x + y) % 2 == 0:
				tile.base_material = light_tile_material
			else:
				tile.base_material = dark_tile_material
				
			tile.tile_interacted.connect(_on_tile_interacted)
			_tiles[Vector2i(x, y)] = tile
			add_child(tile)

func _position_board_center():
	var offset = Vector3(
		(grid_size.x - 1) * tile_spacing / 2.0,
		0,
		(grid_size.y - 1) * tile_spacing / 2.0
	)
	position = -offset
#endregion

#region Piece Management
func place_piece(piece_type: String, team: String, grid_position: Vector2i):
	if !is_within_bounds(grid_position):
		push_error("Invalid position for piece: ", grid_position)
		return
	
	var piece_path = "res://Pieces/%s.tscn" % piece_type.to_lower()
	if !ResourceLoader.exists(piece_path):
		push_error("Missing piece scene: ", piece_path)
		return
	
	var piece_scene = load(piece_path).instantiate()
	var material = load("res://Materials/%s_piece_material.tres" % team.to_lower())
	
	if piece_scene is BasePiece:
		piece_scene.initialize(team, material)
		add_piece(piece_scene, grid_position)
		piece_scene.rotate_y(deg_to_rad(180)) if team == "black" else null
	else:
		push_error("Invalid piece type at ", grid_position)
		piece_scene.queue_free()

func add_piece(piece: BasePiece, grid_position: Vector2i):
	if has_piece_at(grid_position):
		push_warning("Overwriting piece at: ", grid_position)
	
	piece.position = grid_to_world(grid_position)
	piece.current_grid_pos = grid_position
	_pieces[grid_position] = piece
	add_child(piece)
	piece_added.emit(piece)

func move_piece(from: Vector2i, to: Vector2i):
	if !has_piece_at(from):
		push_error("No piece at position: ", from)
		return
	
	var piece = _pieces[from]
	_pieces.erase(from)
	_pieces[to] = piece
	piece.current_grid_pos = to
#endregion

#region JSON Setup
func load_setup_from_json(file_path: String = default_setup_path) -> bool:
	if !FileAccess.file_exists(file_path):
		push_error("Setup file not found: ", file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	
	var parse_error = json.parse(file.get_as_text())
	if parse_error != OK:
		push_error("JSON parse error: ", json.get_error_message())
		return false
	
	var setup_data = json.get_data()
	
	if !setup_data.has("team") || !setup_data.has("pieces"):
		push_error("Invalid setup format")
		return false
	
	var team = setup_data.team.to_lower()
	if !["white", "black"].has(team):
		push_error("Invalid team in setup: ", team)
		return false
	
	reset_board()
	
	for piece_entry in setup_data.pieces:
		var validation = _validate_piece_entry(piece_entry, team)
		if !validation.valid:
			push_warning("Skipping invalid entry: ", validation.message)
			continue
		
		var grid_pos = slot_to_grid_position(piece_entry.slot, team)
		place_piece(piece_entry.type, team, grid_pos)
	
	return true

func slot_to_grid_position(slot: int, team: String) -> Vector2i:
	if slot < 1 || slot > grid_size.x * grid_size.y:
		push_error("Invalid slot number: ", slot)
		return Vector2i(-1, -1)
	
	var zero_based = slot - 1
	var x: int
	var y: int
	
	match team.to_lower():
		"white":
			x = zero_based % grid_size.x
			y = zero_based / grid_size.x
		"black":
			x = grid_size.x - 1 - (zero_based % grid_size.x)
			y = grid_size.y - 1 - (zero_based / grid_size.x)
		_:
			push_error("Invalid team for slot conversion")
			return Vector2i(-1, -1)
	
	return Vector2i(x, y)

func _validate_piece_entry(entry: Dictionary, team: String) -> Dictionary:
	var result = {valid = false, message = ""}
	
	if !entry.has("slot") || typeof(entry.slot) != TYPE_INT:
		result.message = "Missing or invalid slot"
		return result
	
	if !entry.has("type") || typeof(entry.type) != TYPE_STRING:
		result.message = "Missing or invalid type"
		return result
	
	if entry.slot < 1 || entry.slot > grid_size.x * grid_size.y:
		result.message = "Slot out of range (1-%d)" % (grid_size.x * grid_size.y)
		return result
	
	var piece_path = "res://Pieces/%s.tscn" % entry.type.to_lower()
	if !ResourceLoader.exists(piece_path):
		result.message = "Invalid piece type: " + entry.type
		return result
	
	result.valid = true
	return result
#endregion

#region Utility Functions
func world_to_grid(world_position: Vector3) -> Vector2i:
	var local_pos = to_local(world_position)
	return Vector2i(
		round(local_pos.x / tile_spacing),
		round(local_pos.z / tile_spacing)
	)

func grid_to_world(grid_position: Vector2i) -> Vector3:
	return Vector3(
		grid_position.x * tile_spacing,
		0,
		grid_position.y * tile_spacing
	)

func is_within_bounds(grid_position: Vector2i) -> bool:
	return grid_position.x >= 0 && grid_position.x < grid_size.x \
		&& grid_position.y >= 0 && grid_position.y < grid_size.y

func reset_board():
	for piece in _pieces.values():
		piece.queue_free()
	_pieces.clear()

func has_piece_at(grid_position: Vector2i) -> bool:
	return _pieces.has(grid_position)

func get_piece_at(grid_position: Vector2i) -> BasePiece:
	return _pieces.get(grid_position)

func _on_tile_interacted(grid_position: Vector2i):
	tile_interacted.emit(grid_position)
#endregion
