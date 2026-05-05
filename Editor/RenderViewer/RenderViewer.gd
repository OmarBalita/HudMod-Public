#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
##  This program is free software: you can redistribute it and/or modify   ##
##  it under the terms of the GNU General Public License as published by   ##
##  the Free Software Foundation, either version 3 of the License, or      ##
##  (at your option) any later version.                                    ##
##                                                                         ##
##  This program is distributed in the hope that it will be useful,        ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
##  GNU General Public License for more details.                           ##
##                                                                         ##
##  You should have received a copy of the GNU General Public License      ##
##  along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
class_name RenderViewer extends EditorControl

@onready var viewport_cont: RenderViewerViewportContainer = RenderViewerViewportContainer.new(self)
@onready var viewport: SubViewport = SubViewport.new()
@onready var render_sprite: Sprite2D = Sprite2D.new()
@onready var camera: Camera2D = Camera2D.new()

@onready var bottom_cont: BoxContainer = IS.create_box_container(2, true)

@onready var view_cont: BoxContainer = IS.create_box_container(8)
@onready var center_btn: IS.CustomTextureButton = IS.create_texture_button(preload("res://Asset/Icons/world-origin.png"), null, null, "Center")
@onready var grid_btn: IS.CustomTextureButton = IS.create_texture_button(preload("res://Asset/Icons/_grid.png"), null, null, "Grid", true)
@onready var transform_label: Label = IS.create_label("")

@onready var control_cont: BoxContainer = IS.create_box_container()
@onready var render_progress_label: Label = IS.create_label("")
@onready var render_progress_bar: ProgressBar = IS.create_progress_bar(.0, .0, 100., .01)

@export var zoom_speed: float = .05
@export var zoom_min: float = .01
@export var zoom_max: float = 100.

var button_event: InputEventMouseButton

func _ready_editor() -> void:
	
	viewport_cont.stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	render_sprite.texture = Scene2.viewport.get_texture()
	camera.zoom = Vector2(.5, .5)
	
	body.add_child(viewport_cont)
	viewport_cont.add_child(viewport)
	viewport.add_child(render_sprite)
	viewport.add_child(camera)
	
	bottom_cont.size_flags_vertical = Control.SIZE_SHRINK_END
	view_cont.alignment = BoxContainer.ALIGNMENT_BEGIN
	grid_btn.button_pressed = true
	grid_btn.update_button()
	IS.expand(transform_label, true, true)
	
	body.add_child(bottom_cont)
	bottom_cont.add_child(view_cont)
	view_cont.add_child(center_btn)
	view_cont.add_child(grid_btn)
	view_cont.add_child(transform_label)
	
	control_cont.hide()
	render_progress_bar.show_percentage = false
	render_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	IS.expand(render_progress_bar)
	
	bottom_cont.add_child(control_cont)
	control_cont.add_child(render_progress_label)
	control_cont.add_child(render_progress_bar)
	
	header_panel.hide()
	
	PlaybackServer.position_changed.connect(_on_position_changed)
	Renderer.render_started.connect(_on_renderer_render_started)
	Renderer.frame_sended.connect(_on_renderer_frame_sended)
	Renderer.render_stopped.connect(_on_renderer_render_stopped)
	
	resized.connect(_on_resized)
	visibility_changed.connect(_on_visibility_changed)
	center_btn.pressed.connect(_on_center_btn_pressed)
	grid_btn.pressed.connect(_on_grid_btn_pressed)
	
	update()

func _gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		
		button_event = event
		
		match button_event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				effect_zoom(-1)
			MOUSE_BUTTON_WHEEL_UP:
				effect_zoom(1)
	
	elif event is InputEventMouseMotion:
		update_transform_label()
		if button_event:
			if button_event.button_index == MOUSE_BUTTON_LEFT and button_event.is_pressed():
				camera.position -= event.relative / camera.zoom
				update()

func effect_zoom(dir: int) -> void:
	
	var zoom: Vector2 = camera.zoom
	var zoom_factor: Vector2 = Vector2(zoom_speed, zoom_speed) * camera.zoom * dir
	camera.zoom = clamp(zoom + zoom_factor, Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))
	
	var event_centered_pos: Vector2 = button_event.position - size / 2.
	var offset: Vector2 = event_centered_pos / zoom - event_centered_pos / camera.zoom
	camera.position += offset
	
	update()

func update() -> void:
	
	viewport_cont.queue_redraw()
	update_transform_label()
	
	if Renderer.is_working:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	
	if is_visible_in_tree():
		Scene2.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	elif Scene2.viewport.render_target_update_mode != SubViewport.UPDATE_WHEN_VISIBLE:
		Scene2.viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE

func update_transform_label() -> void:
	transform_label.text = "Position: %s, Zoom %s, Mouse Position %s" % [camera.position.snappedf(.1), snappedf(camera.zoom.x * 100., .1), Vector2i(render_sprite.get_local_mouse_position())]

func update_render_info(frame: int) -> void:
	var max: int = ProjectServer2.project_res.root_clip_res.length
	var ratio: float = frame / float(max)
	var percent: float = ratio * 100.
	render_progress_label.text = "Frames sended: %s, of %s, %s%s" % [frame, max, snappedf(percent, .01), "%"]
	render_progress_bar.value = percent

func _on_position_changed(position: int) -> void:
	update()

func _on_renderer_render_started() -> void:
	control_cont.show()

func _on_renderer_frame_sended(frame: int) -> void:
	update_render_info(frame)

func _on_renderer_render_stopped() -> void:
	update_render_info(0)
	control_cont.hide()

func _on_resized() -> void:
	update()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		await get_tree().process_frame
		update()

func _on_center_btn_pressed() -> void:
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(.5, .5)
	update()

func _on_grid_btn_pressed() -> void:
	viewport_cont.apply_grid = grid_btn.button_pressed
	update()


class RenderViewerViewportContainer extends SubViewportContainer:
	
	var render_viewer: RenderViewer
	
	var apply_grid: bool = true
	
	func _init(_render_viewer: RenderViewer) -> void:
		render_viewer = _render_viewer
		clip_contents = true
	
	# Made by Claude AI.
	func _draw() -> void:
		if not apply_grid:
			return
		
		var camera: Camera2D = render_viewer.camera
		var sprite: Sprite2D = render_viewer.render_sprite
		var vp_size: Vector2 = size  # حجم الـ SubViewportContainer
		
		# --- حوّل إحداثيات العالم إلى إحداثيات الـ control ---
		# مركز الشاشة = camera.position في العالم
		var world_to_screen := func(world_pos: Vector2) -> Vector2:
			return (world_pos - camera.position) * camera.zoom + vp_size / 2.0
		
		# --- إعدادات الشبكة ---
		var grid_step: float = 50.0  # المسافة بين خطوط الشبكة بالـ world units
		var minor_color:= Color(1, 1, 1, 0.15)
		var axis_color:= Color(0.22, 0.55, 0.85, 0.7)   # أزرق للمحاور
		var edge_color:= Color(0.91, 0.35, 0.24, 0.85)  # أحمر لحواف الصورة
		
		# --- حساب نطاق العالم المرئي ---
		var half: Vector2 = vp_size / 2.0 / camera.zoom
		var world_min: Vector2 = camera.position - half
		var world_max: Vector2 = camera.position + half
		
		# --- ارسم minor grid ---
		var start_x:= floorf(world_min.x / grid_step) * grid_step
		var start_y:= floorf(world_min.y / grid_step) * grid_step
		
		var x:= start_x
		while x <= world_max.x:
			var sx: float = world_to_screen.call(Vector2(x, 0)).x
			draw_line(Vector2(sx, 0), Vector2(sx, vp_size.y), minor_color, 1.0)
			x += grid_step
		
		var y:= start_y
		while y <= world_max.y:
			var sy: float = world_to_screen.call(Vector2(0, y)).y
			draw_line(Vector2(0, sy), Vector2(vp_size.x, sy), minor_color, 1.0)
			y += grid_step
		
		# --- ارسم محور X (y=0) ومحور Y (x=0) ---
		var origin_screen: Vector2 = world_to_screen.call(Vector2.ZERO)
		
		# محور X
		draw_line(Vector2(0, origin_screen.y), Vector2(vp_size.x, origin_screen.y), axis_color, 1.5, true)
		# محور Y
		draw_line(Vector2(origin_screen.x, 0), Vector2(origin_screen.x, vp_size.y), axis_color, 1.5, true)
		# نقطة الأصل
		draw_circle(origin_screen, 4.0, axis_color)
		
		# --- ارسم حواف الصورة (render_sprite) ---
		if sprite.texture:
			var tex_size: Vector2 = sprite.texture.get_size()
			var half_tex: Vector2 = tex_size / 2.0
			
			# أركان الصورة بإحداثيات العالم
			var img_tl: Vector2 = world_to_screen.call(-half_tex)
			var img_br: Vector2 = world_to_screen.call( half_tex)
			
			# المستطيل الرئيسي
			var img_rect:= Rect2(img_tl, img_br - img_tl)
			draw_rect(img_rect, edge_color, false, 1.5, true)
			
			# خطوط ممتدة من الحواف إلى أطراف الشاشة
			var edge_ext_color:= Color(edge_color.r, edge_color.g, edge_color.b, 0.3)
			
			# الحافة العلوية والسفلية ممتدة
			draw_line(Vector2(0, img_tl.y),    Vector2(vp_size.x, img_tl.y),    edge_ext_color, 0.8, true)
			draw_line(Vector2(0, img_br.y),    Vector2(vp_size.x, img_br.y),    edge_ext_color, 0.8, true)
			# الحافة اليسرى واليمنى ممتدة
			draw_line(Vector2(img_tl.x, 0),    Vector2(img_tl.x, vp_size.y),    edge_ext_color, 0.8, true)
			draw_line(Vector2(img_br.x, 0),    Vector2(img_br.x, vp_size.y),    edge_ext_color, 0.8, true)
			
			# علامات صغيرة على الأركان
			var corner_size:= 6.0
			for corner in [img_tl, Vector2(img_br.x, img_tl.y), Vector2(img_tl.x, img_br.y), img_br]:
				draw_rect(Rect2(corner - Vector2.ONE * corner_size / 2.0, Vector2.ONE * corner_size), edge_color, true)


