class_name CompressedTextureRes extends UsableRes

@export var texture: CompressedTexture2D

func _init(texture: CompressedTexture2D) -> void:
	set_texture(texture)
	set_res_id("ImageTextureRes")

func get_texture() -> CompressedTexture2D:
	return texture

func set_texture(new_texture: CompressedTexture2D) -> void:
	texture = new_texture

func get_height() -> int:
	return texture.get_width()

func get_width() -> int:
	return texture.get_width()

func get_size() -> Vector2:
	return texture.get_size()

func has_alpha() -> bool:
	return texture.has_alpha()

func get_format() -> Image.Format:
	return texture.get_format()


