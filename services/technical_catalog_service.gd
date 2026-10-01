class_name TechnicalCatalogService
extends RefCounted

const PartCatalogService = preload("res://services/part_catalog_service.gd")
const DiagnosticService = preload("res://services/diagnostic_service.gd")
const CATALOG_PATH := "res://data/technical_catalog.json"

static var _catalog_cache: Dictionary = {}

static func catalog() -> Dictionary:
	if not _catalog_cache.is_empty():
		return _catalog_cache
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("Technical catalog is missing: %s" % CATALOG_PATH)
		return {}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.get("sections", []) is Array:
		push_error("Technical catalog JSON is invalid")
		return {}
	_catalog_cache = parsed
	return _catalog_cache

static func sections(vehicle: Dictionary = {}) -> Array:
	var result: Array = []
	for item_value in catalog().get("sections", []):
		var item: Dictionary = item_value.duplicate(true)
		if not is_compatible(item, vehicle):
			continue
		result.append(item)
	return result

static func nodes(parent: Dictionary, vehicle: Dictionary = {}) -> Array:
	var result: Array = []
	for node_value in parent.get("nodes", parent.get("children", [])):
		var node: Dictionary = node_value
		if is_compatible(node, vehicle):
			result.append(node)
	return result

static func is_compatible(row: Dictionary, vehicle: Dictionary = {}) -> bool:
	var drivetrain := str(vehicle.get("drivetrain", "")).strip_edges().to_upper()
	var required_drivetrain := str(row.get("requires_drivetrain", "")).to_upper()
	if required_drivetrain != "":
		if required_drivetrain in ["AWD", "4WD", "4X4"] and drivetrain not in ["AWD", "4WD", "4X4"]:
			return false
		if required_drivetrain in ["FWD", "2WD"] and drivetrain not in ["FWD", "2WD"]:
			return false
	var engine_codes: Array = row.get("requires_engine_codes", [])
	if not engine_codes.is_empty():
		var engine_code := str(vehicle.get("current_engine_code", "")).strip_edges().to_upper()
		if engine_code == "":
			engine_code = str(vehicle.get("factory_engine_code", "")).strip_edges().to_upper()
		if engine_code == "" or engine_code not in engine_codes:
			return false
	var transmissions: Array = row.get("requires_transmissions", [])
	if not transmissions.is_empty():
		var transmission := str(vehicle.get("transmission_code", vehicle.get("transmission", ""))).strip_edges().to_upper()
		if transmission == "" or transmission not in transmissions:
			return false
	var transmission_families: Array = row.get("requires_transmission_families", [])
	if not transmission_families.is_empty():
		var family := str(vehicle.get("transmission_family", "")).strip_edges().to_upper()
		var family_matches := false
		for required_family_value in transmission_families:
			if family.contains(str(required_family_value).to_upper()):
				family_matches = true
		if not family_matches:
			return false
	var years: Array = row.get("requires_years", [])
	if not years.is_empty():
		var year := int(vehicle.get("year", 0))
		if year <= 0 or years.size() < 2 or year < int(years[0]) or year > int(years[1]):
			return false
	var minimum_year := int(row.get("requires_model_year_min", 0))
	if minimum_year > 0 and int(vehicle.get("year", 0)) < minimum_year:
		return false
	var equipment: Array = row.get("requires_equipment", [])
	if not equipment.is_empty():
		var saved: Array = vehicle.get("equipment", [])
		for item in equipment:
			if item not in saved:
				return false
	return true

static func section(section_id: String, vehicle: Dictionary = {}) -> Dictionary:
	for item_value in sections(vehicle):
		var item: Dictionary = item_value
		if str(item.get("id", "")) == section_id:
			return item
	return {}

static func find_part(part_id: String, vehicle: Dictionary = {}) -> Dictionary:
	for section_value in sections(vehicle):
		var section_row: Dictionary = section_value
		var location := _find_part_in_nodes(section_row.get("nodes", []), part_id, [], vehicle)
		if not location.is_empty():
			location["section"] = section_row
			return location
	# Preserve access to existing catalog items that have not yet been placed in a
	# vehicle diagram. The caller can still open their established part actions.
	var part := PartCatalogService.get_part(part_id)
	if not part.is_empty() and is_compatible(part, vehicle):
		return {"section":{"id":str(part.get("system", "")), "name":str(part.get("group", "Система"))}, "node":{"id":"unassigned", "name":str(part.get("group", "Узел")), "part_ids":[part_id]}, "path":[]}
	return {}

static func _find_part_in_nodes(node_rows: Array, part_id: String, path: Array, vehicle: Dictionary) -> Dictionary:
	for node_value in node_rows:
		var node: Dictionary = node_value
		if not is_compatible(node, vehicle):
			continue
		var next_path: Array = path.duplicate()
		next_path.append(node)
		if part_id in node.get("part_ids", []):
			return {"node":node, "path":next_path}
		var nested := _find_part_in_nodes(node.get("children", []), part_id, next_path, vehicle)
		if not nested.is_empty():
			return nested
	return {}

static func search(query: String, vehicle: Dictionary = {}) -> Array:
	var q := _normalize(query)
	if q.length() < 2:
		return []
	var results: Array = []
	var seen: Dictionary = {}
	for section_value in sections(vehicle):
		var section_row: Dictionary = section_value
		_add_search_result(results, seen, section_row, q, "system", section_row, [])
		_search_nodes(section_row.get("nodes", []), section_row, [], q, results, seen, vehicle)
	for part_value in PartCatalogService.search(query):
		var part: Dictionary = part_value
		var part_id := str(part.get("id", ""))
		if not is_compatible(part, vehicle):
			continue
		if not seen.has("part:" + part_id):
			var location := find_part(part_id, vehicle)
			results.append({"kind":"part", "id":part_id, "name":str(part.get("name", part_id)), "subtitle":str(part.get("group", "Деталь")), "section_id":str(location.get("section", {}).get("id", "")), "path":location.get("path", []), "part_id":part_id})
			seen["part:" + part_id] = true
	for part_value in PartCatalogService.all_parts():
		var part: Dictionary = part_value
		var part_id := str(part.get("id", ""))
		if not is_compatible(part, vehicle):
			continue
		if seen.has("part:" + part_id) or not _normalize(str(part.get("oem_numbers", []))).contains(q):
			continue
		var location := find_part(part_id, vehicle)
		results.append({"kind":"part", "id":part_id, "name":str(part.get("name", part_id)), "subtitle":"OEM · " + str(part.get("group", "Деталь")), "section_id":str(location.get("section", {}).get("id", "")), "path":location.get("path", []), "part_id":part_id})
		seen["part:" + part_id] = true
	for scenario_value in DiagnosticService.search(query):
		var scenario: Dictionary = scenario_value
		var flow_id := str(scenario.get("id", ""))
		if flow_id != "" and not seen.has("diagnostic:" + flow_id):
			results.append({"kind":"diagnostic", "id":flow_id, "name":str(scenario.get("title", "Проверка симптома")), "subtitle":"Возможное направление диагностики · не диагноз", "section_id":"", "path":[], "part_id":"", "flow_id":flow_id})
			seen["diagnostic:" + flow_id] = true
	return results

static func _search_nodes(node_rows: Array, section_row: Dictionary, path: Array, q: String, results: Array, seen: Dictionary, vehicle: Dictionary) -> void:
	for node_value in node_rows:
		var node: Dictionary = node_value
		if not is_compatible(node, vehicle):
			continue
		var next_path: Array = path.duplicate()
		next_path.append(node)
		_add_search_result(results, seen, node, q, "node", section_row, next_path)
		for part_id_value in node.get("part_ids", []):
			var part_id := str(part_id_value)
			if seen.has("part:" + part_id):
				continue
			var part := PartCatalogService.get_part(part_id)
			if part.is_empty():
				continue
			_add_search_result(results, seen, part, q, "part", section_row, next_path, part_id)
		_search_nodes(node.get("children", []), section_row, next_path, q, results, seen, vehicle)

static func _add_search_result(results: Array, seen: Dictionary, row: Dictionary, q: String, kind: String, section_row: Dictionary, path: Array, part_id: String = "") -> void:
	var id := part_id if part_id != "" else str(row.get("id", ""))
	var key := kind + ":" + id
	if id == "" or seen.has(key):
		return
	var name := _normalize(str(row.get("name", "")))
	var summary := _normalize(str(row.get("summary", row.get("keywords", []))) + " " + str(row.get("oem_numbers", [])))
	if not name.contains(q) and not summary.contains(q):
		return
	seen[key] = true
	results.append({"kind":kind, "id":id, "name":str(row.get("name", id)), "subtitle":str(section_row.get("name", "Узел")), "section_id":str(section_row.get("id", "")), "path":path, "part_id":part_id})

static func _normalize(value: String) -> String:
	var text := value.to_lower().replace("ё", "е").strip_edges()
	for token in [".", ",", ";", ":", "!", "?", "(", ")", "[", "]", "«", "»", "-", "—", "–", "/", "\\"]:
		text = text.replace(token, " ")
	while text.contains("  "):
		text = text.replace("  ", " ")
	return text.strip_edges()
