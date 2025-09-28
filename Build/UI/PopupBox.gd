class_name PopupedBox extends PopupedControl

var box: BoxContainer
var elements: Array

func _ready() -> void:
	super()
	var margin_container = IS.create_margin_container()
	var scroll_container = IS.create_scroll_container()
	var margin2_container = IS.create_margin_container(0, 12, 0, 0)
	box = IS.create_box_container(12, true)
	
	for index: int in elements.size():
		var element = elements[index]
		if element is Array:
			for control in element:
				if control == null:
					continue
				box.add_child(control.get_parent())
		else: box.add_child(element)
	
	margin2_container.add_child(box)
	scroll_container.add_child(margin2_container)
	margin_container.add_child(scroll_container)
	add_child(margin_container)
	
	IS.expand(margin2_container, true, true)








