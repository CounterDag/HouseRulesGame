# check_detector.gd
class_name CheckDetector
extends Node

## Simplified check detection using existing piece movement logic

static func is_king_in_check(board: GameBoard, team: int) -> bool:
	var king_pos = _find_king(board, team)
	if king_pos == Vector2i(-1, -1):
		push_error("No king found for team %d" % team)
		return false
	
	return is_square_attacked(board, king_pos, team)

static func is_square_attacked(board: GameBoard, position: Vector2i, team: int) -> bool:
	for piece in board.get_all_pieces():
		if piece.team == team:
			continue
		
		# Get raw moves without check validation to prevent infinite recursion
		var moves = piece.get_valid_moves(board, false)
		for move in moves:
			if move.position == position && move.is_attack:
				return true
	return false

static func _find_king(board: GameBoard, team: int) -> Vector2i:
	for piece in board.get_all_pieces():
		if piece.piece_type == "king" && piece.team == team:
			return piece.current_grid_pos
	return Vector2i(-1, -1)

# Helper for checkmate detection (for future use)
static func get_attackers_of_king(board: GameBoard, team: int) -> Array:
	var attackers = []
	var king_pos = _find_king(board, team)
	
	for piece in board.get_all_pieces():
		if piece.team != team:
			var moves = piece.get_valid_moves(board, false)
			for move in moves:
				if move.position == king_pos && move.is_attack:
					attackers.append(piece)
	return attackers
