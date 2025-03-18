# chess_queen.gd
class_name ChessQueen
extends BasePiece

func _ready():
	piece_type = "chessqueen"
	super._ready()

func get_valid_moves(board: GameBoard, check_safety: bool = true) -> Array:
	var moves = []
	var directions = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	
	for dir in directions:
		var current_pos = current_grid_pos + dir
		while board.is_within_bounds(current_pos):
			var piece = board.get_piece_at(current_pos)
			
			if piece:
				if piece.team != team:
					moves.append({
						"position": current_pos,
						"is_attack": true,
						"type": "move"
					})
				break
			
			moves.append({
				"position": current_pos,
				"is_attack": false,
				"type": "move"
			})
			current_pos += dir
	
	return moves
