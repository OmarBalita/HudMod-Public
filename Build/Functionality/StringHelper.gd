# Written by AI
class_name StringHelper extends Node

static func extract_placeholders(text: String, regex_pattern: String = "\\{([a-zA-Z_][a-zA-Z0-9_]*)\\}") -> PackedStringArray:
	var regex:= RegEx.new()
	regex.compile(regex_pattern)
	
	var results:= PackedStringArray()
	for regex_match: RegExMatch in regex.search_all(text):
		results.append(regex_match.get_string(1))
	return results

static func fuzzy_search(search_query: String, text: String) -> bool:
	var query_index: int = 0
	var text_index: int = 0
	
	while query_index < search_query.length() and text_index < text.length():
		if search_query[query_index] == text[text_index]:
			query_index += 1
		text_index += 1
	
	return query_index == search_query.length()


static func generate_new_id(used_ids: PackedStringArray, id_length: int = 12, append_new_id: bool = false) -> String:
	const ID_KEYS: String = "_abcdefghijklmnopqrstuvwxyz"
	var keys_max: int = ID_KEYS.length() - 1
	
	var result_id: String
	
	while not result_id or result_id in used_ids:
		result_id = ""
		for time in id_length:
			var rand_char: String = ID_KEYS[randi_range(0, keys_max)]
			if randi_range(0, 1):
				rand_char = rand_char.to_upper()
			result_id += rand_char
	
	if append_new_id:
		used_ids.append(result_id)
	
	return result_id
