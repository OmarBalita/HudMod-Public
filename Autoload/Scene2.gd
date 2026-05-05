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
extends Node

var update_video_viewers_frame: bool = false

var editor_settings: AppEditorSettings = EditorServer.editor_settings

var viewport: SubViewport = SubViewport.new()
var root: Node
var camera: Camera2D

var curr_nodes: Array[MediaClipRes]
var stream_players: Array[MediaClipRes]
var video_players: Array[VideoClipRes]
var cameras: Array[Camera2DClipRes]


func _ready_scene() -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.audio_listener_enable_2d = true
	viewport.transparent_bg = false
	ProjectServer2.project_opened.connect(_on_project_server_project_opened)
	PlaybackServer.played.connect(play_stream_players)
	PlaybackServer.stopped.connect(stop_stream_players)

func start_scene() -> void:
	root = Node.new()
	
	var root_clip_res: RootClipRes = ProjectServer2.project_res.root_clip_res
	root_clip_res.curr_node = root
	curr_nodes.append(root_clip_res)
	
	camera = Camera2D.new()
	root.add_child(camera)
	viewport.add_child(root)
	
	update_viewport()


func update_viewport() -> void:
	viewport.size = ProjectServer2.project_res.resolution
	viewport.use_debanding = Renderer.is_working
	viewport.use_hdr_2d = false

func get_curr_nodes() -> Array[MediaClipRes]:
	return curr_nodes

func set_curr_nodes(new_val: Array[MediaClipRes]) -> void:
	curr_nodes = new_val

func curr_nodes_has(clip_res: MediaClipRes) -> bool:
	return curr_nodes.has(clip_res)

func curr_nodes_get(clip_res: MediaClipRes) -> Node:
	return clip_res.curr_node

func add_stream_player(audio_clip_res: MediaClipRes) -> void:
	if PlaybackServer.is_playing():
		play_stream_player(audio_clip_res, PlaybackServer.position, float(ProjectServer2.fps))
	stream_players.append(audio_clip_res)
func remove_stream_player(audio_clip_res: MediaClipRes) -> void: stream_players.erase(audio_clip_res)

func add_video_player(video_clip_res: VideoClipRes) -> void:
	if PlaybackServer.is_playing():
		play_video_stream_player(video_clip_res, PlaybackServer.position, float(ProjectServer2.fps))
	video_players.append(video_clip_res)
func remove_video_player(video_clip_res: VideoClipRes) -> void: video_players.erase(video_clip_res)

func add_camera(camera_clip_res: Camera2DClipRes) -> void:
	cameras.append(camera_clip_res)
	update_camera_enabling()
func remove_camera(camera_clip_res: Camera2DClipRes) -> void:
	cameras.erase(camera_clip_res)
	update_camera_enabling()

func update_camera_enabling() -> void:
	camera.enabled = cameras.size() == 0

func spawn_node(parent_res: MediaClipRes, clip_res: MediaClipRes, node: Node, layer_idx: int) -> void:
	var node_parent: Node = parent_res.curr_node
	
	node_parent.add_child(node)
	node_parent.move_child(node, layer_idx)
	
	clip_res.curr_node = node
	curr_nodes.append(clip_res)

func free_node(clip_res: MediaClipRes) -> void:
	clip_res.curr_node.queue_free()
	clip_res.curr_node = null
	curr_nodes.erase(clip_res)


func clear_nodes() -> void:
	for clip_res: MediaClipRes in curr_nodes:
		if clip_res.curr_node:
			clip_res.curr_node.queue_free()
	curr_nodes.clear()
	stream_players.clear()
	video_players.clear()
	cameras.clear()


func loop_nodes(method: Callable) -> void:
	
	for clip_res: MediaClipRes in curr_nodes:
		await method.call(clip_res)

func play_stream_players(at: int) -> void:
	
	var fps_f: float = float(ProjectServer2.fps)
	
	for stream_clip_res: MediaClipRes in stream_players:
		play_stream_player(stream_clip_res, at, fps_f)
	
	for video_clip_res: VideoClipRes in video_players:
		play_video_stream_player(video_clip_res, at, fps_f)

func stop_stream_players(at: int) -> void:
	
	for stream_clip_res: MediaClipRes in stream_players:
		stream_clip_res.curr_node.stop()
	
	for video_clip_res: VideoClipRes in video_players:
		video_clip_res.stream_player.stop()

func play_stream_player(clip_res: MediaClipRes, at: int, fps_f: float) -> void:
	var target_frame: int = PlaybackServer.position - clip_res.clip_pos + clip_res.from
	clip_res.curr_node.play(target_frame / fps_f)

func play_video_stream_player(video_clip_res: VideoClipRes, at: int, fps_f: float) -> void:
	var target_frame: int = PlaybackServer.position - video_clip_res.clip_pos + video_clip_res.from
	video_clip_res.stream_player.play(target_frame / fps_f)



func _on_project_server_project_opened(project_res: ProjectRes) -> void:
	start_scene()




