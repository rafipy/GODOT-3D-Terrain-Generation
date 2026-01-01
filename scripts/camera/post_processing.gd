extends MeshInstance3D
## Post-processing quad that stays attached to camera.
## Renders full-screen effects like pixelation.

@onready var _camera: Camera3D = get_parent() as Camera3D


func _ready() -> void:
	if not _camera:
		push_error("PostProcessing must be a child of Camera3D")
		queue_free()
		return


func _process(_delta: float) -> void:
	# Keep quad positioned in front of camera in clip space
	# The vertex shader handles the actual full-screen positioning
	# This just ensures the mesh stays attached
	pass
