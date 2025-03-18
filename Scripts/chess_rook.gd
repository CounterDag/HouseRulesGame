# chess_rook.gd
class_name ChessRook
extends BasePiece

func _ready():
	piece_type = "chessrook"
	super._ready()

func get_valid_moves(board: GameBoard, check_safety: bool = true) -> Array:
	var moves = []
	var directions = [
		Vector2i.UP,    # Up
		Vector2i.DOWN,  # Down
		Vector2i.LEFT,  # Left
		Vector2i.RIGHT  # Right
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
