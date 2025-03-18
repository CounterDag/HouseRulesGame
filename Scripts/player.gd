# player.gd
class_name Player
extends Resource

@export var team: int = 0
@export var color: Color = Color.WHITE
@export var material: Material  # Assign in Inspector
@export var piece_selection: Array[PackedScene] = []

var score: int = 0
var remaining_time: float = 0.0

func get_piece_selection() -> Array[PackedScene]:
	return piece_selection.duplicate()

func reset():
	score = 0
	remaining_time = 0.0
