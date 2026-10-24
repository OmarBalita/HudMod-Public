#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Founded by Omar Mohammed Balita.                                       ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
## ----------------------------------------------------------------------- ##
##  GPLv3                                                                  ##
#############################################################################
class_name CompSoundChorus extends SoundComponentRes

const MAX_DELAY_MS: float = 50.0
const STEREO_PHASE_OFFSET: float = 0.25

@export var delay_ms: float = 20.0
@export var depth_ms: float = 5.0
@export var rate_hz: float = 0.8
@export var mix: float = 0.5

var _ring: PackedVector2Array
var _pos: int
var _phase: float

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"delay_ms": export(float_args(delay_ms, 5.0, 35.0, .1)),
		&"depth_ms": export(float_args(depth_ms, 0.0, 10.0, .01)),
		&"rate_hz": export(float_args(rate_hz, 0.05, 5.0, .01)),
		&"mix": export(float_args(mix, 0.0, 1.0, .001)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var ring_size: int = int(MAX_DELAY_MS * 0.001 * sample_rate) + 2
	if _ring.size() != ring_size:
		_ring = PackedVector2Array()
		_ring.resize(ring_size)
		_pos = 0

	var base_samples: float = delay_ms * 0.001 * sample_rate
	var depth_samples: float = depth_ms * 0.001 * sample_rate
	var phase_step: float = rate_hz / sample_rate

	var output: PackedVector2Array = buffer.duplicate()
	for i in buffer.size():
		var dry: Vector2 = buffer[i]
		_ring[_pos] = dry

		# Left and right LFOs are a quarter cycle apart to widen the image.
		var delay_l: float = base_samples + depth_samples * sin(_phase * TAU)
		var delay_r: float = base_samples + depth_samples * sin((_phase + STEREO_PHASE_OFFSET) * TAU)
		var wet := Vector2(_read_ring(delay_l, ring_size).x, _read_ring(delay_r, ring_size).y)

		output[i] = dry * (1.0 - mix) + wet * mix
		_pos = (_pos + 1) % ring_size
		_phase = fmod(_phase + phase_step, 1.0)

	return output

func _read_ring(delay_samples: float, ring_size: int) -> Vector2:
	var read_pos: float = fposmod(_pos - delay_samples, ring_size)
	var idx: int = int(read_pos)
	return _ring[idx].lerp(_ring[(idx + 1) % ring_size], read_pos - idx)

func _reset_audio() -> void:
	_ring = PackedVector2Array()
	_pos = 0
	_phase = 0.0
