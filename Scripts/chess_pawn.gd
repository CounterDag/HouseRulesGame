# chess_pawn.gd
class_name ChessPawn
extends BasePiece

# Pawn-specific properties
var en_passant_vulnerable: bool = false
var promotion_ready: bool = false

func _ready():
	piece_type = "chesspawn"
	super._ready()  # Call base class initialization

func get_valid_moves(board: GameBoard, check_safety: bool = true) -> Array:
	var moves = []
	var forward = _get_forward_direction()
	var current_pos = current_grid_pos
	
	# Standard movement
	var one_forward = current_pos + forward
	if board.is_within_bounds(one_forward) && !board.has_piece_at(one_forward):
		moves.append(_create_move_data(one_forward, false))
		
		# Initial double move
		if !has_moved:
			var two_forward = current_pos + (forward * 2)
			if board.is_within_bounds(two_forward) && !board.has_piece_at(two_forward):
				moves.append(_create_move_data(two_forward, false, true))

	# Captures
	var capture_directions = [forward + Vector2i.LEFT, forward + Vector2i.RIGHT]
	for dir in capture_directions:
		var target_pos = current_pos + dir
		if board.is_within_bounds(target_pos):
			var piece = board.get_piece_at(target_pos)
			if piece && piece.team != team:
				moves.append(_create_move_data(target_pos, true))
			
			# En passant detection
			if _is_en_passant_available(target_pos, board):
				moves.append(_create_move_data(target_pos, true, false, true))

	return moves

func move_to(target_position: Vector2i) -> void:
	var initial_pos = current_grid_pos
	await super.move_to(target_position)  # Calls base class movement
	
	# Pawn-specific logic
	en_passant_vulnerable = (abs(target_position.y - initial_pos.y) == 2)
	
	# Promotion check
	var promotion_rank = 7 if team == 0 else 0
	if current_grid_pos.y == promotion_rank:
		promotion_ready = true

# Helper methods
func _get_forward_direction() -> Vector2i:
	return Vector2i.DOWN if team == 0 else Vector2i.UP

func _create_move_data(pos: Vector2i, is_attack: bool, 
					 is_double: bool = false, is_en_passant: bool = false) -> Dictionary:
	return {
		"position": pos,
		"is_attack": is_attack,
		"type": "en_passant" if is_en_passant else "move",
		"is_double": is_double,
		"promotion": false
	}

func _is_en_passant_available(target_pos: Vector2i, board: GameBoard) -> bool:
	# Implementation requires tracking last moved pawn in GameManager
	return false  # Placeholder
