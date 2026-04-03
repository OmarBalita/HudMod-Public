class_name ImageViewer extends Node2D

@export var texture: Texture2D:
	set(val):
		texture = val
		queue_redraw()

@export_group("Offset")
@export var offset: Vector2 = Vector2.ZERO:
	set(val):
		offset = val
		queue_redraw()
@export var flip_h: bool = false:
	set(val):
		flip_h = val
		queue_redraw()
@export var flip_v: bool = false:
	set(val):
		flip_v = val
		queue_redraw()

var texture_scale: Vector2

func _draw() -> void:
	
	var view_size: Vector2i = Scene2.viewport.size
	
	var tex_size: Vector2 = texture.get_size()
	
	var scale_factor: float = min(view_size.x / tex_size.x, view_size.y / tex_size.y)
	var final_size: Vector2 = tex_size * scale_factor
	
	var position: Vector2 = -final_size / 2. + offset
	
	var rect: Rect2 = Rect2(position, final_size)
	
	if flip_h:
		rect.size.x *= -1.
	if flip_v:
		rect.size.y *= -1.
	
	draw_texture_rect(texture, rect, false)


