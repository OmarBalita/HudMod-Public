class_name MenuOption extends Resource


@export var is_separation_line: bool
@export var text: String
@export var icon: Texture2D
@export var forward: Array[MenuOption]
@export var checkable: bool
@export var checked: bool:
	set(val):
		if not checkable:
			return
		checked = val
		#if checked:
			#if check_group:
				#var last_option = check_group.last_checked_option
				#if last_option:
					#check_group.last_checked_option.checked = false
				#check_group.last_checked_option = self

var check_group: CheckGroup


func _init(_text: String = "", _icon: Texture2D = null, _is_separation_line: bool = false, _forward: Array[MenuOption] = []) -> void:
	is_separation_line = _is_separation_line
	text = _text
	icon = _icon
	forward = _forward

static func new_line() -> MenuOption:
	return MenuOption.new("", null, true)

static func new_checked(_text: String = "", _check_group: CheckGroup = null, _icon: Texture2D = null, _forward: Array[MenuOption] = []) -> MenuOption:
	var menu_option = MenuOption.new(_text, _icon, false, _forward)
	menu_option.checkable = true
	menu_option.check_group = _check_group
	return menu_option

static func new_options_with_check_group(options_info: Array[Dictionary], check_group_path: String, check_index: int = 0) -> Array:
	var options: Array
	
	var group: CheckGroup
	if FileAccess.file_exists(check_group_path):
		group = ResourceLoader.load(check_group_path)
	if group == null:
		group = CheckGroup.new()
		group.checked_index = check_index
		group.save_path = check_group_path
		ResourceSaver.save(group, check_group_path)
	
	for index in options_info.size():
		var info = options_info[index]
		var option:= MenuOption.new()
		
		if info.has("text"):
			option.text = info.text
		if info.has("icon"):
			option.icon = info.icon
		if info.has("forward"):
			option.forward = info.forward
		
		option.checkable = true
		option.check_group = group
		if check_index == index:
			option.checked = true
		options.append(option)
	
	return options













