class_name Metrics
extends Control

@onready var panel: Control = self
@onready var toggle_btn: Button = $ToggleButton

@onready var midpoint_time_label1: Label = $TheGrid/MidpointGrid/Time2
@onready var midpoint_time_label2: Label = $TheGrid/MidpointGrid/Time3
@onready var midpoint_time_label3: Label = $TheGrid/MidpointGrid/Time4
@onready var midpoint_time_label4: Label = $TheGrid/MidpointGrid/Time5
@onready var midpoint_time_label5: Label = $TheGrid/MidpointGrid/Time6
@onready var midpoint_time_label6: Label = $TheGrid/MidpointGrid/Time7
@onready var midpoint_time_label7: Label = $TheGrid/MidpointGrid/Time8
@onready var midpoint_time_label8: Label = $TheGrid/MidpointGrid/Time9
@onready var midpoint_time_label9: Label = $TheGrid/MidpointGrid/Time10
@onready var midpoint_time_label10: Label = $TheGrid/MidpointGrid/Time11
@onready var midpoint_time_label11: Label = $TheGrid/MidpointGrid/Time12
@onready var midpoint_time_label12: Label = $TheGrid/MidpointGrid/Time13

@onready var midpoint_space_label1: Label = $TheGrid/MidpointGrid/Space2
@onready var midpoint_space_label2: Label = $TheGrid/MidpointGrid/Space3
@onready var midpoint_space_label3: Label = $TheGrid/MidpointGrid/Space4
@onready var midpoint_space_label4: Label = $TheGrid/MidpointGrid/Space5
@onready var midpoint_space_label5: Label = $TheGrid/MidpointGrid/Space6
@onready var midpoint_space_label6: Label = $TheGrid/MidpointGrid/Space7
@onready var midpoint_space_label7: Label = $TheGrid/MidpointGrid/Space8
@onready var midpoint_space_label8: Label = $TheGrid/MidpointGrid/Space9
@onready var midpoint_space_label9: Label = $TheGrid/MidpointGrid/Space10
@onready var midpoint_space_label10: Label = $TheGrid/MidpointGrid/Space11
@onready var midpoint_space_label11: Label = $TheGrid/MidpointGrid/Space12
@onready var midpoint_space_label12: Label = $TheGrid/MidpointGrid/Space13

@onready var midpoint_fd_label1: Label = $TheGrid/MidpointGrid/fd2
@onready var midpoint_fd_label2: Label = $TheGrid/MidpointGrid/fd3
@onready var midpoint_fd_label3: Label = $TheGrid/MidpointGrid/fd4
@onready var midpoint_fd_label4: Label = $TheGrid/MidpointGrid/fd5
@onready var midpoint_fd_label5: Label = $TheGrid/MidpointGrid/fd6
@onready var midpoint_fd_label6: Label = $TheGrid/MidpointGrid/fd7
@onready var midpoint_fd_label7: Label = $TheGrid/MidpointGrid/fd8
@onready var midpoint_fd_label8: Label = $TheGrid/MidpointGrid/fd9
@onready var midpoint_fd_label9: Label = $TheGrid/MidpointGrid/fd10
@onready var midpoint_fd_label10: Label = $TheGrid/MidpointGrid/fd11
@onready var midpoint_fd_label11: Label = $TheGrid/MidpointGrid/fd12
@onready var midpoint_fd_label12: Label = $TheGrid/MidpointGrid/fd13


var midpoint_time_labels: Array
var midpoint_space_labels: Array
var midpoint_fd_labels: Array


@onready var perlin_time_label1: Label = $TheGrid/PerlinGrid/Time2
@onready var perlin_time_label2: Label = $TheGrid/PerlinGrid/Time3
@onready var perlin_time_label3: Label = $TheGrid/PerlinGrid/Time4
@onready var perlin_time_label4: Label = $TheGrid/PerlinGrid/Time5
@onready var perlin_time_label5: Label = $TheGrid/PerlinGrid/Time6
@onready var perlin_time_label6: Label = $TheGrid/PerlinGrid/Time7
@onready var perlin_time_label7: Label = $TheGrid/PerlinGrid/Time8
@onready var perlin_time_label8: Label = $TheGrid/PerlinGrid/Time9
@onready var perlin_time_label9: Label = $TheGrid/PerlinGrid/Time10
@onready var perlin_time_label10: Label = $TheGrid/PerlinGrid/Time11
@onready var perlin_time_label11: Label = $TheGrid/PerlinGrid/Time12
@onready var perlin_time_label12: Label = $TheGrid/PerlinGrid/Time13

@onready var perlin_space_label1: Label = $TheGrid/PerlinGrid/Space2
@onready var perlin_space_label2: Label = $TheGrid/PerlinGrid/Space3
@onready var perlin_space_label3: Label = $TheGrid/PerlinGrid/Space4
@onready var perlin_space_label4: Label = $TheGrid/PerlinGrid/Space5
@onready var perlin_space_label5: Label = $TheGrid/PerlinGrid/Space6
@onready var perlin_space_label6: Label = $TheGrid/PerlinGrid/Space7
@onready var perlin_space_label7: Label = $TheGrid/PerlinGrid/Space8
@onready var perlin_space_label8: Label = $TheGrid/PerlinGrid/Space9
@onready var perlin_space_label9: Label = $TheGrid/PerlinGrid/Space10
@onready var perlin_space_label10: Label = $TheGrid/PerlinGrid/Space11
@onready var perlin_space_label11: Label = $TheGrid/PerlinGrid/Space12
@onready var perlin_space_label12: Label = $TheGrid/PerlinGrid/Space13

@onready var perlin_fd_label1: Label = $TheGrid/PerlinGrid/fd2
@onready var perlin_fd_label2: Label = $TheGrid/PerlinGrid/fd3
@onready var perlin_fd_label3: Label = $TheGrid/PerlinGrid/fd4
@onready var perlin_fd_label4: Label = $TheGrid/PerlinGrid/fd5
@onready var perlin_fd_label5: Label = $TheGrid/PerlinGrid/fd6
@onready var perlin_fd_label6: Label = $TheGrid/PerlinGrid/fd7
@onready var perlin_fd_label7: Label = $TheGrid/PerlinGrid/fd8
@onready var perlin_fd_label8: Label = $TheGrid/PerlinGrid/fd9
@onready var perlin_fd_label9: Label = $TheGrid/PerlinGrid/fd10
@onready var perlin_fd_label10: Label = $TheGrid/PerlinGrid/fd11
@onready var perlin_fd_label11: Label = $TheGrid/PerlinGrid/fd12
@onready var perlin_fd_label12: Label = $TheGrid/PerlinGrid/fd13

var perlin_time_labels: Array
var perlin_space_labels: Array
var perlin_fd_labels: Array


var _is_visible: bool = false
var _target_x: float = 0.0
var _hidden_x: float = 0.0
var _shown_x: float = 0.0
var animation_speed: float = 6.0

func _ready() -> void:
	_shown_x = 843
	_hidden_x = panel.size.x + 813
	
	_is_visible = false
	_target_x = _hidden_x
	panel.position.x = _hidden_x
	
	if toggle_btn:
		toggle_btn.pressed.connect(_on_toggle)
	
	midpoint_time_labels = [
		midpoint_time_label1, midpoint_time_label2, midpoint_time_label3, 
		midpoint_time_label4, midpoint_time_label5, midpoint_time_label6,
		midpoint_time_label7, midpoint_time_label8, midpoint_time_label9, 
		midpoint_time_label10, midpoint_time_label11, midpoint_time_label12
	]

	midpoint_space_labels = [
		midpoint_space_label1, midpoint_space_label2, midpoint_space_label3, 
		midpoint_space_label4, midpoint_space_label5, midpoint_space_label6, 
		midpoint_space_label7, midpoint_space_label8, midpoint_space_label9, 
		midpoint_space_label10, midpoint_space_label11, midpoint_space_label12
	]

	midpoint_fd_labels = [
		midpoint_fd_label1, midpoint_fd_label2, midpoint_fd_label3, 
		midpoint_fd_label4, midpoint_fd_label5, midpoint_fd_label6,
		midpoint_fd_label7, midpoint_fd_label8, midpoint_fd_label9, 
		midpoint_fd_label10, midpoint_fd_label11, midpoint_fd_label12
	]
	
	perlin_time_labels = [
		perlin_time_label1, perlin_time_label2, perlin_time_label3, 
		perlin_time_label4, perlin_time_label5, perlin_time_label6,
		perlin_time_label7, perlin_time_label8, perlin_time_label9, 
		perlin_time_label10, perlin_time_label11, perlin_time_label12
	]

	perlin_space_labels = [
		perlin_space_label1, perlin_space_label2, perlin_space_label3, 
		perlin_space_label4, perlin_space_label5, perlin_space_label6, 
		perlin_space_label7, perlin_space_label8, perlin_space_label9, 
		perlin_space_label10, perlin_space_label11, perlin_space_label12
	]

	perlin_fd_labels = [
		perlin_fd_label1, perlin_fd_label2, perlin_fd_label3, 
		perlin_fd_label4, perlin_fd_label5, perlin_fd_label6,
		perlin_fd_label7, perlin_fd_label8, perlin_fd_label9, 
		perlin_fd_label10, perlin_fd_label11, perlin_fd_label12
	]

func _on_toggle():
	_is_visible = not _is_visible
	if _is_visible:
		_target_x = _shown_x
		toggle_btn.text = "v  Hide  v"
	else:
		_target_x = _hidden_x
		toggle_btn.text = "^  Menu  ^"

func _process(delta: float) -> void:
	# Smooth panel slide with easing
	var diff := _target_x - panel.position.x
	if absf(diff) > 0.5:
		var t := animation_speed * delta
		panel.position.x += diff * t * (2.0 - t)
	else:
		panel.position.x = _target_x
	

func update_metrics(
	midpoint_times: Array, perlin_times: Array, 
	midpoint_spaces: Array, perlin_spaces: Array,
	midpoint_fds: Array, perlin_fds: Array
):
	for i in range(12):
		midpoint_time_labels[i].text = str(midpoint_times[i])
		perlin_time_labels[i].text = str(perlin_times[i])
		
		midpoint_space_labels[i].text = midpoint_spaces[i]
		perlin_space_labels[i].text = perlin_spaces[i]
		
		midpoint_fd_labels[i].text = midpoint_fds[i]
		perlin_fd_labels[i].text = perlin_fds[i]
	
