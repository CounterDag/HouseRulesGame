# chess_knight.gd
class_name ChessKnight
extends BasePiece

func _ready():
	piece_type = "chessknight"
	super._ready()

func get_valid_moves(board: GameBoard, check_safety: bool = true) -> Array:
	var moves = []
	var patterns = [
		Vector2i(2, 1), Vector2i(2, -1),
		Vector2i(-2, 1), Vector2i(-2, -1),
		Vector2i(1, 2), Vector2i(1, -2),
		Vector2i(-1, 2), Vector2i(-1, -2)
	]
	
	for pattern in patterns:
		var target_pos = current_grid_pos + pattern
		if board.is_within_bounds(target_pos):
			var piece = board.get_piece_at(target_pos)
			if !piece || piece.team != team:
				moves.append({
					"position": target_pos,
					"is_attack": piece != null,
					"type": "move"
				})
	
	return moves
