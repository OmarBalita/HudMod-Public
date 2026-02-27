extends Node

@onready var pingpong_renderers_root: Node = Node.new()

var pingpong_renderers: Dictionary[MediaClipRes, PingPongRenderer]

func _ready() -> void:
	pingpong_renderers_root.name = &"PingPongRendererRoot"
	add_child(pingpong_renderers_root)

func get_pingpong_renderers() -> Dictionary[MediaClipRes, PingPongRenderer]:
	return pingpong_renderers

func pingpong_renderer_init(media_res: MediaClipRes) -> PingPongRenderer:
	var ppr:= PingPongRenderer.new()
	pingpong_renderers_root.add_child(ppr)
	pingpong_renderers[media_res] = ppr
	return ppr

func pingpong_renderer_free(media_res: MediaClipRes) -> void:
	pingpong_renderers[media_res].queue_free()
	pingpong_renderers.erase(media_res)

