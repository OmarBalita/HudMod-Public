class_name AudioHelper extends Object

static func create_data_from_path(path: String) -> Array[PackedByteArray]:
	return AudioDecoder.create_data_from_path(path)

