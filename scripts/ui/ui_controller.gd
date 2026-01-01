class_name UIController
extends Control
## Minimalist UI panel with smooth slide animation.

signal algorithm_changed(algorithm: int)
signal grid_size_changed(size: int)
signal generate_pressed
signal reset_pressed

const ALGORITHM_PERLIN := 1
const ALGORITHM_MIDPOINT := 2
const VALID_GRID_SIZES: Array[int] = [17, 33, 65, 129, 257, 513]

@export var animation_speed: float = 6.0
@export var hover_scale: float = 1.08
@export var hover_speed: float = 12.0

var _is_visible: bool = false
var _target_y: float = 0.0
var _hidden_y: float = 0.0
var _shown_y: float = 0.0
var _current_algorithm: int = ALGORITHM_MIDPOINT
var _grid_size_index: int = 3  # Default 129

# Button hover states
var _button_scales: Dictionary = {}
var _button_targets: Dictionary = {}

@onready var panel: Control = $Panel
@onready var toggle_btn: Button = $Panel/ToggleButton
@onready var content: HBoxContainer = $Panel/Content
@onready var perlin_btn: Button = $Panel/Content/PerlinButton
@onready var midpoint_btn: Button = $Panel/Content/MidpointButton
@onready var grid_down_btn: Button = $Panel/Content/GridSection/GridDown
@onready var grid_label: Label = $Panel/Content/GridSection/GridLabel
@onready var grid_up_btn: Button = $Panel/Content/GridSection/GridUp
@onready var seed_label: Label = $Panel/Content/SeedSection/SeedLabel
@onready var generate_btn: Button = $Panel/Content/GenerateButton
@onready var reset_btn: Button = $Panel/Content/ResetButton


func _ready() -> void:
	print("UIController: Initializing...")
	# Calculate positions
	await get_tree().process_frame
	
	# When hidden: panel moves DOWN so only toggle button (28px) is visible
	# When shown: panel is at Y=0 (fully visible)
	_shown_y = 0.0
	_hidden_y = panel.size.y - 28.0  # Move down, only show toggle button
	
	print("UIController: Panel size = ", panel.size)
	print("UIController: _shown_y = ", _shown_y, ", _hidden_y = ", _hidden_y)
	
	# Start hidden
	_is_visible = false
	_target_y = _hidden_y
	panel.position.y = _hidden_y
	
	_setup_buttons()
	_connect_signals()
	_update_grid_label()
	
	print("UIController: Ready! Panel hidden at y=", _hidden_y)


func _process(delta: float) -> void:
	# Smooth panel slide with easing
	var diff := _target_y - panel.position.y
	if absf(diff) > 0.5:
		# Ease out cubic for smooth deceleration
		var t := animation_speed * delta
		panel.position.y += diff * t * (2.0 - t)
	else:
		panel.position.y = _target_y
	
	# Animate button scales
	for btn in _button_scales.keys():
		if is_instance_valid(btn):
			var target: float = _button_targets.get(btn, 1.0)
			var current: float = _button_scales[btn]
			_button_scales[btn] = lerpf(current, target, hover_speed * delta)
			btn.scale = Vector2.ONE * _button_scales[btn]


func _setup_buttons() -> void:
	var buttons := [toggle_btn, perlin_btn, midpoint_btn, grid_down_btn, grid_up_btn, generate_btn, reset_btn]
	for btn in buttons:
		if btn:
			_button_scales[btn] = 1.0
			_button_targets[btn] = 1.0
			btn.pivot_offset = btn.size / 2.0
			btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
			btn.mouse_exited.connect(_on_button_hover.bind(btn, false))


func _connect_signals() -> void:
	if toggle_btn:
		toggle_btn.pressed.connect(_on_toggle)
	if perlin_btn:
		perlin_btn.pressed.connect(_on_perlin)
	if midpoint_btn:
		midpoint_btn.pressed.connect(_on_midpoint)
	if grid_down_btn:
		grid_down_btn.pressed.connect(_on_grid_down)
	if grid_up_btn:
		grid_up_btn.pressed.connect(_on_grid_up)
	if generate_btn:
		generate_btn.pressed.connect(func(): generate_pressed.emit())
	if reset_btn:
		reset_btn.pressed.connect(func(): reset_pressed.emit())


func _on_button_hover(btn: Button, hovered: bool) -> void:
	_button_targets[btn] = hover_scale if hovered else 1.0


func _on_toggle() -> void:
	_is_visible = not _is_visible
	if _is_visible:
		_target_y = _shown_y
		toggle_btn.text = "v  Hide  v"
	else:
		_target_y = _hidden_y
		toggle_btn.text = "^  Menu  ^"


func _on_perlin() -> void:
	_current_algorithm = ALGORITHM_PERLIN
	_update_algo_buttons()
	algorithm_changed.emit(ALGORITHM_PERLIN)


func _on_midpoint() -> void:
	_current_algorithm = ALGORITHM_MIDPOINT
	_update_algo_buttons()
	algorithm_changed.emit(ALGORITHM_MIDPOINT)


func _on_grid_down() -> void:
	if _grid_size_index > 0:
		_grid_size_index -= 1
		_update_grid_label()
		grid_size_changed.emit(VALID_GRID_SIZES[_grid_size_index])


func _on_grid_up() -> void:
	if _grid_size_index < VALID_GRID_SIZES.size() - 1:
		_grid_size_index += 1
		_update_grid_label()
		grid_size_changed.emit(VALID_GRID_SIZES[_grid_size_index])


func _update_grid_label() -> void:
	if grid_label:
		grid_label.text = str(VALID_GRID_SIZES[_grid_size_index])
	# Update button states
	if grid_down_btn:
		grid_down_btn.disabled = (_grid_size_index <= 0)
	if grid_up_btn:
		grid_up_btn.disabled = (_grid_size_index >= VALID_GRID_SIZES.size() - 1)


func _update_algo_buttons() -> void:
	if perlin_btn:
		perlin_btn.button_pressed = (_current_algorithm == ALGORITHM_PERLIN)
	if midpoint_btn:
		midpoint_btn.button_pressed = (_current_algorithm == ALGORITHM_MIDPOINT)


func set_algorithm(algo: int) -> void:
	_current_algorithm = algo
	_update_algo_buttons()


func set_grid_size(new_size: int) -> void:
	for i in range(VALID_GRID_SIZES.size()):
		if VALID_GRID_SIZES[i] == new_size:
			_grid_size_index = i
			_update_grid_label()
			return


func set_seed(seed_value: int) -> void:
	"""Update the displayed seed value."""
	if seed_label:
		seed_label.text = str(seed_value)
