# game_manager.gd
class_name GameManager
extends Node

## Core game states
enum GameState {
	LOADING_RESOURCES,
	PLAYER_SETUP,        # Piece selection/placement
	TURN_TRANSITION,     # Between players
	PLAYER_TURN,         # Active player's turn
	MOVE_ANIMATION,      # Piece movement in progress
	GAME_OVER            # Victory/defeat state
}

## Configuration
@export var max_players := 2
@export var starting_player := 0
@export var turn_timeout := 30.0
@export var player_resource: Player

## Game state
var current_state: GameState = GameState.LOADING_RESOURCES
var players: Array[Player] = []
var active_player_index := 0
var move_history := []
var local_player_settings: PlayerSettings

## System references
@onready var board: GameBoard = %Board
@onready var input_manager: InputManager = $InputManager
@onready var timer: Timer = $TurnTimer
@onready var ui: Control = %GameUI

## Signals
signal game_ready
signal player_turn_started(player_index: int)
signal player_turn_ended(player_index: int)
signal move_executed(move_data: Dictionary)
signal game_over(result: Dictionary)

func _ready():
	initialize_game()

func initialize_game():
	# Player initialization
	players = []
	for i in max_players:
		var new_player = player_resource.duplicate()
		new_player.team = i
		players.append(new_player)
	
	# Board setup
	if board:
		board.tile_interacted.connect(_on_tile_selected)
		board.piece_added.connect(_on_piece_added)
		board.initialize_board()
		_register_existing_pieces()
	else:
		push_error("Board reference missing!")
	
	# Input system setup
	input_manager.piece_selected.connect(_on_piece_selected)
	input_manager.tile_selected.connect(_on_tile_selected)
	# In GameManager.initialize_game()
	board.tile_interacted.connect(_on_tile_selected)
	board.piece_added.connect(_on_piece_added)
	
	# Player customization
	local_player_settings = load_player_settings()
	
	change_state(GameState.PLAYER_SETUP)
	game_ready.emit()

func load_player_settings() -> PlayerSettings:
	var settings = PlayerSettings.new()
	# Add logic to load from save file
	return settings

func _register_existing_pieces():
	for piece in board.get_all_pieces():
		_register_piece(piece)

func _on_piece_added(piece: BasePiece):
	_register_piece(piece)

func _register_piece(piece: BasePiece):
	# Connect input signals
	input_manager.register_piece(piece)
	
	# Apply visual customization
	var team_mat = players[piece.team].team_material
	var base_settings = local_player_settings if piece.team == 0 else players[piece.team].base_settings
	piece.apply_appearance(team_mat, base_settings)

func change_state(new_state: GameState):
	exit_state(current_state)
	enter_state(new_state)
	current_state = new_state

func enter_state(state: GameState):
	match state:
		GameState.PLAYER_SETUP:
			ui.show_setup_interface()
			board.enable_piece_placement(true)
		
		GameState.PLAYER_TURN:
			timer.start(turn_timeout)
			ui.update_turn_display(active_player_index)
			board.enable_piece_interaction(true)
			player_turn_started.emit(active_player_index)
		
		GameState.GAME_OVER:
			board.enable_piece_interaction(false)
			timer.stop()
			ui.show_game_over()

func exit_state(state: GameState):
	match state:
		GameState.PLAYER_SETUP:
			board.enable_piece_placement(false)
			ui.hide_setup_interface()
		
		GameState.PLAYER_TURN:
			board.enable_piece_interaction(false)
			player_turn_ended.emit(active_player_index)

func execute_move(move_data: Dictionary):
	if current_state != GameState.PLAYER_TURN:
		return
	if !is_valid_move(move_data):
		ui.show_invalid_move_warning()
		return
	change_state(GameState.MOVE_ANIMATION)
	
	var piece = board.get_piece_at(move_data.from_position)
	var target_position = move_data.to_position
	# Handle captures
	if board.has_piece_at(target_position):
		var captured_piece = board.get_piece_at(target_position)
		captured_piece.capture()
		move_data["captured"] = captured_piece.get_data()
		# Animate movement with proper await
	await piece.move_to(target_position)
	# Update game state after animation completes
	board.update_piece_position(piece, move_data.from_position, target_position)
	move_history.append(move_data)
	move_executed.emit(move_data)
	check_victory_conditions()
	advance_turn()

func advance_turn():
	active_player_index = (active_player_index + 1) % players.size()
	change_state(GameState.TURN_TRANSITION)
	await get_tree().create_timer(0.5).timeout
	change_state(GameState.PLAYER_TURN)

func is_valid_move(move_data: Dictionary) -> bool:
	# Basic validation
	if !board.has_piece_at(move_data.from_position):
		return false
	
	var piece = board.get_piece_at(move_data.from_position)
	if !piece or piece.team != active_player_index:
		return false
	if !board.is_within_bounds(move_data.to_position):
		return false
	
	# Check detection validation
	var temp_state = board.get_current_state()
	temp_state.move_piece(move_data.from_position, move_data.to_position)
	if CheckDetector.is_king_in_check(temp_state, active_player_index):
		return false
	
	return piece.is_valid_move(move_data.to_position, board)

func check_victory_conditions():
	var alive_teams := {}
	for piece in board.get_all_pieces():
		alive_teams[piece.team] = true
	
	if alive_teams.size() == 1:
		declare_victory(alive_teams.keys()[0])

func declare_victory(winning_team: int):
	var result = {
		"winner": winning_team,
		"reason": "last_standing",
		"score": players[winning_team].calculate_score()
	}
	game_over.emit(result)
	change_state(GameState.GAME_OVER)

# Input handlers
func _on_tile_selected(grid_pos: Vector2i):
	if current_state != GameState.PLAYER_TURN:
		return
	
	if board.has_piece_at(grid_pos):
		handle_piece_selection(grid_pos)
	else:
		handle_tile_selection(grid_pos)

func _on_piece_selected(piece: BasePiece):
	if current_state == GameState.PLAYER_TURN:
		handle_piece_selection(piece.grid_position)

func handle_piece_selection(position: Vector2i):
	var piece = board.get_piece_at(position)
	if piece and piece.team == active_player_index:
		ui.show_available_moves(piece.get_valid_moves(board))
		input_manager.selected_piece = piece

func handle_tile_selection(position: Vector2i):
	var selected_piece = input_manager.selected_piece
	if selected_piece and position in selected_piece.get_valid_moves(board):
		var move_data = {
			"from_position": selected_piece.grid_position,
			"to_position": position,
			"piece": selected_piece.get_data()
		}
		execute_move(move_data)

func _on_turn_timer_timeout():
	players[active_player_index].penalize_timeout()
	advance_turn()

func reset_game():
	active_player_index = starting_player
	move_history.clear()
	board.reset_board()
	change_state(GameState.PLAYER_SETUP)
