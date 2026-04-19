class_name Vector2Controller extends BoxContainer

signal val_changed(new_val: Vector2)

var curr_val: Vector2:
	set(val):
		curr_val = val
		if x_edit and y_edit:
			x_edit.set_curr_val_manually(val.x)
			y_edit.set_curr_val_manually(val.y)

@onready var x_edit: FloatController = IS.create_float_controller(curr_val.x, -INF, INF, .001, .01)
@onready var y_edit: FloatController = IS.create_float_controller(curr_val.y, -INF, INF, .001, .01)

func _ready() -> void:
	IS.describe_box_container(self, 6, true)
	var x_split: SplitContainer = IS.create_split_container(2, false, {custom_minimum_size = Vector2(0, 32.0), dragging_enabled = false})
	var y_split: SplitContainer = IS.create_split_container(2, false, {custom_minimum_size = Vector2(0, 32.0), dragging_enabled = false})
	var x_label: Label = IS.create_label("X", IS.label_settings_bold, {modulate = Color.RED})
	var y_label: Label = IS.create_label("Y", IS.label_settings_bold, {modulate = Color.GREEN})
	
	y_split.add_child(y_label)
	IS.add_children(x_split, [x_label, x_edit])
	IS.add_children(y_split, [y_label, y_edit])
	IS.add_children(self, [
		x_split, IS.create_color_rect(Color(Color.RED, .5), {custom_minimum_size = Vector2(.0,2.0)}),
		y_split, IS.create_color_rect(Color(Color.GREEN, .5), {custom_minimum_size = Vector2(.0,2.0)})
	])
	
	x_edit.val_changed.connect(on_edit_val_changed)
	y_edit.val_changed.connect(on_edit_val_changed)

func on_edit_val_changed(new_val: float) -> void:
	set_curr_val(Vector2(x_edit.curr_val, y_edit.curr_val))

func set_curr_val(new_val: Vector2) -> void:
	curr_val = new_val
	val_changed.emit(curr_val)

func set_curr_val_manually(new_val: Vector2) -> void:
	curr_val = new_val
