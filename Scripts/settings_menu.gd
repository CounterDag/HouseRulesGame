# settings_menu.gd
class_name SettingsMenu
extends CanvasLayer

## Emitted when settings should be applied to visible pieces
signal settings_applied
## Emitted when returning to previous menu
signal menu_closed

@export_category("UI References")
@export var color_picker: ColorPickerButton
@export var scale_slider: HSlider
@export var material_list: OptionButton
@export var preview_piece: BasePiece

@export_category("Material Options")
@export var available_materials: Array[StandardMaterial3D]

var current_settings: PlayerSettings
var player_id: int = 0

func _ready():
	# Initialize UI with current settings
	current_settings = PlayerSettings.load_or_create(player_id)
	_populate_material_list()
	_refresh_ui()
	
	# Connect signals
	color_picker.color_changed.connect(_on_color_changed)
	scale_slider.value_changed.connect(_on_scale_changed)
	material_list.item_selected.connect(_on_material_selected)
	
	visibility_changed.connect(_on_visibility_changed)
	
	# Initial preview update
	_update_preview()

func _populate_material_list():
	material_list.clear()
	for mat in available_materials:
		material_list.add_item(mat.resource_name)
		material_list.set_item_metadata(material_list.item_count - 1, mat)

func _refresh_ui():
	color_picker.color = current_settings.base_color
	scale_slider.value = current_settings.base_scale
	
	# Select current material in list
	for i in material_list.item_count:
		if material_list.get_item_metadata(i) == current_settings.base_material:
			material_list.select(i)
			break

func _update_preview():
	if is_instance_valid(preview_piece):
		current_settings.apply_to_mesh(preview_piece.base)

func _on_color_changed(new_color: Color):
	current_settings.base_color = new_color
	_update_preview()

func _on_scale_changed(new_scale: float):
	current_settings.base_scale = new_scale
	_update_preview()

func _on_material_selected(index: int):
	var selected_mat = material_list.get_item_metadata(index)
	if selected_mat is StandardMaterial3D:
		current_settings.base_material = selected_mat
		_update_preview()

func _on_apply_pressed():
	if current_settings.validate():
		current_settings.save(player_id)
		settings_applied.emit()
		hide()
	else:
		show_error("Invalid settings!")

func _on_close_pressed():
	menu_closed.emit()
	hide()

func show_error(message: String):
	# Implement your error display logic here
	print("Error: ", message)

func _on_visibility_changed():
	if visible:
		current_settings = PlayerSettings.load_or_create(player_id)
		_refresh_ui()
		_update_preview()
