class_name LibraryIndex
extends RefCounted

static func normalized(value: String) -> String:
	return value.to_lower().replace("ä", "a").replace("ö", "o").replace("ü", "u").replace("ß", "ss").replace("é", "e").replace("&", " ").replace("-", " ").replace("_", " ")

static func matches(query: String, title: String, collection: String, tags: Array) -> bool:
	var haystack := normalized(title + " " + collection + " " + " ".join(tags))
	for word in normalized(query).split(" ", false):
		if not haystack.contains(word): return false
	return true

static func tags(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for tag in value:
			if tag is String and not tag.strip_edges().is_empty() and not result.has(tag.strip_edges()): result.append(tag.strip_edges().left(40))
	return result
