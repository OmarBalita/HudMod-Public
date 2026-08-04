class_name FixedViewer extends ImageViewer

func _draw() -> void:
	if not texture: return
	draw_texture(texture, -texture.get_size() / 2.)
