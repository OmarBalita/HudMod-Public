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
