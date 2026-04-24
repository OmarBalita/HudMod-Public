class_name RenderProperties extends EditorControl

@onready var header_box_cont: BoxContainer = IS.create_box_container(8)
@onready var video_render_btn: Button = IS.create_button("Render Video", preload("res://Asset/Icons/play.png"))
@onready var pause_btn: Button = IS.create_button("Pause", preload("res://Asset/Icons/pause.png"))
@onready var cancel_btn: Button = IS.create_button("Cancel", preload("res://Asset/Icons/cancel.png"))

@onready var scroll_cont: ScrollContainer = IS.create_scroll_container()
@onready var body_box_cont: BoxContainer = IS.create_box_container(8, true)

@export var video_render_profile: VideoRenderProfile = VideoRenderProfile.new()

var render_profile_edit: EditBoxContainer


func _ready_editor() -> void:
	
	body_box_cont.alignment = BoxContainer.ALIGNMENT_BEGIN
	IS.expand(body_box_cont, true, true)
	
	header.add_child(header_box_cont)
	IS.add_children(header_box_cont, [
		video_render_btn,
		pause_btn,
		cancel_btn
	])
	
	body.add_child(scroll_cont)
	scroll_cont.add_child(body_box_cont)
	
	video_render_btn.pressed.connect(_on_video_render_btn_pressed)
	pause_btn.pressed.connect(_on_pause_btn_pressed)
	cancel_btn.pressed.connect(_on_cancel_btn_pressed)
	
	update_render_profile_edit()
	
	video_render_profile.renderer_created_successfully.connect(_on_video_render_profile_renderer_created_successfully)
	
	Renderer.render_started.connect(_on_renderer_render_started)
	Renderer.render_paused.connect(_on_renderer_render_paused)
	Renderer.render_resumed.connect(_on_renderer_render_resumed)
	Renderer.render_stopped.connect(_on_renderer_render_stopped)
	
	_on_renderer_render_stopped()

func update_render_profile_edit() -> void:
	if render_profile_edit:
		render_profile_edit.queue_free()
	render_profile_edit = UsableRes.create_custom_edit(&"Render Profile", video_render_profile)[0].get_meta(&"owner")
	body_box_cont.add_child(render_profile_edit)

func _on_video_render_btn_pressed() -> void:
	video_render_profile.create_renderer_from_profile()

func _on_video_render_profile_renderer_created_successfully(output_path: String, video_renderer: VideoRenderer, audio_renderer: Resource) -> void:
	Renderer.start(output_path, video_renderer, audio_renderer)

func _on_pause_btn_pressed() -> void:
	Renderer.pause_resume()

func _on_cancel_btn_pressed() -> void:
	Renderer.cancel()

func _on_renderer_render_started() -> void:
	_on_renderer_render_resumed()
	video_render_btn.hide()
	pause_btn.show()
	cancel_btn.show()

func _on_renderer_render_paused() -> void:
	pause_btn.text = "Resume"
	pause_btn.icon = preload("res://Asset/Icons/play.png")

func _on_renderer_render_resumed() -> void:
	pause_btn.text = "Pause"
	pause_btn.icon = preload("res://Asset/Icons/pause.png")

func _on_renderer_render_stopped() -> void:
	video_render_btn.show()
	pause_btn.hide()
	cancel_btn.hide()




