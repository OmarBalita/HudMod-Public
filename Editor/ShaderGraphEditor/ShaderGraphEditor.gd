class_name ShaderGraphEditor extends GraphEditorControl


func _ready() -> void:
	super()
	set_graph_node_options({
		MenuOption.new("Input"): [
			MenuOption.new("UV"),
			MenuOption.new("Color"),
			MenuOption.new("Time"),
			MenuOption.new("Vertex"),
			MenuOption.new("Texture Size"),
			MenuOption.new("Screen Size"),
			MenuOption.new("Screen UV"),
			MenuOption.new("Mouse Pos")
		],
		MenuOption.new("Variables"): [
			MenuOption.new("Integer"),
			MenuOption.new("Float"),
			MenuOption.new("Vector2"),
			MenuOption.new("Vector3"),
			MenuOption.new("Vector4"),
			MenuOption.new("Color"),
			MenuOption.new("Image Texture"),
			MenuOption.new("ColorRange Texture"),
			MenuOption.new("Noise Texture")
		],
		MenuOption.new("Math"): [
			MenuOption.new("Math Operator"),
			MenuOption.new("Math Function"),
			MenuOption.new("Invert")
		],
		MenuOption.new("Transform"): [
			MenuOption.new("UV Mapping"),
			MenuOption.new("UV Polar Coord"),
			MenuOption.new("SDF to ScreenUV"),
			MenuOption.new("ScreenUV to SDF"),
		],
		MenuOption.new("Color"): [
			MenuOption.new("Tint"),
			MenuOption.new("Brightness / Contrast"),
			MenuOption.new("Gamma"),
			MenuOption.new("Hue / Saturation / Value"),
			MenuOption.new("Replace Color")
		],
		MenuOption.new("Effect"): [
			MenuOption.new("Blur"),
			MenuOption.new("Sharpen"),
			MenuOption.new("Glitch"),
			MenuOption.new("Pixelate"),
			MenuOption.new("Posterize"),
			MenuOption.new("Vignette")
		]
	})

func on_options_menu_menu_button_pressed(menu_option: MenuOption) -> void:
	super(menu_option)
	spawn_node(create_node(menu_option.text))

