extends Node3D
## Main world controller.
## Handles input, terrain generation, and scene setup.

@onready var terrain: Node3D = $SubViewportContainer/SubViewport/Terrain
@onready var camera: Camera3D = $SubViewportContainer/SubViewport/OrbitCamera
@onready var water: MeshInstance3D = $SubViewportContainer/SubViewport/Water
@onready var sun: DirectionalLight3D = $SubViewportContainer/SubViewport/DirectionalLight3D
@onready var ui_controller: Control = $CanvasLayer/UIController
@onready var viewport_container: SubViewportContainer = $SubViewportContainer
@onready var post_fx_checkbox: CheckBox = $CanvasLayer/PostFXCheckBox
@onready var spin_checkbox: CheckBox = $CanvasLayer/SpinCheckBox


func _ready() -> void:
	_setup_water()
	_connect_signals()
	_connect_ui_signals()
	_connect_checkbox_signals()
	
	# Initial generation
	terrain.generate_terrain()


func _setup_water() -> void:
	# Water is at y=0 (sea level)
	water.position.y = GameSettings.water_level


func _connect_signals() -> void:
	terrain.terrain_generated.connect(_on_terrain_generated)
	GameSettings.settings_changed.connect(_on_settings_changed)
	GameSettings.seed_changed.connect(_on_seed_changed)


func _connect_ui_signals() -> void:
	if not ui_controller:
		return
	
	ui_controller.algorithm_changed.connect(_on_ui_algorithm_changed)
	ui_controller.grid_size_changed.connect(_on_ui_grid_size_changed)
	ui_controller.generate_pressed.connect(_on_ui_generate)
	ui_controller.reset_pressed.connect(_on_ui_flatten)
	
	# Sync initial UI state
	ui_controller.set_grid_size(GameSettings.get_grid_size())
	ui_controller.set_seed(GameSettings.terrain_seed)


func _connect_checkbox_signals() -> void:
	if post_fx_checkbox:
		post_fx_checkbox.toggled.connect(_on_post_fx_toggled)
	if spin_checkbox:
		spin_checkbox.toggled.connect(_on_spin_toggled)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key := event as InputEventKey
		match key.keycode:
			KEY_R:
				# Regenerate with new seed
				terrain.regenerate_with_new_seed()
				ui_controller.set_seed(GameSettings.terrain_seed)
				_print_settings()
			KEY_SPACE:
				# Toggle camera auto-rotate (handled via GameSettings now)
				GameSettings.camera_auto_rotate = not GameSettings.camera_auto_rotate
			KEY_EQUAL, KEY_KP_ADD:
				# Scale up
				GameSettings.terrain_scale = minf(GameSettings.terrain_scale + 0.1, 5.0)
				terrain.generate_terrain()
			KEY_MINUS, KEY_KP_SUBTRACT:
				# Scale down
				GameSettings.terrain_scale = maxf(GameSettings.terrain_scale - 0.1, 0.1)
				terrain.generate_terrain()
			KEY_BRACKETLEFT:
				# Decrease terrain detail
				GameSettings.terrain_size = maxi(GameSettings.terrain_size - 1, 4)
				terrain.generate_terrain()
			KEY_BRACKETRIGHT:
				# Increase terrain detail
				GameSettings.terrain_size = mini(GameSettings.terrain_size + 1, 9)
				terrain.generate_terrain()
			KEY_Q:
				# Decrease roughness (smoother terrain)
				GameSettings.md_roughness -= 0.05
				terrain.generate_terrain()
				print("Roughness: %.2f" % GameSettings.md_roughness)
			KEY_E:
				# Increase roughness (more chaotic terrain)
				GameSettings.md_roughness += 0.05
				terrain.generate_terrain()
				print("Roughness: %.2f" % GameSettings.md_roughness)
			KEY_1:
				terrain.set_algorithm(GameSettings.Algorithm.MIDPOINT_DISPLACEMENT)
				terrain.generate_terrain()
			KEY_2:
				terrain.set_algorithm(GameSettings.Algorithm.PERLIN_NOISE)
				terrain.generate_terrain()
			KEY_H:
				# Print help
				_print_controls()
			KEY_S:
				# Print current settings
				_print_settings()


func _print_controls() -> void:
	print("=== CONTROLS ===")
	print("R - New random seed")
	print("Q/E - Decrease/Increase roughness")
	print("+/- - Scale terrain up/down")
	print("[/] - Decrease/Increase grid detail")
	print("Space - Toggle camera auto-rotate")
	print("Right-click drag - Manual orbit")
	print("Scroll - Zoom")
	print("S - Show current settings")
	print("H - Show this help")


func _print_settings() -> void:
	print("=== SETTINGS ===")
	print("Seed: %d" % GameSettings.terrain_seed)
	print("Roughness: %.2f" % GameSettings.md_roughness)
	print("Grid: %d x %d" % [GameSettings.get_grid_size(), GameSettings.get_grid_size()])
	print("Scale: %.1f" % GameSettings.terrain_scale)


func _on_terrain_generated(time_ms: float) -> void:
	print("Generation complete: %.1f ms" % time_ms)


func _on_settings_changed() -> void:
	# Update post-processing stretch_shrink based on toggle
	if viewport_container:
		viewport_container.stretch_shrink = 4 if GameSettings.post_processing_enabled else 1


func _on_seed_changed(_new_seed: int) -> void:
	# Seed changed, regeneration will happen via explicit call
	pass


func _on_ui_algorithm_changed(algorithm: int) -> void:
	match algorithm:
		1:  # PERLIN
			terrain.set_algorithm(GameSettings.Algorithm.PERLIN_NOISE)
		2:  # MIDPOINT
			terrain.set_algorithm(GameSettings.Algorithm.MIDPOINT_DISPLACEMENT)
	terrain.generate_terrain()


func _on_ui_grid_size_changed(size: int) -> void:
	var power := int(log(size - 1) / log(2))
	GameSettings.terrain_size = power
	terrain.grid_size = size
	terrain.generate_terrain()


func _on_ui_generate() -> void:
	terrain.regenerate_with_new_seed()
	ui_controller.set_seed(GameSettings.terrain_seed)
	_print_settings()


func _on_ui_flatten() -> void:
	terrain.flatten_terrain()
	print("Terrain flattened")


func _on_post_fx_toggled(enabled: bool) -> void:
	GameSettings.post_processing_enabled = enabled


func _on_spin_toggled(enabled: bool) -> void:
	GameSettings.camera_auto_rotate = enabled
