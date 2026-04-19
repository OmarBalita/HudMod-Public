extends Node

@onready var pingpong_renderers_root: Node = Node.new()

var pingpong_renderers: Dictionary[MediaClipRes, PingPongRenderer]


func _ready() -> void:
	pingpong_renderers_root.name = &"PingPongRendererRoot"
	add_child(pingpong_renderers_root)

func get_pingpong_renderers() -> Dictionary[MediaClipRes, PingPongRenderer]:
	return pingpong_renderers

func pingpong_renderer_init(clip_res: MediaClipRes) -> PingPongRenderer:
	var ppr:= PingPongRenderer.new()
	pingpong_renderers_root.add_child(ppr)
	pingpong_renderers[clip_res] = ppr
	var high_quality: bool = EditorServer.use_high_quality()
	pingpong_renderer_update(clip_res, high_quality, high_quality)
	return ppr

func pingpong_renderer_free(clip_res: MediaClipRes) -> void:
	pingpong_renderers[clip_res].queue_free()
	pingpong_renderers.erase(clip_res)

func pingpong_renderer_update(clip_res: MediaClipRes, use_debanding: bool, use_hdr2: bool) -> void:
	var ppr: PingPongRenderer = pingpong_renderers[clip_res]
	ppr.viewport_a.use_debanding = use_debanding
	ppr.viewport_b.use_debanding = use_debanding
	ppr.viewport_c.use_debanding = use_debanding
	ppr.viewport_a.use_hdr_2d = use_hdr2
	ppr.viewport_b.use_hdr_2d = use_hdr2
	ppr.viewport_c.use_hdr_2d = use_hdr2

func update_pprs() -> void:
	var high_quality: bool = EditorServer.use_high_quality()
	for clip_res: MediaClipRes in pingpong_renderers:
		pingpong_renderer_update(clip_res, high_quality, high_quality)

func until_pprs_to_finish() -> void:
	for clip_res: MediaClipRes in pingpong_renderers:
		var ppr: PingPongRenderer = pingpong_renderers[clip_res]
		if ppr.is_in_process:
			await ppr.process_finished

