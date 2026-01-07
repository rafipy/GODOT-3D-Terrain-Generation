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
@export var hold_initial_delay: float = 0.5
@export var hold_repeat_rate: float = 0.1

var _is_visible: bool = false
var _target_y: float = 0.0
var _hidden_y: float = 0.0
var _shown_y: float = 0.0
var _current_algorithm: int = ALGORITHM_MIDPOINT
var _grid_size: int = 129

# Button hover states
var _button_scales: Dictionary = {}
var _button_targets: Dictionary = {}

# Hold-to-repeat state
var _hold_timer: Timer
var _is_holding: bool = false
var _hold_direction: int = 0
var _initial_hold: bool = true

var auto_refresh = false

@onready var panel: Control = $Panel
@onready var toggle_btn: Button = $Panel/ToggleButton
@onready var content: HBoxContainer = $Panel/Content
@onready var perlin_btn: Button = $Panel/Content/PerlinButton
@onready var midpoint_btn: Button = $Panel/Content/MidpointButton
@onready var grid_down_btn: Button = $Panel/Content/GridSection/GridController/GridDown
@onready var grid_label: Label = $Panel/Content/GridSection/GridController/GridLabel
@onready var grid_up_btn: Button = $Panel/Content/GridSection/GridController/GridUp
@onready var seed_label: Label = $Panel/Content/SeedSection/SeedLabel
@onready var generate_btn: Button = $Panel/Content/GenerateButton
@onready var reset_btn: Button = $Panel/Content/ResetButton
@onready var refresh_chk: CheckBox = $Panel/Content/RefreshSection/RefreshCheck
@onready var refresh_btn: Button = $Panel/Content/RefreshButton
@onready var simulate_btn: Button = $Panel/Content/SimulateButton

func _ready() -> void:
	print("UIController: Initializing...")
	
	# Grid up and down hold timer
	_hold_timer = Timer.new()
	_hold_timer.one_shot = false
	_hold_timer.timeout.connect(_on_hold_timer_timeout)
	add_child(_hold_timer)
	
	await get_tree().process_frame
	
	_shown_y = 0.0
	_hidden_y = panel.size.y - 28.0
	
	print("UIController: Panel size = ", panel.size)
	print("UIController: _shown_y = ", _shown_y, ", _hidden_y = ", _hidden_y)
	
	# Start hidden
	_is_visible = false
	_target_y = _hidden_y
	panel.position.y = _hidden_y
	
	GameSettings.settings_changed.connect(_update_grid_label)
	_setup_buttons()
	_connect_signals()
	_update_grid_label()
	_update_refresh_button_state()
	
	print("UIController: Ready! Panel hidden at y=", _hidden_y)


func _process(delta: float) -> void:
	# Smooth panel slide with easing
	var diff := _target_y - panel.position.y
	if absf(diff) > 0.5:
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
	var buttons := [toggle_btn, perlin_btn, midpoint_btn, grid_down_btn, 
					grid_up_btn, generate_btn, reset_btn, refresh_btn, simulate_btn]
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
		grid_down_btn.button_down.connect(_on_grid_button_down.bind(-1))
		grid_down_btn.button_up.connect(_on_grid_button_up)
	if grid_up_btn:
		grid_up_btn.button_down.connect(_on_grid_button_down.bind(1))
		grid_up_btn.button_up.connect(_on_grid_button_up)
	if generate_btn:
		generate_btn.pressed.connect(func(): generate_pressed.emit())
	if reset_btn:
		reset_btn.pressed.connect(func(): reset_pressed.emit())
	if refresh_btn:
		refresh_btn.pressed.connect(_refresh)
	if refresh_chk:
		refresh_chk.toggled.connect(_on_check)
	if simulate_btn:
		simulate_btn.pressed.connect(_simulate)


func _on_check(checked: bool) -> void:
	GameSettings.auto_refresh = checked
	_update_refresh_button_state()
	
	# If turning auto_refresh ON, apply any pending terrain
	if checked:
		var terrain := get_tree().get_first_node_in_group("terrain")
		if terrain and terrain.has_method("apply_pending_terrain"):
			terrain.apply_pending_terrain()


func _update_refresh_button_state() -> void:
	"""Update refresh button appearance based on auto_refresh state"""
	if refresh_btn:
		# Enable the manual refresh button only when auto_refresh is OFF
		refresh_btn.disabled = GameSettings.auto_refresh
		if GameSettings.auto_refresh:
			refresh_btn.text = "Auto"
		else:
			refresh_btn.text = "Refresh"


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
	GameSettings.current_algorithm = GameSettings.Algorithm.PERLIN_NOISE
	GameSettings.settings_changed.emit()


func _on_midpoint() -> void:
	_current_algorithm = ALGORITHM_MIDPOINT
	_update_algo_buttons()
	GameSettings.current_algorithm = GameSettings.Algorithm.MIDPOINT_DISPLACEMENT
	GameSettings.settings_changed.emit()


func _change_grid_size(direction: int) -> void:
	GameSettings.terrain_power += direction

func _simulate():
	var terrainNode:TerrainController = get_parent().get_parent().get_node("SubViewportContainer").get_node("SubViewport").get_node("Terrain")
	var temp: bool = GameSettings.auto_refresh
	GameSettings.simulating = true
	GameSettings.auto_refresh = false
	var metricNode:Metrics = get_parent().get_node("MetricController")
	GameSettings.current_algorithm = GameSettings.Algorithm.MIDPOINT_DISPLACEMENT
	var midpoint_times:Array[int] = []
	var midpoint_spaces: Array[String] = []
	var midpoint_fds: Array[String]=[]
	for i in range(1, 13):
		var start_time = Time.get_ticks_msec()
		var start_mem = OS.get_static_memory_usage()
		GameSettings.terrain_power = i
		var end_time = Time.get_ticks_msec()
		var end_mem = OS.get_static_memory_usage()
		midpoint_times.append(end_time - start_time)
		var space_kb = (end_mem - start_mem) / 1024.0
		midpoint_spaces.append("%.1f" % space_kb)
		midpoint_fds.append("%.2f" % terrainNode.calculate_fractal_dimension())
		#print("Setting terrain_power to ", i, " took ", end_time - start_time, " ms")
	GameSettings.current_algorithm = GameSettings.Algorithm.PERLIN_NOISE
	var perlin_times:Array[int] = []
	var perlin_spaces: Array[String] = []
	var perlin_fds: Array[String]=[]
	for i in range(1,13):
		var start_time = Time.get_ticks_msec()
		var start_mem = OS.get_static_memory_usage()
		GameSettings.terrain_power = i
		var end_time = Time.get_ticks_msec()
		var end_mem = OS.get_static_memory_usage()
		perlin_times.append(end_time - start_time)
		var space_kb = (end_mem - start_mem) / 1024.0
		perlin_spaces.append("%.1f" % space_kb)
		perlin_fds.append("%.2f" % terrainNode.calculate_fractal_dimension())
		
	metricNode.update_metrics(
		midpoint_times,perlin_times,
		midpoint_spaces,perlin_spaces,
		midpoint_fds,perlin_fds
	)
	GameSettings.terrain_power = 7
	GameSettings.simulating = false
	GameSettings.auto_refresh = temp
	
func _refresh():
	"""Apply pending terrain data to mesh"""
	var terrain := get_tree().get_first_node_in_group("terrain")
	if terrain:
		# Check if there's pending data to apply
		if terrain.has_method("apply_pending_terrain"):
			terrain.apply_pending_terrain()
		else:
			# Fallback: force regenerate
			terrain.force_generate()

	
func _on_grid_button_down(direction: int) -> void:
	_hold_direction = direction
	_is_holding = true
	_initial_hold = true
	
	_change_grid_size(direction)
	
	_hold_timer.wait_time = hold_initial_delay
	_hold_timer.start()


func _on_grid_button_up() -> void:
	_is_holding = false
	_hold_timer.stop()


func _on_hold_timer_timeout() -> void:
	if _is_holding:
		if _initial_hold:
			_initial_hold = false
			_hold_timer.wait_time = hold_repeat_rate
		
		_change_grid_size(_hold_direction)


func _update_grid_label() -> void:
	var size := GameSettings.get_grid_size()
	grid_label.text = "%d" % [size]


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
			_grid_size = i
			_update_grid_label()
			return


func set_seed(seed_value: int) -> void:
	"""Update the displayed seed value."""
	if seed_label:
		seed_label.text = str(seed_value)
