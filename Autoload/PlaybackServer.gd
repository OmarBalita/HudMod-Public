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

signal position_changed(position: int)
signal played(at: int)
signal stopped(at: int)

signal render_process_finished()

@export var playing: bool

@export var position: int:
	set(val):
		position = val
		process_root(ProjectServer2.project_res.root_clip_res)
		position_changed.emit(val)

var start_time: float
var is_render_process_finished: bool = true

func is_playing() -> bool:
	return playing

func play(emit_played: bool = true) -> void:
	var opened_clip_res: MediaClipRes = ProjectServer2.opened_clip_res_path.back()
	
	var start: int = opened_clip_res.clip_pos
	position = clamp(position, start, start + opened_clip_res.length)
	
	var curr_time: float = Time.get_ticks_msec() / 1000.
	start_time = curr_time - position * ProjectServer2.delta
	
	playing = true
	if emit_played:
		played.emit(position)
	
	step()

func stop() -> void:
	if playing:
		stopped.emit(position)
		playing = false

func step() -> void:
	
	var opened_clip_res: MediaClipRes = ProjectServer2.opened_clip_res_path.back()
	
	var frames_dropped: int = EditorServer.editor_settings.performance.frames_dropped
	var step: int = 1 if Renderer.is_working else frames_dropped + 1
	
	var target_time: float = start_time + position * ProjectServer2.delta
	var curr_time: float = Time.get_ticks_msec() / 1000.
	var delay: float = (target_time - curr_time) * step
	
	if opened_clip_res.length <= 0:
		stop()
		return
	
	if delay > .0:
		await get_tree().create_timer(delay).timeout
	
	elif delay < -.05:
		await get_tree().process_frame
		if not is_playing():
			return
		play(false)
		return
	position += step
		
	var start: int = opened_clip_res.clip_pos
	var end: int = start + opened_clip_res.length
	
	if position >= end:
		if EditorServer.editor_settings.edit.replay:
			position = start
			play()
		else:
			stop()
		return
	
	if is_playing():
		step()

func seek(at: int) -> void:
	position = at

func seek_here() -> void:
	position = position

func get_position() -> int:
	return position

func set_position(new_val: int) -> void:
	position = new_val


func process_root(root_clip_res: RootClipRes) -> void:
	var layers: Array[LayerRes] = root_clip_res.layers
	for layer_idx: int in layers.size():
		var layer: LayerRes = layers[layer_idx]
		process_layer(layer_idx, layer_idx, root_clip_res, layer)
	
	is_render_process_finished = false
	await RenderFarm.until_pprs_to_finish()
	render_process_finished.emit()
	is_render_process_finished = true


func process(parent_clip_res: MediaClipRes, root_layer_idx: int) -> void:
	var layers: Array[LayerRes] = parent_clip_res.layers
	for layer_idx: int in layers.size():
		var layer: LayerRes = layers[layer_idx]
		process_layer(root_layer_idx, layer_idx, parent_clip_res, layer)


func process_layer(root_layer_idx: int, layer_idx: int, parent_clip_res: MediaClipRes, layer: LayerRes) -> void:
	
	var displayed_clip_res: MediaClipRes = layer.displayed_clip_res
	
	var clips: Dictionary[int, MediaClipRes] = layer.clips
	
	for frame: int in clips:
		
		var clip_res: MediaClipRes = clips[frame]
		
		if is_frame_at_clip_res(frame, clip_res):
			
			if clip_res != displayed_clip_res:
				
				if displayed_clip_res:
					free_clip(displayed_clip_res)
				
				spawn_clip(parent_clip_res, clip_res, root_layer_idx, layer_idx, layer, frame)
				layer.displayed_frame = frame
				layer.displayed_clip_res = clip_res
			
			clip_res.process(position - frame)
			process(clip_res, root_layer_idx)
			
			return
	
	if displayed_clip_res:
		free_clip(displayed_clip_res)
		layer.displayed_clip_res = null

func is_frame_at_clip_res(frame: int, clip_res: MediaClipRes) -> bool:
	return position >= frame and position < frame + clip_res.length

func spawn_clip(parent_clip_res: MediaClipRes, clip_res: MediaClipRes, root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> void:
	var node: Node = clip_res.init_node(root_layer_idx, layer_idx, layer_res, frame)
	Scene2.spawn_node(parent_clip_res, clip_res, node, layer_idx)
	clip_res.enter(node)

func free_clip(clip_res: MediaClipRes) -> void:
	
	var layers: Array[LayerRes] = clip_res.layers
	
	for layer: LayerRes in layers:
		if layer.displayed_clip_res:
			free_clip(layer.displayed_clip_res)
			layer.displayed_clip_res = null
	
	if clip_res.curr_node:
		clip_res.exit(clip_res.curr_node)
		Scene2.free_node(clip_res)

func root_layer_get_bus_unique_name(root_layer_idx: int) -> StringName:
	return ProjectServer2.project_res.root_clip_res.get_layer(root_layer_idx).get_bus_unique_name()


