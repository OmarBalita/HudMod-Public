class_name PopupedBox extends PopupedControl

var box: BoxContainer
var elements: Array[Control]

func _ready() -> void:
	super()
	var margin_container = InterfaceServer.create_margin_container()
	var scroll_container = InterfaceServer.create_scroll_container()
	var scroll_margin_container = InterfaceServer.create_margin_container(0, 12, 0, 0)
	box = InterfaceServer.create_box_container(12, true)
	for element in elements:
		box.add_child(element)
	scroll_margin_container.add_child(box)
	scroll_container.add_child(scroll_margin_container)
	margin_container.add_child(scroll_container)
	add_child(margin_container)
	
	InterfaceServer.expand(scroll_margin_container)
