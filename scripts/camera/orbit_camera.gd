class_name OrbitCamera
extends Camera3D
## Animated orbit camera around terrain center.

@export_group("Orbit Settings")
@export var target: Vector3 = Vector3.ZERO
@export var distance: float = 50.0
@export var height: float = 30.0
@export var auto_rotate: bool = true
@export var rotation_speed: float = 0.2  # Radians per second

@export_group("Manual Control")
@export var mouse_sensitivity: float = 0.003
@export var zoom_speed: float = 2.0
@export var min_distance: float = 10.0
@export var max_distance: float = 150.0

var _orbit_angle: float = 0.0
var _pitch: float = -0.4  # Slight downward angle
var _is_dragging: bool = false


func _ready() -> void:
	# Connect to GameSettings for auto_rotate state
	GameSettings.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()
	_update_camera_position()


func _process(delta: float) -> void:
	if auto_rotate and not _is_dragging:
		_orbit_angle += rotation_speed * delta
	
	_update_camera_position()


func _unhandled_input(event: InputEvent) -> void:
	# Handle configurable shortcut for toggling spin
	if event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		if key_event.keycode == GameSettings.spin_toggle_key:
			GameSettings.camera_auto_rotate = not GameSettings.camera_auto_rotate
			return
	
	# Mouse drag for manual orbit
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_is_dragging = mb.pressed
			if _is_dragging:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		# Zoom with scroll wheel
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - zoom_speed, min_distance, max_distance)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + zoom_speed, min_distance, max_distance)
	
	# Mouse motion for orbit control
	if event is InputEventMouseMotion and _is_dragging:
		var motion := event as InputEventMouseMotion
		_orbit_angle -= motion.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - motion.relative.y * mouse_sensitivity, -PI/2 + 0.1, -0.1)


func _update_camera_position() -> void:
	# Calculate orbit position
	var horizontal_dist := distance * cos(_pitch)
	var vertical_offset := distance * sin(_pitch)
	
	var x := target.x + horizontal_dist * cos(_orbit_angle)
	var z := target.z + horizontal_dist * sin(_orbit_angle)
	var y := target.y + height - vertical_offset
	
	global_position = Vector3(x, y, z)
	look_at(target, Vector3.UP)


func set_target(new_target: Vector3) -> void:
	target = new_target


func set_orbit_angle(angle: float) -> void:
	_orbit_angle = angle


func toggle_auto_rotate() -> void:
	auto_rotate = not auto_rotate


func _on_settings_changed() -> void:
	auto_rotate = GameSettings.camera_auto_rotate
