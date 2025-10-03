extends Node

func describe(what: Object, description: Dictionary) -> void:
	for d: String in description:
		what.set(d, description.get(d))

func describe_node_deep(node: Node, description: Dictionary) -> void:
	describe(node, description)
	for child_node: Node in node.get_children():
		describe_node_deep(child_node, description)

func call_method_deep(node: Node, method_name: StringName, args: Array) -> void:
	node.call(method_name, args)
	for child_node: Node in node.get_children():
		call_method_deep(child_node, method_name, args)

func copy_properties(from: Object, to_objects: Array[Object], do_not_copy: Array[StringName]) -> void:
	for prop: Dictionary in from.get_property_list():
		var name = prop.name
		if name in do_not_copy:
			continue
		for to: Object in to_objects:
			to.set(name, from.get(name))
