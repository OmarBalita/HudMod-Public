class_name CustomTextEdit extends TextEdit

func get_selection_from_index() -> int:
	return line_col_to_index(
		get_selection_from_line(),
		get_selection_from_column()
	)

func get_selection_to_index() -> int:
	return line_col_to_index(
		get_selection_to_line(),
		get_selection_to_column()
	)

func line_col_to_index(line: int, col: int) -> int:
	var index: int
	for line_index: int in line:
		index += get_line(line_index).length() + 1
	return index + col
