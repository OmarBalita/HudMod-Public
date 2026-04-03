extends Node

signal position_changed(position: int)
signal played(at: int)
signal stopped(at: int)

@export var playing: bool

@export var position: int:
	set(val):
		position = val
		process_root(ProjectServer2.project_res.root_clip_res)
		position_changed.emit(val)

var start_time: float

func is_playing() -> bool:
	return playing

func play() -> void:
	var opened_clip_res: MediaClipRes = ProjectServer2.opened_clip_res_path.back()
	var start: int = opened_clip_res.clip_pos
	position = clamp(position, start, start + opened_clip_res.length)
	
	var curr_time: float = Time.get_ticks_msec() / 1000.
	start_time = curr_time - position * ProjectServer2.delta
	
	playing = true
	step()
	
	played.emit(position)

func stop() -> void:
	if playing:
		stopped.emit(position)
		playing = false

func step() -> void:
	
	var target_time: float = start_time + position * ProjectServer2.delta
	var curr_time: float = Time.get_ticks_msec() / 1000.
	var delay: float = target_time - curr_time
	
	if delay > .0:
		await get_tree().create_timer(delay).timeout
	
	var opened_clip_res: MediaClipRes = ProjectServer2.opened_clip_res_path.back()
	var start: int = opened_clip_res.clip_pos
	var end: int = start + opened_clip_res.length
	
	if position >= end:
		if EditorServer.editor_settings.is_replay:
			position = start
			play()
		else:
			stop()
		return
	
	position += 1
	
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


func process(parent_clip_res: MediaClipRes, root_layer_idx: int) -> void:
	var layers: Array[LayerRes] = parent_clip_res.layers
	for layer_idx: int in layers.size():
		var layer: LayerRes = layers[layer_idx]
		process_layer(layer_idx, layer_idx, parent_clip_res, layer)


func process_layer(root_layer_idx: int, layer_idx: int, parent_clip_res: MediaClipRes, layer: LayerRes) -> void:
	
	var displayed_clip_res: MediaClipRes = layer.displayed_clip_res
	
	var clips: Dictionary[int, MediaClipRes] = layer.clips
	
	for frame: int in clips:
		
		var clip_res: MediaClipRes = clips[frame]
		
		if is_frame_at_clip_res(frame, clip_res):
			
			if clip_res != displayed_clip_res:
				
				if displayed_clip_res:
					free_clip(displayed_clip_res)
				
				spawn_clip(parent_clip_res, clip_res, root_layer_idx, layer_idx, frame)
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

func spawn_clip(parent_clip_res: MediaClipRes, clip_res: MediaClipRes, root_layer_idx: int, layer_idx: int, frame: int) -> void:
	var node: Node = clip_res.init_node(root_layer_idx, layer_idx, frame)
	Scene2.spawn_node(parent_clip_res, clip_res, node)
	clip_res.enter(node)

func free_clip(clip_res: MediaClipRes) -> void:
	var layers: Array[LayerRes] = clip_res.layers
	for layer: LayerRes in layers:
		if layer.displayed_clip_res:
			free_clip(layer.displayed_clip_res)
			layer.displayed_clip_res = null
	clip_res.exit(clip_res.curr_node)
	Scene2.free_node(clip_res)


