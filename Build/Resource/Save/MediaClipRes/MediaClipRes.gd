class_name MediaClipRes extends Resource

@export var id: String

@export_file() var media_resource_path: String
# files types:
# Image: svg, png, jpeg, jif ...
# Video: mp4, avi, av1, mkv, gif ...
# Audio: mp3, wav, ogg ...
# Text: res => Resource:TextResource
# Shape: res => Resource:ShapeResource
# Effect: res => Resource:EffectResource
# Code: res => Resource:CodeResource

@export var from: int = 0
@export var length: int = 10 # as frames

@export var children: Dictionary[int, Dictionary]
#{
	#index_x: {time_x: MediaClipRes.new(), time_y: MediaClipRes.new()}
	#index_y: {}
	#index_z: {}
	#index_w: {}
	#...
#}


@export var properties: Dictionary[String, Dictionary]





















