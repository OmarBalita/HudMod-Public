class_name FlexViewportControl extends Control

@export var viewport_container: SubViewportContainer

func _ready() -> void:
	resized.connect(on_resized)

func on_resized() -> void:
	
	if not viewport_container: return
	
	var viewport: SubViewport = null
	for child in viewport_container.get_children():
		if child is SubViewport:
			viewport = child
			break
	if not viewport:
		return
	
	var viewport_size = viewport.size
	
	var scale_ratio = min(
		size.x / viewport_size.x,
		size.y / viewport_size.y
	)
	
	viewport_container.scale = Vector2.ONE * scale_ratio
	
	var scaled_size = Vector2(viewport_size) * viewport_container.scale
	viewport_container.position = (size - scaled_size) / 2.0







