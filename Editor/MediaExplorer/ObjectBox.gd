class_name ObjectBox extends MediaBox

func _ready() -> void:
	super()
	add_category(&"Object", true, Color.LIGHT_GRAY)
	add_category(&"Object2D", true, Color("6699ff"))
	#add_category(&"Object3D", true, Color.BLACK)
	
	var categories_indices: Dictionary[StringName, int] = {
		&"Object": 0,
		&"Object2D": 1
	}
	
	var clips_ress: Dictionary[StringName, Dictionary] = ClassServer.get_media_clip_classes()
	
	for object_classname: StringName in clips_ress:
		var object_info: Dictionary = clips_ress[object_classname]
		var object_script: Script = object_info.script
		
		if object_script.is_abstract() or not object_script.is_media_clip_spawnable():
			continue
		
		var category_name: StringName = object_script.get_explorer_section()
		
		var category: Category = get_category(category_name)
		var object_card: ObjectCard = ObjectCard.new(self, categories_indices[category_name])
		
		if category == null:
			continue
		
		object_card.display_name = object_classname
		object_card.display_texture = object_info.icon
		object_card.clip_res_script = object_script
		
		object_card.custom_minimum_size = media_explorer.card_display_size
		
		category.add_content(object_card)
		object_card.thumbnail_texture_rect.modulate = Color(category.category_custom_color, .75)
	
	update_select_container()
	update_cards_selection()


class ObjectCard extends MediaBox.MediaCard:
	
	@export var clip_res_script: GDScript
	
	func get_media_ress() -> Array[MediaClipRes]:
		var clip_res: MediaClipRes = clip_res_script.new()
		clip_res.length = EditorServer.editor_settings.edit.default_clip_duration_frame
		return [clip_res]





