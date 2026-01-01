extends Node

var n := 10
var selected := 1 # 1 = perlin noise, 2 = mid point

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func simulate() -> void:
	pass

func setGridSize(n_s:String) -> void:
	print('wow')
	n=int(n_s)
	# TODO update hte mesh

func setMid() -> void:
	print('wow')
	selected = 2

func setPerlin() -> void:
	print('wow')
	selected = 1

func reset() -> void:
	print('wow')
	setGridSize('10')
	
func run()-> void:
	print('wow')
	pass
