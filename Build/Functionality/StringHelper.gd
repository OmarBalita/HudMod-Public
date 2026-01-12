class_name StringHelper extends Node

static func extract_placeholders(text: String, regex_pattern: String = "\\{([a-zA-Z_][a-zA-Z0-9_]*)\\}") -> PackedStringArray:
	var regex:= RegEx.new()
	regex.compile(regex_pattern)
	
	var results:= PackedStringArray()
	for regex_match: RegExMatch in regex.search_all(text):
		results.append(regex_match.get_string(1))
	return results

