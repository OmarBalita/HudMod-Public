class_name PopupedColorController extends PopupedControl

signal color_changed(new_color: Color)

enum State {IDLE, PICK_COLOR}

@export_group("Theme")
@export_subgroup("Texture")
@export var texture_color_picker: Texture2D = preload("res://Asset/Icons/tool.png")
@export var texture_add_palette: Texture2D = preload("res://Asset/Icons/plus.png")

# RealTime Variables

var curr_color: Color = Color.BLACK:
	set(val):
		curr_color = val
		if is_node_ready():
			update()
		color_changed.emit(curr_color)

var curr_state: State = 0

var built_in_color_palettes: Array = [
  ColorPaletteRes.new_res("Material Design Bright", ["#f44336","#e81e63","#9c27b0","#673ab7","#3f51b5","#2196f3","#03a9f4","#00bcd4","#009688","#4caf50","#8bc34a","#cddc39"]),
  ColorPaletteRes.new_res("Material Design Warm", ["#ffc107","#ff9800","#ff5722","#795548","#9e9e9e","#607d8b","#000000"]),
  ColorPaletteRes.new_res("Dreamy Pastel", ["#f8f29a","#a5ce7c","#f7f4d4","#f7bfb8","#b3aede","#c3e9f8"]),
  ColorPaletteRes.new_res("Summer Sea", ["#e3caa2","#f0e1cc","#73bdbc","#0d96ba","#167997"]),
  ColorPaletteRes.new_res("Vintage Summer", ["#00896f","#99bf72","#f4df9e","#e38f2d","#d45d37"]),
  ColorPaletteRes.new_res("Blissful Summer", ["#65ae39","#8cbe69","#f3dd25","#eebf25","#e69489","#aa7fa5"]),
  ColorPaletteRes.new_res("Summer Pool Party", ["#0198f1","#49c2ff","#a9eeff","#0067d4","#e999de","#7c62c4"]),
  ColorPaletteRes.new_res("Summer Festival", ["#01a7ec","#ffff46","#ffc94b","#fe8f5d","#fe47b3","#80da65"]),
  ColorPaletteRes.new_res("Rustic Brown & Green", ["#102820","#4c6444","#caba9c","#8a6240","#4d2d18"]),
  ColorPaletteRes.new_res("Burgundy & Earth Tones", ["#8c1127","#a68e80","#a65437","#592418","#26130f"]),
  ColorPaletteRes.new_res("Forest Harvest", ["#385248","#f29849","#f27c38","#732d14","#0d0d0d"]),
  ColorPaletteRes.new_res("Rustic Autumn", ["#385928","#f2c063","#bf7c41","#8c512e","#26120b"]),
  ColorPaletteRes.new_res("Rustic Charm", ["#261c0f","#a6886d","#bf7245","#a6360d","#731b07"]),
  ColorPaletteRes.new_res("Rainy Day Coziness", ["#03060d","#2d4d59","#6593a6","#aabbbf","#d5dde1","#f0f4f7"]),
  ColorPaletteRes.new_res("Cappuccino", ["#a68f78","#c3b091","#e0d7c5","#f2ebe2","#8b6d5c","#5a432e"]),
  ColorPaletteRes.new_res("Beach Pastel Rainbow", ["#ff9fb1","#ffd47f","#ffffc1","#c1ffcf","#a7d8ff","#d8baff"]),
  ColorPaletteRes.new_res("Beautiful Blues", ["#083d77","#085f63","#08a045","#51c17b","#a8e890","#d6f5c1"]),
  ColorPaletteRes.new_res("Shades of Teal", ["#004d4d","#006666","#008080","#009999","#00cccc","#33ffff"]),
  ColorPaletteRes.new_res("Ice Cream Pastels", ["#ffd3e0","#ffe1a8","#e1ffd3","#d3e1ff","#f0d3ff","#ffdfe1"]),
  ColorPaletteRes.new_res("VaporWave Neon", ["#ff6ec7","#9d65c9","#65c9dd","#65e4c9","#c9ff65","#6eff65"])
]

var custom_color_palettes: Array


# RealTime Nodes

var save_component: SaveComponent

# Right Side (Color Palettes)
var color_palettes_box: BoxContainer
var add_palette_button: Button

# Left Side (Color Control)
var rgb_box: BoxContainer
var hsv_box: BoxContainer

var color_shape: VHSCircleShape
var color_val_line: ValLine
var before_color_rect: ColorRect
var after_color_rect: ColorRect
var color_picker_button: IS.CustomTextureButton

var red_controller: SliderControl
var green_controller: SliderControl
var blue_controller: SliderControl
var hue_controller: SliderControl
var sat_controller: SliderControl
var val_controller: SliderControl
var alpha_controller: SliderControl

var hex_line: LineEdit

var type_menu: Menu



func _ready() -> void:
	
	# PopupControl
	popup_speed = .2
	popdown_speed = .1
	super()
	
	# Save Component
	save_component = SaveComponent.new()
	save_component.properties = ["custom_color_palettes"]
	save_component.save_path = EditorServer.editor_path + "color_palettes.tres"
	add_child(save_component)
	
	save_component.load_data()
	
	
	# Start Color Controller Editor
	var rgb_step = 1.0 / 255
	
	var margin_container = IS.create_margin_container()
	var split_container = IS.create_split_container(10)
	
	var controller_box = IS.create_box_container(10, true)
	
	var color_palettes_scroll_controller = IS.create_scroll_container(1, 1, {custom_minimum_size = Vector2(310, 0)})
	var color_palettes_margin_container = IS.create_margin_container(12, 12, 12, 12, {size_flags_horizontal = Control.SIZE_EXPAND_FILL})
	var color_palette_split_container = IS.create_split_container(2, true)
	color_palettes_box = IS.create_box_container(10, true)
	add_palette_button = IS.create_button("Add New Color Palette", texture_add_palette, true)
	
	var color_control_box = IS.create_box_container()
	var color_display_box = IS.create_box_container()
	rgb_box = IS.create_box_container(10, true)
	hsv_box = IS.create_box_container(10, true)
	
	color_shape = VHSCircleShape.new(curr_color.h, curr_color.s, curr_color.v)
	color_val_line = ValLine.new(curr_color.v)
	
	before_color_rect = IS.create_color_rect(curr_color, {custom_minimum_size = Vector2(100, 0)})
	after_color_rect = IS.create_color_rect(curr_color, {custom_minimum_size = Vector2(100, 0)})
	color_picker_button = IS.create_texture_button(texture_color_picker, null, null, true)
	
	red_controller = IS.create_float_edit("R", true, false, curr_color.r, .0, 1.0, rgb_step)[0]
	green_controller = IS.create_float_edit("G", true, false, curr_color.g, .0, 1.0, rgb_step)[0]
	blue_controller = IS.create_float_edit("B", true, false, curr_color.b, .0, 1.0, rgb_step)[0]
	
	hue_controller = IS.create_float_edit("H", true, false, curr_color.h, .0, 1.0, 1.0 / 360)[0]
	sat_controller = IS.create_float_edit("S", true, false, curr_color.s, .0, 1.0, .01)[0]
	val_controller = IS.create_float_edit("V", true, false, curr_color.v, .0, 1.0, .01)[0]
	alpha_controller = IS.create_float_edit("A", true, false, curr_color.a, .0, 1.0, .01)[0]
	
	hex_line = IS.create_line_edit("Hex", curr_color.to_html())
	
	type_menu = IS.create_menu([
		MenuOption.new("RGB"),
		MenuOption.new("HSV")
	], false, {custom_minimum_size = Vector2(0, 40)})
	
	# Spawn UI Nodes
	color_control_box.add_child(color_shape)
	color_control_box.add_child(color_val_line)
	
	color_display_box.add_child(before_color_rect)
	color_display_box.add_child(after_color_rect)
	color_display_box.add_child(color_picker_button)
	
	rgb_box.add_child(red_controller.get_parent())
	rgb_box.add_child(green_controller.get_parent())
	rgb_box.add_child(blue_controller.get_parent())
	hsv_box.add_child(hue_controller.get_parent())
	hsv_box.add_child(sat_controller.get_parent())
	hsv_box.add_child(val_controller.get_parent())
	
	controller_box.add_child(color_control_box)
	controller_box.add_child(color_display_box)
	controller_box.add_child(rgb_box)
	controller_box.add_child(hsv_box)
	controller_box.add_child(alpha_controller.get_parent())
	controller_box.add_child(hex_line)
	controller_box.add_child(type_menu)
	
	color_palettes_margin_container.add_child(color_palettes_box)
	color_palettes_scroll_controller.add_child(color_palettes_margin_container)
	
	color_palette_split_container.add_child(add_palette_button)
	color_palette_split_container.add_child(color_palettes_scroll_controller)
	
	split_container.add_child(controller_box)
	split_container.add_child(color_palette_split_container)
	margin_container.add_child(split_container)
	add_child(margin_container)
	
	# Connections
	popdowned.connect(save)
	
	color_shape.val_changed.connect(on_color_shape_val_changed)
	color_val_line.val_changed.connect(on_color_val_line_val_changed)
	color_picker_button.pressed.connect(on_color_picker_button_pressed)
	red_controller.slider_controller.val_changed.connect(on_red_slider_val_changed)
	green_controller.slider_controller.val_changed.connect(on_green_slider_val_changed)
	blue_controller.slider_controller.val_changed.connect(on_blue_slider_val_changed)
	hue_controller.slider_controller.val_changed.connect(on_hue_slider_val_changed)
	sat_controller.slider_controller.val_changed.connect(on_sat_slider_val_changed)
	val_controller.slider_controller.val_changed.connect(on_val_slider_val_changed)
	alpha_controller.slider_controller.val_changed.connect(on_alpha_slider_val_changed)
	type_menu.focus_index_changed.connect(on_type_menu_focus_index_changed)
	hex_line.text_submitted.connect(on_hex_line_text_changed)
	
	add_palette_button.pressed.connect(on_add_palette_button_pressed)
	
	hex_line.grab_focus()
	hex_line.select()
	
	# Update/Spawn Palettes Boxes
	spawn_built_in_palettes()
	update_custom_palettes()
	

func _input(event: InputEvent) -> void:
	
	if curr_state == 1:
		if event is InputEventMouse:
			set_curr_color(get_picked_color())
			if event is InputEventMouseButton:
				curr_state = 0
				color_picker_button.change_button_pressed(false)
	else: super(event)



func get_curr_color() -> Color:
	return curr_color

func set_curr_color(color: Color) -> void:
	curr_color = color

func get_picked_color() -> Color:
	var pos_from = get_global_mouse_position() * ProjectSettings.get_setting("display/window/stretch/scale")
	var pick_pos = Vector2i(pos_from)
	var image: Image = get_viewport().get_texture().get_image()
	return image.get_pixelv(pick_pos)

func update() -> void:
	red_controller.slider_controller.set_curr_val_manually(curr_color.r)
	green_controller.slider_controller.set_curr_val_manually(curr_color.g)
	blue_controller.slider_controller.set_curr_val_manually(curr_color.b)
	hue_controller.slider_controller.set_curr_val_manually(curr_color.h)
	sat_controller.slider_controller.set_curr_val_manually(curr_color.s)
	val_controller.slider_controller.set_curr_val_manually(curr_color.v)
	
	color_shape.update(curr_color.h, curr_color.s, curr_color.v)
	color_val_line.update(curr_color.v)
	
	after_color_rect.set_color(curr_color)
	hex_line.set_text(curr_color.to_html())

func create_new_palette(palette_name: String, built_in: bool, colors: Array) -> void:
	var new_color_palette_res = ColorPaletteRes.new_res(palette_name, colors, built_in)
	custom_color_palettes.append(new_color_palette_res)
	save()

func spawn_palette_box(color_palette_res: ColorPaletteRes) -> PaletteBox:
	var palette_box = PaletteBox.new()
	palette_box.color_palette = color_palette_res
	palette_box.control_root = self
	palette_box.color_selected.connect(set_curr_color)
	palette_box.palette_removed.connect(update_custom_palettes)
	color_palettes_box.add_child(palette_box)
	return palette_box

func spawn_built_in_palettes() -> void:
	for color_palette_res: ColorPaletteRes in built_in_color_palettes:
		spawn_palette_box(color_palette_res)

func update_custom_palettes() -> void:
	
	var color_palettes_spawned_already: Array[ColorPaletteRes]
	
	for child in color_palettes_box.get_children():
		var color_palette = child.color_palette
		if custom_color_palettes.has(color_palette) or built_in_color_palettes.has(color_palette):
			color_palettes_spawned_already.append(color_palette)
			continue
		child.queue_free()
	
	for color_palette_res: ColorPaletteRes in custom_color_palettes:
		if not color_palettes_spawned_already.has(color_palette_res):
			var palette_box = spawn_palette_box(color_palette_res)
			color_palettes_box.move_child(palette_box, 0)

func save() -> void:
	save_component.save_data()




func on_color_shape_val_changed(new_hue: float, new_sat: float) -> void:
	curr_color.h = new_hue
	curr_color.s = new_sat

func on_color_val_line_val_changed(new_val: float) -> void:
	curr_color.v = new_val

func on_color_picker_button_pressed() -> void:
	curr_state = 1

func on_red_slider_val_changed(new_val: float) -> void:
	curr_color.r = new_val

func on_green_slider_val_changed(new_val: float) -> void:
	curr_color.g = new_val

func on_blue_slider_val_changed(new_val: float) -> void:
	curr_color.b = new_val

func on_hue_slider_val_changed(new_val: float) -> void:
	curr_color.h = new_val

func on_sat_slider_val_changed(new_val: float) -> void:
	curr_color.s = new_val

func on_val_slider_val_changed(new_val: float) -> void:
	curr_color.v = new_val

func on_alpha_slider_val_changed(new_val: float) -> void:
	curr_color.a = new_val

func on_type_menu_focus_index_changed(index: int) -> void:
	rgb_box.visible = not index
	hsv_box.visible = index

func on_hex_line_text_changed(new_val: String) -> void:
	curr_color = Color.html(new_val)

func on_add_palette_button_pressed() -> void:
	var name_edit = IS.create_line_edit("Type Palette Name", "New Palette")
	
	var on_accept_button_pressed = func() -> void:
		create_new_palette(name_edit.get_text(), false, [])
		update_custom_palettes()
	var window = WindowManager.popup_accept_window(get_window(), Vector2(400, 150), "Create New Palette", on_accept_button_pressed)
	window.add_child(name_edit)
	
	name_edit.select()
	name_edit.grab_focus()





class VHSCircleShape extends Control:
	
	signal val_changed(new_hue: float, new_sat: float)
	
	@export var radius: float = 120.0:
		set(val):
			radius = val
			update_properties()
	
	var hue: float
	var sat: float
	var val: float
	
	var dragged: bool
	
	func _init(_hue: float, _sat: float, _val: float) -> void:
		update(_hue, _sat, _val)
	
	func _ready() -> void:
		# Set Base Settings
		update_properties()
	
	func _input(event: InputEvent) -> void:
		
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var dist_to_center = (get_local_mouse_position() - size / 2.0).length()
				if dist_to_center <= radius:
					dragged = event.is_pressed()
					update_from_display_point()
				else: dragged = false
		
		elif event is InputEventMouseMotion:
			if dragged:
				update_from_display_point()
				val_changed.emit(hue, sat)
	
	func _draw() -> void:
		
		var center = size / 2.0
		var pixel_size = Vector2.ONE * radius / 100.0 * 2.0
		
		for h in 360:
			for s in 100:
				var hue = h / 360.0
				var sat = s / 100.0
				var rect_pos = Vector2(cos(deg_to_rad(h)), sin(deg_to_rad(h))) * sat * radius
				draw_rect(Rect2(center + rect_pos, pixel_size), Color.from_hsv(hue, sat, val), true, -1.0, s + 1 == 100)
		
		var angle_rad = TAU * hue
		var display_offset = Vector2(cos(angle_rad), sin(angle_rad)) * sat * radius
		draw_circle(center + display_offset, 5.0, Color.BLACK)
		draw_circle(center + display_offset, 6.0, IS.COLOR_ACCENT_BLUE, false, 2.0, true)
	
	func update_properties() -> void:
		custom_minimum_size = Vector2.ONE * radius * 2.1
	
	func update(_hue: float, _sat: float, _val: float) -> void:
		hue = _hue
		sat = _sat
		val = _val
		queue_redraw()
	
	func update_from_display_point(point = null) -> void:
		
		if point == null:
			point = get_local_mouse_position()
		
		var center = size / 2.0
		var offset = point - center
		var angle = atan2(offset.y, offset.x)
		if angle < 0.0:
			angle += TAU
		
		hue = angle / TAU
		sat = clamp(offset.length() / radius, 0.0, 1.0)
		
		queue_redraw()





class ValLine extends Control:
	
	signal val_changed(new_val: float)
	
	var val: float
	
	var dragged: bool
	
	var width: float = 20.0:
		set(val):
			width = val
			queue_redraw()
	
	var length: float = 240.0:
		set(val):
			length = val
			queue_redraw()
	
	func _init(_val: float) -> void:
		update(_val)
	
	func _ready() -> void:
		custom_minimum_size = Vector2(width, length)
	
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if get_global_rect().has_point(get_global_mouse_position()):
					dragged = event.is_pressed()
					update_from_display_point()
				else: dragged = false
		
		elif event is InputEventMouseMotion:
			if dragged:
				update_from_display_point()
				val_changed.emit(val)
	
	func _draw() -> void:
		
		var y_step = length / 100.0
		
		var radius = width / 2.0
		var y_displacement = radius / 2.0
		draw_circle(Vector2(radius, y_displacement), radius, Color.WHITE, true, -1.0, true)
		draw_circle(Vector2(radius, length + y_displacement), radius, Color.BLACK, true, -1.0, true)
		
		for v in 100:
			var val = v / 100.0
			var y_pos = v * y_step
			draw_rect(Rect2(Vector2(.0, length - y_pos + y_displacement), Vector2(width, y_step)), Color.from_hsv(.0, .0, val), true, -1.0, true)
		
		var cursor_display_pos = length - length * val + y_displacement
		draw_line(Vector2(-2, cursor_display_pos), Vector2(width + 2, cursor_display_pos), IS.COLOR_ACCENT_BLUE, 5.0, true)
	
	func update(_val: float) -> void:
		val = _val
		queue_redraw()
	
	func update_from_display_point(point = null) -> void:
		if point == null:
			point = get_local_mouse_position()
		val = clamp(1.0 - point.y / length, 0.0, 1.0)
		queue_redraw()




class PaletteBox extends PanelContainer:
	
	signal color_added(color: Color)
	signal color_removed(color: Color)
	signal palette_removed()
	signal color_selected(color: Color)
	
	@export var color_palette: ColorPaletteRes
	
	@export_group("Theme")
	@export_subgroup("Texture", "texture")
	@export var texture_add = preload("res://Asset/Icons/add.png")
	@export var texture_remove = preload("res://Asset/Icons/trash-can.png")
	
	# RealTime Nodes
	var control_root: PopupedColorController
	
	var add_color_button: TextureButton
	var name_label: Label
	var remove_palette_button: TextureButton
	var colors_grid_container: FlexGridContainer
	
	func _ready() -> void:
		# Set Base Settings
		IS.set_base_panel_settings(self, IS.STYLE_BUTTON)
		
		# Start Controls
		var margin_container = IS.create_margin_container(4, 4, 4, 4)
		var split_container = IS.create_split_container(4, true)
		var header_box = IS.create_box_container()
		
		name_label = IS.create_name_label(color_palette.palette_name)
		colors_grid_container = IS.create_grid_container(Vector2(32, 32))
		
		if not color_palette.built_in:
			add_color_button = IS.create_texture_button(texture_add)
			remove_palette_button = IS.create_texture_button(texture_remove)
			header_box.add_child(add_color_button)
			header_box.add_child(remove_palette_button)
			add_color_button.pressed.connect(on_add_color_button_pressed)
			remove_palette_button.pressed.connect(on_remove_palette_button_pressed)
		header_box.add_child(name_label)
		
		split_container.add_child(header_box)
		split_container.add_child(colors_grid_container)
		margin_container.add_child(split_container)
		add_child(margin_container)
		
		IS.expand(name_label)
		
		# Spawn Color Buttons
		update_colors()
	
	
	func spawn_color(color: Color) -> SavedColorButton:
		var color_button = SavedColorButton.new(color)
		colors_grid_container.add_child(color_button)
		color_button.pressed.connect(on_color_button_pressed.bind(color))
		color_button.remove_requested.connect(on_color_remove_requested.bind(color))
		return color_button
	
	func update_colors() -> void:
		for child in colors_grid_container.get_children():
			child.queue_free()
		for color: Color in color_palette.colors:
			spawn_color(color)
	
	
	func on_add_color_button_pressed() -> void:
		var color = control_root.curr_color
		color_palette.colors.append(color)
		control_root.save()
		update_colors()
		color_added.emit(color)
		printt("add new color to the palette !", color)
	
	func on_remove_palette_button_pressed() -> void:
		control_root.custom_color_palettes.erase(color_palette)
		palette_removed.emit()
		print("remove palette it self !")
	
	func on_color_button_pressed(color: Color) -> void:
		color_selected.emit(color)
	
	func on_color_remove_requested(color: Color) -> void:
		if color_palette.built_in: return
		if color in color_palette.colors:
			color_palette.colors.erase(color)
			control_root.save()
			update_colors()
			color_removed.emit(color)
			printt("remove color from the palette", color)
	
	
	class SavedColorButton extends Button:
		
		signal remove_requested()
		
		var color: Color
		
		# RealTime Variables
		var radius_scale: float = 1.0
		
		func _init(_color: Color) -> void:
			color = _color
		
		func _ready() -> void:
			# Set Base Settings
			IS.set_button_style(self)
			custom_minimum_size = Vector2(32, 32)
			flat = true
			# Connections
			mouse_entered.connect(on_mouse_entered)
			mouse_exited.connect(on_mouse_exited)
		
		func _gui_input(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_RIGHT:
					remove_requested.emit()
		
		func _draw() -> void:
			var half_size = size / 2.0
			draw_circle(half_size, half_size.length() / 2.0 * radius_scale, color, true, -1.0, true)
		
		func on_mouse_entered() -> void:
			radius_scale = 1.2
			queue_redraw()
		
		func on_mouse_exited() -> void:
			radius_scale = 1.0
			queue_redraw()







