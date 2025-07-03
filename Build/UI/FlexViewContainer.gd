class_name FlexViewContainer extends SubViewportContainer

func _ready() -> void:
	resized.connect(on_resized)
	on_resized()

func on_resized() -> void:
	var viewport: SubViewport = null
	for child in get_children():
		if child is SubViewport:
			viewport = child
			break
	if not viewport:
		return
	
	var viewport_size = viewport.size
	
	# احسب نسبة التحجيم المطلوبة (تصغير أو تكبير حسب الحاجة)
	var scale_ratio = minf(
		get_parent().size.x / viewport_size.x,
		get_parent().size.y / viewport_size.y
	)
	
	print(get_parent().size.x)
	print(get_parent().size.y)
	
	# طبق التحجيم
	scale = Vector2.ONE * scale_ratio








