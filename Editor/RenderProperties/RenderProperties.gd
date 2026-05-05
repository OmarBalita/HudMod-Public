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
# Old code that has been discontinued
class_name RenderProperties extends EditorControl

@onready var header_box_cont: BoxContainer = IS.create_box_container(8)
@onready var video_render_btn: Button = IS.create_button("Render Video", preload("res://Asset/Icons/play.png"))
@onready var pause_btn: Button = IS.create_button("Pause", preload("res://Asset/Icons/pause.png"))
@onready var cancel_btn: Button = IS.create_button("Cancel", preload("res://Asset/Icons/cancel.png"))

@onready var scroll_cont: ScrollContainer = IS.create_scroll_container()
@onready var body_box_cont: BoxContainer = IS.create_box_container(8, true)

@export var video_render_profile: VideoRenderProfile = VideoRenderProfile.new()

var render_profile_edit: EditContainer


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
	video_render_profile.renderer_creation_failed.connect(_on_video_render_profile_renderer_creation_failed)
	
	Renderer.render_started.connect(_on_renderer_render_started)
	Renderer.render_paused.connect(_on_renderer_render_paused)
	Renderer.render_resumed.connect(_on_renderer_render_resumed)
	Renderer.render_finished_successfully.connect(_on_renderer_render_finished_successfully)
	Renderer.render_canceled_or_failed.connect(_on_renderer_render_canceled_or_failed)
	Renderer.render_stopped.connect(_on_renderer_render_stopped)
	
	_on_renderer_render_stopped()

func update_render_profile_edit() -> void:
	if render_profile_edit:
		render_profile_edit.queue_free()
	render_profile_edit = UsableRes.create_custom_edit(&"render_profile", video_render_profile)
	body_box_cont.add_child(render_profile_edit)

func _on_video_render_btn_pressed() -> void:
	video_render_profile.create_renderer_from_profile()

func _on_video_render_profile_renderer_created_successfully(output_path: String, video_renderer: VideoRenderer, audio_renderer: Resource) -> void:
	Renderer.start(output_path, video_renderer, audio_renderer)

func _on_video_render_profile_renderer_creation_failed(error: String) -> void:
	EditorServer.push_message(error)

func _on_pause_btn_pressed() -> void:
	Renderer.pause_resume()

func _on_cancel_btn_pressed() -> void:
	Renderer.cancel()

func _on_renderer_render_started() -> void:
	pause_btn.text = "Pause"
	pause_btn.icon = preload("res://Asset/Icons/pause.png")
	video_render_btn.hide()
	pause_btn.show()
	cancel_btn.show()
	EditorServer.push_message("The rendering process has begun.", EditorServer.MessageMode.MESSAGE_MODE_IDLE)


func _on_renderer_render_paused() -> void:
	pause_btn.text = "Resume"
	pause_btn.icon = preload("res://Asset/Icons/play.png")
	EditorServer.push_message("The rendering was paused.", EditorServer.MessageMode.MESSAGE_MODE_IDLE)

func _on_renderer_render_resumed() -> void:
	pause_btn.text = "Pause"
	pause_btn.icon = preload("res://Asset/Icons/pause.png")
	EditorServer.push_message("The rendering was resumed.", EditorServer.MessageMode.MESSAGE_MODE_IDLE)

func _on_renderer_render_finished_successfully() -> void:
	EditorServer.push_message("Rendering and exporting were completed successfully.", EditorServer.MessageMode.MESSAGE_MODE_IDLE)

func _on_renderer_render_canceled_or_failed(error: String) -> void:
	EditorServer.push_message(error)

func _on_renderer_render_stopped() -> void:
	video_render_btn.show()
	pause_btn.hide()
	cancel_btn.hide()




