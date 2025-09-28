class_name FlexViewportControl extends FocusControl

@export var enabled: bool = true:
	set(val):
		enabled = val
		viewport_container.stretch = not val
		on_resized()
@export var viewport_container: SubViewportContainer

func _init() -> void:
	clip_contents = true

func _ready() -> void:
	super()
	resized.connect(on_resized)

func _draw() -> void:
	super()
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)

func on_resized() -> void:
	
	if not viewport_container: return
	
	if enabled:
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
	else:
		viewport_container.scale = Vector2.ONE
		viewport_container.position = Vector2.ZERO
		viewport_container.size = size










