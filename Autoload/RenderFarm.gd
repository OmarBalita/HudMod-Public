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

