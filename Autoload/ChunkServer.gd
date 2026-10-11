#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
##	This program is free software: you can redistribute it and/or modify   ##
##	it under the terms of the GNU General Public License as published by   ##
##	the Free Software Foundation, either version 3 of the License, or	   ##
##	(at your option) any later version.									   ##
##																		   ##
##	This program is distributed in the hope that it will be useful,		   ##
##	but WITHOUT ANY WARRANTY; without even the implied warranty of		   ##
##	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the		   ##
##	GNU General Public License for more details.						   ##
##																		   ##
##	You should have received a copy of the GNU General Public License	   ##
##	along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
extends Node

signal chunk_ready(key: ChunkKey)
signal chunk_failed(key: ChunkKey)
signal source_ready(source_id: StringName)
signal source_failed(source_id: StringName)

enum Kind {
	NONE = -1,
	WAVEFORM,
}

@export var max_in_flight: int = get_default_max_in_flight()

var waveform: WaveformProducer
var store: ChunkStore = ChunkStore.new()

var producers: Dictionary[Kind, ChunkProducer] = {}
var sources: Dictionary[StringName, ChunkSource] = {}
var epochs: Dictionary[StringName, int] = {}
var demands: Dictionary[StringName, Array] = {}
var queue: Array[ChunkRequest] = []
var in_flight: Dictionary[StringName, bool] = {}
var failed: Dictionary[StringName, bool] = {}


func _init() -> void:
	waveform = WaveformProducer.new(self)
	register_producer(waveform)


static func get_default_max_in_flight() -> int:
	var threads: int = int(ProjectSettings.get_setting("threading/worker_pool/max_threads", -1))
	if threads < 1:
		threads = OS.get_processor_count()
	var ratio: float = float(ProjectSettings.get_setting("threading/worker_pool/low_priority_thread_ratio", 0.3))
	return maxi(1, int(threads * ratio))


func register_producer(producer: ChunkProducer) -> void:
	var kind: Kind = producer.get_kind()
	if kind == Kind.NONE:
		push_error("ChunkServer: producer has no kind.")
		return
	producers[kind] = producer

func register_source(id: StringName, payload: Variant = null) -> ChunkSource:
	var source: ChunkSource = _begin_source(id)
	source.payload = payload
	source.is_ready = true
	_rebuild_queue()
	_pump()
	return source

func register_source_async(id: StringName, prepare: Callable) -> ChunkSource:
	var source: ChunkSource = _begin_source(id)
	WorkerThreadPool.add_task(_run_prepare.bind(id, source.epoch, prepare), false, "ChunkServer prepare")
	return source

func unregister_source(id: StringName) -> void:
	if not sources.has(id):
		return
	sources.erase(id)
	store.remove_source(id)
	_erase_failed_of_source(id)
	_rebuild_queue()

func get_source(id: StringName) -> ChunkSource:
	return sources.get(id, null)

func clear_all() -> void:
	for id: StringName in sources.keys():
		unregister_source(id)
	demands.clear()
	queue.clear()
	failed.clear()
	store.clear()

func set_demand(demander: StringName, requests: Array[ChunkRequest]) -> void:
	if requests.is_empty():
		demands.erase(demander)
	else:
		demands[demander] = requests
	_rebuild_queue()
	_pump()

func clear_demand(demander: StringName) -> void:
	if demands.erase(demander):
		_rebuild_queue()

func retry_failed() -> void:
	failed.clear()
	_rebuild_queue()
	_pump()

func get_cached(key: ChunkKey) -> Variant:
	return store.get_value(key.id)

func is_cached(key: ChunkKey) -> bool:
	return store.has_value(key.id)

func is_failed(key: ChunkKey) -> bool:
	return failed.has(key.id)

func get_stats() -> Dictionary:
	return {
		&"queued": queue.size(),
		&"in_flight": in_flight.size(),
		&"cached": store.get_count(),
		&"cached_bytes": store.get_used(),
		&"failed": failed.size(),
	}


func _begin_source(id: StringName) -> ChunkSource:
	if sources.has(id):
		unregister_source(id)
	var epoch: int = int(epochs.get(id, -1)) + 1
	epochs[id] = epoch
	var source: ChunkSource = ChunkSource.new(id, epoch)
	sources[id] = source
	return source

func _erase_failed_of_source(id: StringName) -> void:
	var prefix: String = ChunkKey.source_prefix(id)
	for key_id: StringName in failed.keys():
		if String(key_id).begins_with(prefix):
			failed.erase(key_id)

func _rebuild_queue() -> void:
	var best: Dictionary[StringName, ChunkRequest] = {}
	
	for demander: StringName in demands:
		for request: ChunkRequest in demands[demander]:
			var key: ChunkKey = request.key
			if failed.has(key.id) or in_flight.has(key.id) or store.has_value(key.id):
				continue
			if not producers.has(key.kind):
				continue
			var source: ChunkSource = sources.get(key.source_id, null)
			if source == null or source.has_failed:
				continue
			if best.has(key.id) and best[key.id].priority <= request.priority:
				continue
			best[key.id] = request
	
	var new_queue: Array[ChunkRequest] = []
	new_queue.assign(best.values())
	new_queue.sort_custom(_is_more_urgent)
	queue = new_queue

func _pump() -> void:
	var i: int = 0
	while in_flight.size() < max_in_flight and i < queue.size():
		var request: ChunkRequest = queue[i]
		var source: ChunkSource = sources.get(request.key.source_id, null)
		
		if source == null or source.has_failed:
			queue.remove_at(i)
			continue
		if not source.is_ready:
			i += 1
			continue
		
		queue.remove_at(i)
		in_flight[request.key.id] = true
		WorkerThreadPool.add_task(
			_run_chunk.bind(request.key, source, producers[request.key.kind], source.epoch),
			false, "ChunkServer chunk"
		)

func _run_chunk(key: ChunkKey, source: ChunkSource, producer: ChunkProducer, epoch: int) -> void:
	var raw: Variant = producer.produce(key, source)
	_on_chunk_done.call_deferred(key, raw, epoch, WorkerThreadPool.get_caller_task_id())

func _run_prepare(id: StringName, epoch: int, prepare: Callable) -> void:
	var payload: Variant = prepare.call()
	_on_prepare_done.call_deferred(id, epoch, payload, WorkerThreadPool.get_caller_task_id())

func _on_chunk_done(key: ChunkKey, raw: Variant, epoch: int, task_id: int) -> void:
	if task_id >= 0:
		WorkerThreadPool.wait_for_task_completion(task_id)
	in_flight.erase(key.id)
	
	var source: ChunkSource = sources.get(key.source_id, null)
	if source == null or source.epoch != epoch or not producers.has(key.kind):
		_rebuild_queue()
		_pump()
		return
	
	var producer: ChunkProducer = producers[key.kind]
	var value: Variant = producer.finalize(raw, key) if raw != null else null
	
	if value == null:
		failed[key.id] = true
		chunk_failed.emit(key)
	else:
		store.put_value(key.id, value, producer.size_of(value))
		chunk_ready.emit(key)
	_pump()

func _on_prepare_done(id: StringName, epoch: int, payload: Variant, task_id: int) -> void:
	if task_id >= 0:
		WorkerThreadPool.wait_for_task_completion(task_id)
	
	var source: ChunkSource = sources.get(id, null)
	if source == null or source.epoch != epoch:
		return
	
	if payload == null:
		source.has_failed = true
		_rebuild_queue()
		source_failed.emit(id)
		return
	
	source.payload = payload
	source.is_ready = true
	source_ready.emit(id)
	_pump()

static func _is_more_urgent(a: ChunkRequest, b: ChunkRequest) -> bool:
	if a.priority != b.priority:
		return a.priority < b.priority
	if a.key.source_id != b.key.source_id:
		return String(a.key.source_id) < String(b.key.source_id)
	return a.key.index < b.key.index


class ChunkKey extends RefCounted:
	
	var source_id: StringName
	var kind: Kind
	var variant: int
	var index: int
	var id: StringName
	
	func _init(_source_id: StringName, _kind: Kind, _variant: int, _index: int) -> void:
		source_id = _source_id
		kind = _kind
		variant = _variant
		index = _index
		id = StringName("%s|%d|%d|%d" % [source_id, kind, variant, index])
	
	static func source_prefix(_source_id: StringName) -> String:
		return "%s|" % _source_id


class ChunkRequest extends RefCounted:
	
	const TIER_VISIBLE: int = 0
	const TIER_NEAR: int = 1_000_000
	const TIER_BACKGROUND: int = 2_000_000
	
	var key: ChunkKey
	var priority: int
	
	func _init(_key: ChunkKey, _priority: int = TIER_VISIBLE) -> void:
		key = _key
		priority = _priority


class ChunkSource extends RefCounted:
	
	var id: StringName
	var epoch: int
	var payload: Variant
	var is_ready: bool
	var has_failed: bool
	
	func _init(_id: StringName, _epoch: int) -> void:
		id = _id
		epoch = _epoch


class ChunkStore extends RefCounted:
	
	@export var budget: int
	
	var used: int = 0
	var values: Dictionary = {}
	var sizes: Dictionary[StringName, int] = {}
	
	func _init(_budget: int = 64 * 1024 * 1024) -> void:
		budget = _budget
	
	func has_value(key_id: StringName) -> bool:
		return values.has(key_id)
	
	func get_value(key_id: StringName) -> Variant:
		if not values.has(key_id):
			return null
		# Re-insert to mark it as the most recently used.
		var value: Variant = values[key_id]
		values.erase(key_id)
		values[key_id] = value
		return value
	
	func put_value(key_id: StringName, value: Variant, size: int) -> void:
		remove_value(key_id)
		values[key_id] = value
		sizes[key_id] = size
		used += size
		while used > budget and values.size() > 1:
			remove_value(values.keys()[0])
	
	func remove_value(key_id: StringName) -> void:
		if not values.has(key_id):
			return
		used -= sizes[key_id]
		values.erase(key_id)
		sizes.erase(key_id)
	
	func remove_source(source_id: StringName) -> void:
		var prefix: String = ChunkKey.source_prefix(source_id)
		for key_id: StringName in values.keys():
			if String(key_id).begins_with(prefix):
				remove_value(key_id)
	
	func clear() -> void:
		values.clear()
		sizes.clear()
		used = 0
	
	func get_used() -> int:
		return used
	
	func get_count() -> int:
		return values.size()


class ChunkProducer extends RefCounted:
	
	func get_kind() -> Kind:
		return Kind.NONE
	
	func produce(key: ChunkKey, source: ChunkSource) -> Variant:
		return null
	
	func finalize(raw: Variant, key: ChunkKey) -> Variant:
		return raw
	
	func size_of(value: Variant) -> int:
		return 1


class WaveformProducer extends ChunkProducer:
	
	const CHUNK_WIDTH: int = 512
	const IMAGE_HEIGHT: int = 64
	const PEAKS_PER_SECOND: int = 240
	const PREFETCH_CHUNKS: int = 2
	
	const THUMBNAIL_PEAKS: int = 256
	const THUMBNAIL_FRAMES_PER_PEAK: int = 64
	
	var server: Object
	var source_ids: Dictionary[StringName, StringName] = {}
	
	
	func _init(_server: Object) -> void:
		server = _server
	
	
	func get_kind() -> Kind:
		return Kind.WAVEFORM
	
	func register_media(path: StringName, id: String, pcm: PackedByteArray) -> void:
		var source_id: StringName = StringName(id) if not id.is_empty() else StringName(String(path).md5_text())
		source_ids[path] = source_id
		server.register_source_async(source_id, func() -> Variant:
			return MediaHelper.build_peak_map(pcm, PEAKS_PER_SECOND, 0)
		)
	
	func unregister_media(path: StringName) -> void:
		if not source_ids.has(path):
			return
		server.unregister_source(source_ids[path])
		source_ids.erase(path)
	
	func rename_media(from: StringName, to: StringName) -> void:
		if source_ids.has(from):
			source_ids[to] = source_ids[from]
			source_ids.erase(from)
	
	func get_source_id(path: StringName) -> StringName:
		return source_ids.get(path, &"")
	
	static func make_key(source_id: StringName, pixels_per_second: int, chunk_index: int) -> ChunkKey:
		return ChunkKey.new(source_id, Kind.WAVEFORM, pixels_per_second, chunk_index)
	
	func get_total_pixels(source_id: StringName, pixels_per_second: int) -> int:
		var source: ChunkSource = server.get_source(source_id)
		if source == null or not source.is_ready:
			return 0
		return _total_pixels(source.payload, pixels_per_second)
	
	static func get_chunk_count(total_pixels: int) -> int:
		return (total_pixels + CHUNK_WIDTH - 1) / CHUNK_WIDTH
	
	static func get_chunk_width(total_pixels: int, chunk_index: int) -> int:
		return clampi(total_pixels - chunk_index * CHUNK_WIDTH, 0, CHUNK_WIDTH)
	
	static func plan(first: int, last: int, visible: Vector2i, playhead: int) -> Dictionary[int, int]:
		var priorities: Dictionary[int, int] = {}
		var anchor: int = playhead if playhead >= 0 else visible.x
		
		for index: int in range(visible.x, visible.y + 1):
			if index >= first and index <= last:
				priorities[index] = ChunkRequest.TIER_VISIBLE + absi(index - anchor)
		
		if visible.y >= visible.x:
			for distance: int in range(1, PREFETCH_CHUNKS + 1):
				_add_near(priorities, first, last, visible.x - distance, distance)
				_add_near(priorities, first, last, visible.y + distance, distance)
		
		if playhead >= 0:
			for distance: int in range(0, PREFETCH_CHUNKS + 1):
				_add_near(priorities, first, last, playhead + distance, distance)
		
		return priorities
	
	func render_thumbnail(pcm: PackedByteArray, length: float, size: int) -> Image:
		var peaks_per_second: int = maxi(1, ceili(THUMBNAIL_PEAKS / maxf(length, 0.001)))
		var map: Dictionary = MediaHelper.build_peak_map(pcm, peaks_per_second, THUMBNAIL_FRAMES_PER_PEAK)
		var peaks: PackedFloat32Array = map.peaks
		return MediaHelper.render_waveform(
			peaks, 0, peaks.size(), size,
			Image.FORMAT_RGBA8, size, size, 2, 2,
			map.peak, MediaHelper.STYLE_THUMBNAIL, Color.TRANSPARENT
		)
	
	func produce(key: ChunkKey, source: ChunkSource) -> Variant:
		var payload: Dictionary = source.payload
		var pixels_per_second: int = key.variant
		var pixel_from: int = key.index * CHUNK_WIDTH
		var width: int = mini(CHUNK_WIDTH, _total_pixels(payload, pixels_per_second) - pixel_from)
		if width < 1:
			return null
		
		return MediaHelper.render_waveform(
			payload.peaks, pixel_from, payload.peaks_per_second, pixels_per_second,
			Image.FORMAT_L8, width, IMAGE_HEIGHT, 0, 1,
			payload.peak, MediaHelper.STYLE_TIMELINE, Color.TRANSPARENT
		)
	
	func finalize(raw: Variant, key: ChunkKey) -> Variant:
		var image: Image = raw as Image
		if image == null or image.is_empty():
			return null
		return ImageTexture.create_from_image(image)
	
	func size_of(value: Variant) -> int:
		var texture: Texture2D = value as Texture2D
		if texture == null:
			return 1
		# ~4/3 for the mipmap chain.
		return int(texture.get_width() * texture.get_height() * 1.34)
	
	
	static func _total_pixels(payload: Dictionary, pixels_per_second: int) -> int:
		var peak_count: int = (payload.peaks as PackedFloat32Array).size()
		var peaks_per_second: int = payload.peaks_per_second
		return (peak_count * pixels_per_second + peaks_per_second - 1) / peaks_per_second
	
	static func _add_near(priorities: Dictionary[int, int], first: int, last: int, index: int, distance: int) -> void:
		if index < first or index > last or priorities.has(index):
			return
		priorities[index] = ChunkRequest.TIER_NEAR + distance
