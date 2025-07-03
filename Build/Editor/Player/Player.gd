class_name Player extends EditorRect


# ---------------------------------------------------
# Editor Global Variables

@export_group("Theme")
@export_subgroup("Texture")
var texture_play = preload("res://Asset/Icons/play-button-arrowhead.png")
var texture_ratio = preload("res://Asset/Icons/aspect-ratio.png")
var texture_full_screen = preload("res://Asset/Icons/expand.png")
var texture_more = preload("res://Asset/Icons/more.png")


# RealTime Variables

var curr_frame: int:
	set(val):
		curr_frame = val
		time_code_label.text = TimeServer.frame_to_timecode(curr_frame)

# RealTime Nodes

var display_root: Node2D
var display_camera: Camera2D

var viewport: SubViewport

var play_button: TextureButton
var time_code_label: Label
var max_time_label: Label
var ratio_button: TextureButton
var full_screen_button: TextureButton
var more_button: TextureButton


# ---------------------------------------------------
# Background Called Functions

func _start() -> void:
	super()
	
	# Describe Player
	var split_container = InterfaceServer.create_split_container(1, true)
	var view_container = InterfaceServer.create_viewport_container({size_flags_vertical = Control.SIZE_EXPAND_FILL})
	var options_container = InterfaceServer.create_box_container(10, false,
	{"custom_minimum_size": Vector2(.0, 50.0), "alignment": BoxContainer.ALIGNMENT_CENTER})
	var time_panel = InterfaceServer.create_panel_container(Vector2(300, 0))
	var time_container = InterfaceServer.create_box_container()
	
	viewport = SubViewport.new()
	view_container.add_child(viewport)
	
	play_button = InterfaceServer.create_texture_button(texture_play)
	time_code_label = InterfaceServer.create_label(TimeServer.frame_to_timecode(curr_frame), InterfaceServer.LABEL_SETTINGS_BOLD)
	max_time_label = InterfaceServer.create_label("00:01:00:00")
	ratio_button = InterfaceServer.create_texture_button(texture_ratio)
	full_screen_button = InterfaceServer.create_texture_button(texture_full_screen)
	more_button = InterfaceServer.create_texture_button(texture_more)
	
	time_container.add_child(time_code_label)
	time_container.add_child(InterfaceServer.create_h_line_panel(15, Color(1,1,1, .5)))
	time_container.add_child(max_time_label)
	time_panel.add_child(time_container)
	
	options_container.add_child(InterfaceServer.create_empty_control())
	options_container.add_child(play_button)
	options_container.add_child(InterfaceServer.create_v_line_panel())
	options_container.add_child(time_panel)
	options_container.add_child(InterfaceServer.create_empty_control(10, 10, {size_flags_horizontal = Control.SIZE_EXPAND_FILL}))
	options_container.add_child(full_screen_button)
	options_container.add_child(InterfaceServer.create_v_line_panel())
	options_container.add_child(ratio_button)
	options_container.add_child(more_button)
	options_container.add_child(InterfaceServer.create_empty_control())
	
	
	split_container.add_child(view_container)
	split_container.add_child(options_container)
	body.add_child(split_container)
	
	# Display Root and Camera by default
	await get_tree().process_frame
	setup_display()





func setup_display() -> void:
	display_root = Node2D.new()
	display_camera = Camera2D.new()
	display_root.add_child(display_camera)
	viewport.add_child(display_root)










