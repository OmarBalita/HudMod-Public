class_name AudioStreamHelper extends Object

static func create_stream() -> AudioStreamWAV:
	var stream:= AudioStreamWAV.new()
	stream.mix_rate = 44100
	stream.stereo = true
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	return stream

static func create_stream_from_path(path: String) -> AudioStreamWAV:
	var stream:= create_stream()
	stream.data = Audio.get_audio_data(path)
	return stream

