class_name ResLoadHelper extends Resource

static func load_or_save(path: String, res_id: Resource) -> Resource:
	if not FileAccess.file_exists(path):
		var resource: Resource = res_id.new()
		ResourceSaver.save(resource, path, ResourceSaver.FLAG_COMPRESS)
		return resource
	else:
		return ResourceLoader.load(path)
