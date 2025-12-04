class_name ClipNodesExplorer extends EditorRect

var nodes_tree: Tree
var root: TreeItem

var curr_nodes: Dictionary


func _ready_editor() -> void:
	nodes_tree = Tree.new()
	IS.set_base_container_settings(nodes_tree)
	body.add_child(nodes_tree)
	create_root()


func create_root() -> void:
	root = nodes_tree.create_item()
	root.set_text(0, "Root")


func create_layer_node(layer: int, clip_res: MediaClipRes) -> TreeItem:
	var node = nodes_tree.create_item(root)
	node.set_text(0, str(layer, " : ", "clip"))
	return node
