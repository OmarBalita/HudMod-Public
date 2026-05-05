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

@onready var pingpong_renderers_root: Node = Node.new()

var pingpong_renderers: Dictionary[Display2DClipRes, PingPongRenderer]


func _ready() -> void:
	pingpong_renderers_root.name = &"PingPongRendererRoot"
	add_child(pingpong_renderers_root)

func get_pingpong_renderers() -> Dictionary[Display2DClipRes, PingPongRenderer]:
	return pingpong_renderers

func pingpong_renderer_init(clip_res: Display2DClipRes) -> PingPongRenderer:
	var ppr:= PingPongRenderer.new()
	pingpong_renderers_root.add_child(ppr)
	pingpong_renderers[clip_res] = ppr
	var high_quality: bool = EditorServer.use_high_quality()
	pingpong_renderer_update(clip_res, high_quality)
	return ppr

func pingpong_renderer_free(clip_res: Display2DClipRes) -> void:
	pingpong_renderers[clip_res].queue_free()
	pingpong_renderers.erase(clip_res)

func pingpong_renderer_update(clip_res: Display2DClipRes, use_debanding: bool) -> void:
	var ppr: PingPongRenderer = pingpong_renderers[clip_res]
	ppr.viewport_a.use_debanding = use_debanding
	ppr.viewport_b.use_debanding = use_debanding
	ppr.viewport_c.use_debanding = use_debanding
	ppr.viewport_a.use_hdr_2d = false
	ppr.viewport_b.use_hdr_2d = false
	ppr.viewport_c.use_hdr_2d = false

func update_pprs() -> void:
	var high_quality: bool = EditorServer.use_high_quality()
	for clip_res: Display2DClipRes in pingpong_renderers:
		pingpong_renderer_update(clip_res, high_quality)

func until_pprs_to_finish() -> void:
	for clip_res: Display2DClipRes in pingpong_renderers:
		var ppr: PingPongRenderer = pingpong_renderers[clip_res]
		if ppr.is_in_process:
			await ppr.process_finished

