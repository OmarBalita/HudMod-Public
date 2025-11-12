class_name TimeMarker extends FocusControl

@export_group("Theme")
@export_subgroup("Texture", "texture")
@export var texture_marker: Texture2D = preload("res://Asset/Icons/location-marker.png")

var time_marker_pos: int
var time_marker_res: TimeMarkerRes

# RealTime Node
var popuped_text: PopupedText


func _init() -> void:
	draw_focus = false
	
	selectable = true
	draggable = true
	
	multiselect = false


func _ready() -> void:
	super()
	# Set Base Settings
	IS.set_base_settings(self)
	# Connections
	#selected.connect(on_selected)
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)
	selected_without_drag.connect(on_selected)
	drag_started.connect(on_drag_started)
	drag_finished.connect(on_drag_finished)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			ProjectServer.remove_time_marker(time_marker_pos)

func _draw() -> void:
	super()
	var color: Color = time_marker_res.custom_color
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_polygon(PackedVector2Array([
		Vector2(.0, size.y), Vector2(size.x, size.y), Vector2(.0, size.y + 12)
	]), PackedColorArray([color]))



func on_mouse_entered() -> void:
	
	is_focus = true
	await get_tree().create_timer(.5).timeout
	if is_focus and not popuped_text:
		var _text = "Custom Name: " + time_marker_res.custom_name + "\nCustom Description: " + time_marker_res.custom_description
		popuped_text = IS.create_popuped_text(_text)
		popuped_text.popdown_when_mouse_move = false
		get_tree().get_current_scene().add_child(popuped_text)
		popuped_text.popup(global_position + Vector2(0, size.y))

func on_mouse_exited() -> void:
	is_focus = false
	if is_instance_valid(popuped_text):
		popuped_text.popdown()
	popuped_text = null


func on_selected() -> void:
	var color_options: Array[MenuOption]
	
	var colors: Array[Color] = IS.RAINBOW_COLORS
	for color: Color in colors:
		var option: MenuOption = MenuOption.new("", texture_marker)
		option.set_meta("modulate", color)
		option.set_meta("icon_alignment", 1)
		color_options.append(option)
	
	var custom_color_index: int = colors.find(time_marker_res.custom_color)
	
	var name_line: LineEdit = IS.create_line_edit("Custom Name", time_marker_res.custom_name, null, {max_length = 24})
	var color_menu: Menu = IS.create_menu(color_options, false, {custom_minimum_size = Vector2(0, 40)})
	var description_controller: TextEdit = IS.create_text_edit_edit("Custom Description", time_marker_res.custom_description)[0]
	var description_edit: IS.EditBoxContainer = description_controller.get_parent()
	
	color_menu.focus_index = custom_color_index
	description_edit.keyframable = false
	
	var marker_window: BoxContainer = WindowManager.popup_accept_window(
		get_tree().get_current_scene(),
		Vector2(550, 400),
		"Create Time Marker",
		func() -> void:
			time_marker_res.custom_name = name_line.get_text()
			time_marker_res.custom_color = colors[color_menu.get_focus_index()]
			time_marker_res.custom_description = description_controller.get_text()
			queue_redraw()
	)
	
	IS.add_childs(marker_window, [
		name_line, color_menu, description_edit
	])
	
	IS.expand(description_edit, true, true)
	
	name_line.select()
	name_line.grab_focus()



func on_drag_started() -> void:
	EditorServer.time_line.timeline_state = TimeLine.TimelineStates.EXPAND_MEDIA_CLIP

func on_drag_finished() -> void:
	var timeline: TimeLine = EditorServer.time_line
	timeline.timeline_state = TimeLine.TimelineStates.IDLE
	var target_frame: int = timeline.get_frame_from_mouse_pos()
	ProjectServer.move_time_marker(time_marker_pos, target_frame)










