extends Node

func describe(what: Object, description: Dictionary) -> void:
	for d: String in description:
		what.set(d, description.get(d))
