class_name LayoutInfo extends Resource

@export_group(&"LayoutInfo")
@export var layout_1: LayoutInfo
@export var layout_2: LayoutInfo
@export var editor_1_name: StringName
@export var editor_2_name: StringName
@export var vertical: bool
@export var split_offset: int:
	set(val):
		split_offset = val

var root: LayoutRootInfo

func open(editors: Dictionary[StringName, EditorControl]) -> Dictionary[StringName, Variant]:
	var split_container: SplitContainer = IS.create_split_container(0, vertical, {})
	IS.expand(split_container, true, true)
	
	if layout_1: split_container.add_child(layout_1.open(editors).layout)
	elif editor_1_name: editors[editor_1_name].reparent(split_container)
	if layout_2: split_container.add_child(layout_2.open(editors).layout)
	elif editor_2_name: editors[editor_2_name].reparent(split_container)
	
	split_container.split_offset = split_offset
	split_container.dragged.connect(_on_split_container_dragged)
	split_container.drag_ended.connect(_on_split_container_drag_ended)
	
	return {&"layout": split_container}

static func parse(split_container: SplitContainer, layout_id: Object = LayoutInfo) -> LayoutInfo:
	var layout_info: LayoutInfo = layout_id.new()
	var children: Array[Node] = split_container.get_children()
	
	var child_1: Control = children[0]
	if child_1 is SplitContainer: layout_info.layout_1 = LayoutInfo.parse(child_1)
	else: layout_info.editor_1_name = child_1.get_meta(&"editor_name")
	
	if children.size() > 1:
		var child_2: Control = children[1]
		if child_2 is SplitContainer: layout_info.layout_2 = LayoutInfo.parse(child_2)
		else: layout_info.editor_2_name = child_2.get_meta(&"editor_name")
	
	layout_info.vertical = split_container.vertical
	layout_info.split_offset = split_container.split_offset
	
	return layout_info

func set_root_deep(_root: LayoutRootInfo) -> void:
	root = _root
	if layout_1: layout_1.set_root_deep(_root)
	if layout_2: layout_2.set_root_deep(_root)

func _on_split_container_dragged(offset: int) -> void:
	split_offset = offset

func _on_split_container_drag_ended() -> void:
	if root: root.layout_changed.emit()



