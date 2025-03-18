# chess_king.gd
class_name TheMonarch
extends BasePiece

## Emitted when castling is performed
signal castling_performed(side: String)

func _ready():
	piece_type = "themonarch"
	super._ready()

func get_valid_moves(board: GameBoard, check_safety: bool = true) -> Array:
	var moves = []
	var directions = [
		Vector2i.UP,        # Up
		Vector2i.DOWN,      # Down
		Vector2i.LEFT,      # Left
		Vector2i.RIGHT,     # Right
		Vector2i.UP + Vector2i.LEFT,    # Up-Left
		Vector2i.UP + Vector2i.RIGHT,   # Up-Right
		Vector2i.DOWN + Vector2i.LEFT,  # Down-Left
		Vector2i.DOWN + Vector2i.RIGHT  # Down-Right
	]
	
	# Standard king moves
	for dir in directions:
		var target_pos = current_grid_pos + dir
		if board.is_within_bounds(target_pos):
			var piece = board.get_piece_at(target_pos)
			if !piece || piece.team != team:
				moves.append({
					"position": target_pos,
					"is_attack": piece != null,
					"type": "move"
				})
	
	# Castling - kingside
	if _can_castle_kingside(board):
		moves.append({
			"position": current_grid_pos + Vector2i(2, 0),
			"type": "castling",
			"side": "kingside",
			"rook_position": current_grid_pos + Vector2i(3, 0)
		})
	
	# Castling - queenside
	if _can_castle_queenside(board):
		moves.append({
			"position": current_grid_pos + Vector2i(-2, 0),
			"type": "castling",
			"side": "queenside",
			"rook_position": current_grid_pos + Vector2i(-4, 0)
		})
	
	return moves

func _can_castle_kingside(board: GameBoard) -> bool:
	if has_moved: return false
	
	# Check rook position and status
	var rook_pos = current_grid_pos + Vector2i(3, 0)
	var rook = board.get_piece_at(rook_pos)
	if !rook || rook.piece_type != "rook" || rook.has_moved:
		return false
	
	# Check empty between spaces
	for x in [1, 2]:
		if board.has_piece_at(current_grid_pos + Vector2i(x, 0)):
			return false
	
	return true

func _can_castle_queenside(board: GameBoard) -> bool:
	if has_moved: return false
	
	# Check rook position and status
	var rook_pos = current_grid_pos + Vector2i(-4, 0)
	var rook = board.get_piece_at(rook_pos)
	if !rook || rook.piece_type != "rook" || rook.has_moved:
		return false
	
	# Check empty between spaces
	for x in [-1, -2, -3]:
		if board.has_piece_at(current_grid_pos + Vector2i(x, 0)):
			return false
	
	return true

func move_to(target_position: Vector2i) -> void:
	await super.move_to(target_position)
	
	# Update castling availability
	if !has_moved:
		has_moved = true
