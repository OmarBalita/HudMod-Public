class_name PingPongRenderer extends Node

signal process_started()
signal process_finished()

@onready var viewport_a: SubViewport = SubViewport.new()
@onready var viewport_b: SubViewport = SubViewport.new()
@onready var viewport_c: SubViewport = SubViewport.new()

@onready var sprite_a: Sprite2D = Sprite2D.new()
@onready var sprite_b: Sprite2D = Sprite2D.new()
@onready var sprite_c: Sprite2D = Sprite2D.new()

var is_in_process: bool:
	set(val):
		is_in_process = val
		if val: process_started.emit()
		else: process_finished.emit()

var process_id: int

func _ready() -> void:
	
	for vp: SubViewport in [viewport_a, viewport_b, viewport_c]:
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		var cam = Camera2D.new()
		vp.add_child(cam)
		add_child(vp)
	
	sprite_a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite_c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	viewport_a.add_child(sprite_a)
	viewport_b.add_child(sprite_b)
	viewport_c.add_child(sprite_c)


func request_process_output(input_tex: Texture2D, shader_materials: Array[ShaderMaterial], render_scale: float = 1., render_margin: Vector2i = Vector2i()) -> Texture2D:
	
	process_id += 1
	var curr_process_id: int = process_id
	
	is_in_process = true
	
	var original_size: Vector2 = input_tex.get_size()
	var base_size: Vector2 = original_size * render_scale
	var target_size: Vector2i = Vector2i(base_size) + render_margin
	var size_ratio: Vector2 = base_size / Vector2(target_size)
	
	target_size.x = max(1, target_size.x)
	target_size.y = max(1, target_size.y)
	
	viewport_a.size = target_size
	viewport_b.size = target_size
	viewport_c.size = target_size
	
	var output: Texture2D = input_tex
	
	for index: int in shader_materials.size():
		if curr_process_id != process_id:
			return null
		
		var is_a: bool = index % 2 == 0
		var target_vp: SubViewport
		var target_sprite: Sprite2D
		if is_a:
			target_vp = viewport_a
			target_sprite = sprite_a
		else:
			target_vp = viewport_b
			target_sprite = sprite_b
		
		target_sprite.texture = output
		
		var tex_size: Vector2 = output.get_size()
		target_sprite.scale = Vector2(target_size) / Vector2(tex_size) * (size_ratio if index == 0 else 1.)
		target_sprite.material = shader_materials[index]
		
		target_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		
		output = target_vp.get_texture()
	
	if curr_process_id != process_id:
		return null
	
	sprite_c.texture = output
	sprite_c.scale = Vector2.ONE
	sprite_c.material = null
	
	viewport_c.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	if curr_process_id == process_id:
		is_in_process = false
	
	return viewport_c.get_texture()

