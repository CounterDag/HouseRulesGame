extends Node3D

@export var movement_speed: float = 5.0
@export var horizontal_rotation_speed: float = 1.0
@export var vertical_rotation_speed: float = 1.0
@export var zoom_speed: float = 1.0
@export var min_height: float = 2.0
@export var max_height: float = 12.0
@export var min_vertical_angle: float = 15.0  # -90 degrees (straight down)
@export var max_vertical_angle: float = 75.0    # 0 degrees (horizontal)

var _horizontal_rotation: float = 0.0
var _vertical_rotation: float = 45.0  # Start at top-down
var _mouse_rotation: bool = false

@onready var _pivot: Node3D = $Pivot
@onready var _camera: Camera3D = $Pivot/Camera3D

func _ready():
	_update_camera_transform()

func _input(event):
	# Mouse rotation control
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_mouse_rotation = event.pressed
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion && _mouse_rotation:
		# Horizontal rotation
		_horizontal_rotation += -event.relative.x * horizontal_rotation_speed
		# Vertical rotation with clamping
		_vertical_rotation = clamp(
			_vertical_rotation + -event.relative.y * vertical_rotation_speed,
			min_vertical_angle,
			max_vertical_angle
		)
		_update_camera_transform()
	
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.position.y = clamp(_camera.position.y - zoom_speed, min_height, max_height)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.position.y = clamp(_camera.position.y + zoom_speed, min_height, max_height)

func _process(delta):
	# Keyboard movement
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("camera_right") - Input.get_action_strength("camera_left")
	input_vector.y = Input.get_action_strength("camera_back") - Input.get_action_strength("camera_forward")
	
	if input_vector.length() > 0:
		var move_direction = input_vector.normalized().rotated(deg_to_rad(-_horizontal_rotation))
		global_translate(Vector3(move_direction.x, 0, move_direction.y) * movement_speed * delta)

func _update_camera_transform():
	# Convert degrees to radians for 3D rotations
	var horizontal_rad = deg_to_rad(_horizontal_rotation)
	var vertical_rad = deg_to_rad(_vertical_rotation)
	
	# Apply rotations to pivot
	_pivot.rotation = Vector3(vertical_rad, horizontal_rad, 0.0)
	
	# Keep camera focused on parent position
	_camera.look_at(global_position)
