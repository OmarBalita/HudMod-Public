class_name ColorScopeEditor extends EditorControl

signal calculation_finished()

@export var samples_down_scale: int = 1:
	set(val):
		samples_down_scale = val
		if not EditorServer.time_line.is_playing:
			curr_samples_down_scale = val
@export var inplay_samples_down_scale: int = 4:
	set(val):
		inplay_samples_down_scale = val
		if EditorServer.time_line.is_playing:
			curr_samples_down_scale = val

var curr_samples_down_scale: int = samples_down_scale:
	set(val):
		if val != curr_samples_down_scale:
			curr_samples_down_scale = val
			request_calculate(true)

var color_scope_sub_editors: Dictionary[StringName, ColorScopeSubEditor] = {
	&"histogram": HistogramEditor.new(),
	&"waveform": WaveformEditor.new(),
	&"parade": ParadeEditor.new(),
	#&"vector_scope": VectorScopeEditor.new()
}

var color_scope_sub_editors_visib: Array[bool] = [true, false, true]

var header_container: BoxContainer = IS.create_box_container(8)
var sub_editors_container: BoxContainer = IS.create_box_container(4, true)

var curr_image: Image
var curr_image_data: PackedByteArray
var is_calculating: bool


func get_curr_image() -> Image:
	return curr_image

func set_curr_image(new_image: Image) -> void:
	curr_image = new_image

func _ready_editor() -> void:
	super()
	
	var csse_keys: Array[StringName] = color_scope_sub_editors.keys()
	
	for index: int in color_scope_sub_editors.size():
		var key: StringName = csse_keys[index]
		var sub_editor: ColorScopeSubEditor = color_scope_sub_editors[key]
		var visibility: bool = color_scope_sub_editors_visib[index]
		
		var btn:= IS.create_bool_edit(key, visibility, Vector2(180., .0), 1)
		var btn_edit_box: IS.EditBoxContainer = IS.get_edit_box_from(btn)
		
		btn_edit_box.keyframable = false
		sub_editor.visible = visibility
		IS.expand(sub_editor, true, true)
		
		btn_edit_box.val_changed.connect(func(usable_res: UsableRes, key: StringName, new_val: Variant) -> void:
			var _request_calculate: bool = not color_scope_sub_editors_visib.has(true)
			color_scope_sub_editors_visib[index] = new_val
			sub_editor.visible = new_val
			if _request_calculate:
				request_calculate()
		)
		
		header_container.add_child(btn_edit_box)
		sub_editors_container.add_child(sub_editor)
	
	IS.expand(header_container, true, true)
	
	var header_scroll_container: ScrollContainer = IS.create_scroll_container(3, 0)
	header_scroll_container.add_child(header_container)
	header.add_child(header_scroll_container)
	body.add_child(sub_editors_container)
	
	ProjectServer.media_clips_changed.connect(_on_project_server_media_clips_changed)
	PlaybackServer.position_changed.connect(_on_playback_server_position_changed)
	PlaybackServer.played.connect(_on_playback_server_played)
	PlaybackServer.stopped.connect(_on_playback_server_stopped)
	EditorServer.properties.property_changed.connect(_on_properties_property_changed)
	
	visibility_changed.connect(_on_visibility_changed)
	
	request_calculate()


func _input(event: InputEvent) -> void:
	if (EditorServer.properties.get_global_rect().has_point(get_global_mouse_position()) and Input.get_mouse_button_mask() == 1) or PlaybackServer.is_playing():
		curr_samples_down_scale = inplay_samples_down_scale
	else:
		curr_samples_down_scale = samples_down_scale


func request_calculate(force: bool = false) -> void:
	if not is_visible_in_tree() or not color_scope_sub_editors_visib.has(true):
		return
	await get_tree().process_frame
	await get_tree().process_frame
	curr_image = Scene2.viewport.get_texture().get_image()
	curr_image.shrink_x2()
	var new_image_data: PackedByteArray = curr_image.get_data()
	if not force and curr_image_data == new_image_data:
		return
	curr_image_data = new_image_data
	if not curr_image or is_calculating:
		return
	WorkerThreadPool.add_task(calculate.bind(curr_image, curr_image_data, curr_samples_down_scale), true)
	is_calculating = true

func calculate(input: Image, raw_data: PackedByteArray, samples_down_scale: int) -> void:
	## C# Calculate Code
	##  اثبت اختبار الأداء التالي:
	## shrink_x2 = false, down_scale = 1: 0.3s Average
	## shrink_x2 = true, down_scale = 1: 0.12s Average
	finish_calculate.call_deferred(input, samples_down_scale, ColorScopeMath.Calculate(input, raw_data, samples_down_scale))
	
	## GDScript Calculate Code
	#var pixel_opacity: float = .03 * samples_down_scale
	#
	#var width: int = input.get_width()
	#var height: int = input.get_height()
	#var width_downscale: int = width / samples_down_scale
	#var height_downscale: int = height / samples_down_scale
	#
	#var histogram_data: PackedVector4Array
	#var waveform_data: Dictionary[int, PackedVector4Array]
	#var red_image:= Image.create_empty(width_downscale, 256, false, Image.FORMAT_LA8)
	#var green_image:= Image.create_empty(width_downscale, 256, false, Image.FORMAT_LA8)
	#var blue_image:= Image.create_empty(width_downscale, 256, false, Image.FORMAT_LA8)
	#var luminance_image:= Image.create_empty(width_downscale, 256, false, Image.FORMAT_LA8)
	#
	#histogram_data.resize(256)
	#
	#for x_step: int in width_downscale:
		#var x: int = x_step * samples_down_scale
		#var x_waveform_data: PackedVector4Array
		#x_waveform_data.resize(256)
		#waveform_data[x] = x_waveform_data
		#
		#for y_step: int in height_downscale:
			#var pixel: Color = input.get_pixel(x, y_step)
			#var r: float = pixel.r
			#var g: float = pixel.g
			#var b: float = pixel.b
			#var lum: float = r * .299 + g * .587 + b * .114
			#
			#var r_255: int = r * 255
			#var b_255: int = g * 255
			#var g_255: int = b * 255
			#var lum_255: int = lum * 255
			#
			#histogram_data[r_255].x += 1
			#histogram_data[g_255].y += 1
			#histogram_data[b_255].z += 1
			#histogram_data[lum_255].w += 1
			#
			#x_waveform_data[r_255].x += pixel_opacity
			#x_waveform_data[g_255].y += pixel_opacity
			#x_waveform_data[b_255].z += pixel_opacity
			#x_waveform_data[lum_255].w += pixel_opacity
		#
		#for y: int in 256:
			#var vec4: Vector4 = x_waveform_data[y]
			#var fixed_y: int = 255 - y
			#red_image.set_pixel(x_step, fixed_y, Color(Color.WHITE, vec4.x))
			#green_image.set_pixel(x_step, fixed_y, Color(Color.WHITE, vec4.y))
			#blue_image.set_pixel(x_step, fixed_y, Color(Color.WHITE, vec4.z))
			#luminance_image.set_pixel(x_step, fixed_y, Color(Color.WHITE, vec4.w))
	#
	#finish_calculate.call_deferred(input, samples_down_scale, {
		#&"resolution": Vector2i(width, height),
		#&"histogram": histogram_data,
		#&"waveform": waveform_data,
		#&"r_img": ImageTexture.create_from_image(red_image),
		#&"g_img": ImageTexture.create_from_image(green_image),
		#&"b_img": ImageTexture.create_from_image(blue_image),
		#&"lum_img": ImageTexture.create_from_image(luminance_image)
	#} as Dictionary[StringName, Variant])

func finish_calculate(input: Image, samples_down_scale: int, output: Dictionary[StringName, Variant]) -> void:
	color_scope_sub_editors.histogram.push_viewer_data(output)
	color_scope_sub_editors.waveform.push_viewer_data(output)
	color_scope_sub_editors.parade.push_viewer_data(output)
	
	is_calculating = false
	calculation_finished.emit()
	
	if input != curr_image or samples_down_scale != curr_samples_down_scale:
		request_calculate(true)


class ColorScopeSubEditor extends SplitContainer:
	var header: BoxContainer = IS.create_box_container(12, false, {})
	var body: MarginContainer = IS.create_margin_container(4, 4, 4, 4)
	
	var title: StringName
	var color_scope_viewer: ColorScopeViewer
	
	func _init() -> void:
		vertical = true
		dragging_enabled = false
		dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
	
	func _ready() -> void:
		var header_panel: PanelContainer = IS.create_panel_container(Vector2(.0, 32.0), IS.STYLE_CORNERLESS_DARK)
		var body_panel: PanelContainer = IS.create_panel_container(Vector2(), IS.STYLE_CORNERLESS_BLACK)
		var header_margin: MarginContainer = IS.create_margin_container(4, 4, 4, 4)
		var title_label: Label = IS.create_name_label(title)
		IS.expand(title_label)
		header.add_child(title_label)
		header_margin.add_child(header)
		body_panel.add_child(body)
		header_panel.add_child(header_margin)
		add_child(header_panel)
		add_child(body_panel)
		
		color_scope_viewer = new_color_scope_viewer()
		body.add_child(color_scope_viewer)
	
	func push_viewer_data(data: Dictionary[StringName, Variant]) -> void:
		color_scope_viewer.set_viewer_data(data)
	
	func new_color_scope_viewer() -> ColorScopeViewer:
		return null


class RGBLSubEditor extends ColorScopeSubEditor:
	@export var draw_r: bool = true:
		set(val): draw_r = val; color_scope_viewer.update_viewer()
	@export var draw_g: bool = true:
		set(val): draw_g = val; color_scope_viewer.update_viewer()
	@export var draw_b: bool = true:
		set(val): draw_b = val; color_scope_viewer.update_viewer()
	@export var draw_lum: bool:
		set(val): draw_lum = val; color_scope_viewer.update_viewer()
	
	func _ready() -> void:
		super()
		var r_btn: Button = IS.create_button("R", null, false, true, {toggle_mode = true, button_pressed = draw_r, custom_minimum_size = Vector2(64., .0)})
		var g_btn: Button = IS.create_button("G", null, false, true, {toggle_mode = true, button_pressed = draw_g, custom_minimum_size = Vector2(64., .0)})
		var b_btn: Button = IS.create_button("B", null, false, true, {toggle_mode = true, button_pressed = draw_b, custom_minimum_size = Vector2(64., .0)})
		var lum_btn: Button = IS.create_button("Lum", null, false, true, {toggle_mode = true, button_pressed = draw_lum, custom_minimum_size = Vector2(64., .0)})
		r_btn.pressed.connect(func() -> void: draw_r = r_btn.button_pressed)
		g_btn.pressed.connect(func() -> void: draw_g = g_btn.button_pressed)
		b_btn.pressed.connect(func() -> void: draw_b = b_btn.button_pressed)
		lum_btn.pressed.connect(func() -> void: draw_lum = lum_btn.button_pressed)
		IS.add_children(header, [r_btn, g_btn, b_btn, lum_btn])

class HistogramEditor extends RGBLSubEditor:
	
	func _init() -> void:
		super()
		title = &"Histogram"
	
	func new_color_scope_viewer() -> ColorScopeViewer:
		return HistogramViewer.new(self)

class WaveformEditor extends RGBLSubEditor:
	
	func _init() -> void:
		super()
		title = &"Waveform"
	
	func new_color_scope_viewer() -> ColorScopeViewer:
		return WaveformViewer.new(self)

class ParadeEditor extends RGBLSubEditor:
	
	func _init() -> void:
		super()
		title = &"Parade"
	
	func new_color_scope_viewer() -> ColorScopeViewer:
		return ParadeViewer.new(self)

class VectorScopeEditor extends ColorScopeSubEditor:
	
	func _init() -> void:
		super()
		title = &"Vector Scope"
	
	func new_color_scope_viewer() -> ColorScopeViewer:
		return VectorScopeViewer.new(self)

class ColorScopeViewer extends Control:
	var editor: ColorScopeSubEditor
	
	var viewer_data: Dictionary[StringName, Variant]
	
	func _init(_editor: ColorScopeSubEditor) -> void:
		editor = _editor
	
	func set_viewer_data(data: Dictionary[StringName, Variant]) -> void:
		viewer_data = data
		queue_redraw()
	
	func update_viewer() -> void:
		queue_redraw()

class HistogramViewer extends ColorScopeViewer:
	var histogram_data: PackedVector4Array
	func set_viewer_data(data: Dictionary[StringName, Variant]) -> void:
		histogram_data = data.histogram
		super(data)
	
	func _draw() -> void:
		var lines_steps: int = 8
		var steps_between_dist: int = 256 / lines_steps
		var font: Font = IS.LABEL_SETTINGS_MAIN.font
		
		for step: int in lines_steps + 1:
			var index: int = min(255, step * steps_between_dist)
			var index_str: String = str(index)
			var x: float = size.x * (index / 256.0)
			draw_line(Vector2(x, .0), Vector2(x, size.y), Color.DIM_GRAY, 2.0)
			draw_string(font, Vector2(min(x + 3.0, size.x - (index_str.length() * 10.)), 20.0), index_str, 0, -1, 14, Color.GRAY)
		
		if histogram_data.is_empty():
			return
		
		var dist_between: float = size.x / 256.0
		
		var point_start: Vector2 = Vector2(.0, size.y + 1.0)
		var point_end: Vector2 = size + Vector2.DOWN
		
		var packed_r_array: PackedVector2Array = [point_start]
		var packed_g_array: PackedVector2Array = [point_start]
		var packed_b_array: PackedVector2Array = [point_start]
		var packed_lum_array: PackedVector2Array = [point_start]
		
		var max_val: int = 0
		for index: int in 256:
			max_val = max(
				max_val,
				histogram_data[index].x,
				histogram_data[index].y,
				histogram_data[index].z,
				histogram_data[index].w
			)
		
		for index: int in range(1, 256):
			var x: float = index * dist_between
			var rgb_y: Vector4 = get_rgb_h(index, max_val) * size.y
			
			packed_r_array.append(Vector2(x, rgb_y.x))
			packed_g_array.append(Vector2(x, rgb_y.y))
			packed_b_array.append(Vector2(x, rgb_y.z))
			packed_lum_array.append(Vector2(x, rgb_y.w))
		
		packed_r_array.append(point_end)
		packed_g_array.append(point_end)
		packed_b_array.append(point_end)
		packed_lum_array.append(point_end)
		
		if editor.draw_r:
			draw_polygon(packed_r_array, PackedColorArray([Color(Color.RED, .3)]))
			draw_polyline(packed_r_array, Color.RED)
		if editor.draw_g:
			draw_polygon(packed_g_array, PackedColorArray([Color(Color.LIME_GREEN, .3)]))
			draw_polyline(packed_g_array, Color.LIME_GREEN)
		if editor.draw_b:
			draw_polygon(packed_b_array, PackedColorArray([Color(Color.BLUE, .3)]))
			draw_polyline(packed_b_array, Color.BLUE)
		if editor.draw_lum:
			draw_polygon(packed_lum_array, PackedColorArray([Color(Color.WHITE, .3)]))
			draw_polyline(packed_lum_array, Color.WHITE)
	
	func get_rgb_h(index: int, max_val: int) -> Vector4:
		return Vector4.ONE - (histogram_data[index]) / float(max_val)

class WaveformViewer extends ColorScopeViewer:
	
	var red_texture_rect: TextureRect = IS.create_texture_rect(null, {expand_mode = TextureRect.EXPAND_IGNORE_SIZE, modulate = Color.RED, texture_filter = TEXTURE_FILTER_NEAREST})
	var green_texture_rect: TextureRect = IS.create_texture_rect(null, {expand_mode = TextureRect.EXPAND_IGNORE_SIZE, modulate = Color.LIME_GREEN, texture_filter = TEXTURE_FILTER_NEAREST})
	var blue_texture_rect: TextureRect = IS.create_texture_rect(null, {expand_mode = TextureRect.EXPAND_IGNORE_SIZE, modulate = Color.BLUE, texture_filter = TEXTURE_FILTER_NEAREST})
	var luminance_texture_rect: TextureRect = IS.create_texture_rect(null, {expand_mode = TextureRect.EXPAND_IGNORE_SIZE})
	
	func _ready() -> void:
		red_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		green_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		blue_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		luminance_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		IS.add_children(self, [luminance_texture_rect, red_texture_rect, green_texture_rect, blue_texture_rect])
		update_viewer()
	
	func set_viewer_data(data: Dictionary[StringName, Variant]) -> void:
		super(data)
		if data:
			red_texture_rect.texture = data.r_img
			green_texture_rect.texture = data.g_img
			blue_texture_rect.texture = data.b_img
			luminance_texture_rect.texture = data.lum_img
	
	func update_viewer() -> void:
		queue_redraw()
		red_texture_rect.visible = editor.draw_r
		green_texture_rect.visible = editor.draw_g
		blue_texture_rect.visible = editor.draw_b
		luminance_texture_rect.visible = editor.draw_lum
	
	func _draw() -> void:
		var lines_steps: int = 4
		var steps_between_dist: int = 256 / lines_steps
		var font: Font = IS.LABEL_SETTINGS_MAIN.font
		for step: int in lines_steps + 1:
			var index: int = min(255, step * steps_between_dist)
			var index_str: String = str(255 - index)
			var y: float = size.y * (index / 256.0)
			draw_line(Vector2(.0, y), Vector2(size.x, y), Color.DIM_GRAY, 2.0)
			draw_string(font, Vector2(5.0, y), index_str, 0, -1, 14, Color.GRAY)

class ParadeViewer extends WaveformViewer:
	
	var parade_box_container: BoxContainer = IS.create_box_container(0)
	
	func _ready() -> void:
		IS.expand(luminance_texture_rect, true)
		IS.expand(red_texture_rect, true)
		IS.expand(green_texture_rect, true)
		IS.expand(blue_texture_rect, true)
		IS.add_children(parade_box_container, [luminance_texture_rect, red_texture_rect, green_texture_rect, blue_texture_rect])
		parade_box_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(parade_box_container)
		update_viewer()

class VectorScopeViewer extends ColorScopeViewer:
	
	func _draw() -> void:
		var center_pos: Vector2 = size / 2.
		var circle_radius: float = min(size.x, size.y) / 2.
		draw_circle(center_pos, circle_radius, Color.DIM_GRAY, false, 2.)
		draw_circle(center_pos, 5., Color.WHITE, true, -1., true)

func _on_project_server_media_clips_changed() -> void:
	curr_samples_down_scale = inplay_samples_down_scale

func _on_playback_server_position_changed(position: int) -> void:
	request_calculate()

func _on_playback_server_played(at: int) -> void:
	curr_samples_down_scale = inplay_samples_down_scale

func _on_playback_server_stopped(at: int) -> void:
	curr_samples_down_scale = samples_down_scale

func _on_properties_property_changed() -> void:
	request_calculate()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		request_calculate()
