# input_manager.gd
class_name InputManager
extends Node

## Emitted when a board tile is selected
signal tile_selected(grid_position: Vector2i)
## Emitted when a game piece is selected
signal piece_selected(piece: BasePiece)
## Emitted when selection is cleared
signal selection_cleared
## Emitted when right-click/context action occurs
signal context_menu_requested(position: Vector2)

@export_category("Camera Settings")
@export var game_camera: Camera3D
@export var fallback_to_active_camera: bool = true

@export_category("Input Settings")
@export var mouse_button: MouseButton = MOUSE_BUTTON_LEFT
@export var context_button: MouseButton = MOUSE_BUTTON_RIGHT
@export var touch_as_mouse: bool = true
@export var double_click_threshold: float = 0.3

var selected_piece: BasePiece = null
var _last_click_time: float = 0.0
var _registered_pieces: Array[BasePiece] = []

func _ready():
	if !game_camera && fallback_to_active_camera:
		game_camera = get_viewport().get_camera_3d()
	assert(game_camera != null, "InputManager: No camera assigned and no active camera found!")

func _unhandled_input(event: InputEvent):
	if _handle_context_menu(event):
		return
	if _handle_selection(event):
		get_viewport().set_input_as_handled()

func _handle_context_menu(event: InputEvent) -> bool:
	if event is InputEventMouseButton && event.button_index == context_button && event.pressed:
		context_menu_requested.emit(event.position)
		return true
	return false

func _handle_selection(event: InputEvent) -> bool:
	var is_mouse_event := event is InputEventMouseButton
	var is_touch_event := event is InputEventScreenTouch
	
	if !(is_mouse_event || is_touch_event):
		return false
	
	var pressed := false
	var position := Vector2.ZERO
	
	if is_mouse_event:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != mouse_button:
			return false
		pressed = mouse_event.pressed
		position = mouse_event.position
	else:
		var touch_event := event as InputEventScreenTouch
		pressed = touch_event.pressed
		position = touch_event.position
	
	var now := Time.get_ticks_msec() / 1000.0
	var double_click := pressed && (now - _last_click_time) < double_click_threshold
	_last_click_time = now
	
	if pressed:
		return _process_selection_attempt(position, double_click)
	return false

func _process_selection_attempt(screen_pos: Vector2, double_click: bool) -> bool:
	var result := _raycast_from_screen(screen_pos)
	
	if result.is_empty():
		if double_click:
			_clear_selection()
		return false
	
	var collider = result.collider
	
	if collider is BasePiece:
		var piece := collider as BasePiece
		selected_piece = piece
		piece_selected.emit(piece)
		return true
	elif collider.is_in_group("board_tile"):
		if collider.has_method("get_grid_position"):
			var grid_pos: Vector2i = collider.get_grid_position()
			tile_selected.emit(grid_pos)
			return true
	
	return false

func _raycast_from_screen(screen_pos: Vector2) -> Dictionary:
	var params := PhysicsRayQueryParameters3D.new()
	params.collision_mask = 0b1  # Ensure tiles/pieces are on correct layer
	
	var ray_origin := game_camera.project_ray_origin(screen_pos)
	var ray_dir := game_camera.project_ray_normal(screen_pos)
	params.from = ray_origin
	params.to = ray_origin + ray_dir * game_camera.far
	
	return get_viewport().world_3d.direct_space_state.intersect_ray(params)

func register_piece(piece: BasePiece):
	if piece in _registered_pieces:
		return
	
	piece.piece_selected.connect(_on_piece_selected)
	_registered_pieces.append(piece)
	piece.tree_exiting.connect(_on_piece_exiting.bind(piece))

func _on_piece_selected(piece: BasePiece):
	selected_piece = piece
	piece_selected.emit(piece)

func _on_piece_exiting(piece: BasePiece):
	_registered_pieces.erase(piece)
	if selected_piece == piece:
		_clear_selection()

func _clear_selection():
	selected_piece = null
	selection_cleared.emit()

func set_input_active(active: bool):
	set_process_unhandled_input(active)
	if !active:
		_clear_selection()
