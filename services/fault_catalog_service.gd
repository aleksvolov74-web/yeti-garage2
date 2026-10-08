class_name FaultCatalogService
extends RefCounted

const DATA_PATH := "res://data/warning_lights.json"
const DTC_PATH := "res://data/dtc_catalog.json"
const MANUAL_PATH := "res://data/manual_index.json"
const DiagnosticService = preload("res://services/diagnostic_service.gd")
const TechnicalCatalog = preload("res://services/technical_catalog_service.gd")
const PartCatalog = preload("res://services/part_catalog_service.gd")

static var _warnings: Array = []
static var _dtcs: Array = []

static func warnings() -> Array:
	_load()
	return _warnings.duplicate(true)

static func warning(id: String) -> Dictionary:
	_load()
	for row_value in _warnings:
		var row: Dictionary = row_value
		if str(row.get("id", "")) == id:
			return row.duplicate(true)
	return {}

static func dtcs() -> Array:
	_load()
	return _dtcs.duplicate(true)

static func normalize_code(value: String) -> String:
	return value.to_upper().replace(" ", "").replace("\t", "").replace("\n", "").replace("\r", "")

static func valid_code(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[PUCB][0-9A-F]{4}$")
	return regex.search(normalize_code(value)) != null

static func dtc(code: String) -> Dictionary:
	_load()
	var normalized := normalize_code(code)
	for row_value in _dtcs:
		var row: Dictionary = row_value
		if str(row.get("code", "")) == normalized:
			return row.duplicate(true)
	return {}

static func search(query: String) -> Array:
	_load()
	var q := query.strip_edges().to_lower().replace("ё", "е")
	var normalized_code := normalize_code(query)
	var result: Array = []
	if q == "":
		return result
	for row_value in _warnings:
		var row: Dictionary = row_value
		var haystack := str(row.get("title", "")).to_lower() + " " + str(row.get("id", "")).to_lower() + " " + " ".join(row.get("keywords", [])).to_lower()
		if q in haystack:
			result.append({"kind":"warning", "id":str(row.get("id", "")), "name":str(row.get("title", "")), "subtitle":"Лампа"})
	for row_value in _dtcs:
		var row: Dictionary = row_value
		if normalized_code in str(row.get("code", "")) or q in str(row.get("title_ru", "")).to_lower():
			result.append({"kind":"dtc", "id":str(row.get("code", "")), "name":str(row.get("code", "")) + " · " + str(row.get("title_ru", "")), "subtitle":"Код ошибки"})
	return result

static func validate() -> Array[String]:
	_load()
	var errors: Array[String] = []
	var vehicle := {"year":2011, "factory_engine_code":"CBZB", "current_engine_code":"CBZB", "drivetrain":"FWD", "transmission_family":"0AM / DQ200"}
	var manual_pages := _manual_pages()
	var seen_warnings: Dictionary = {}
	for row_value in _warnings:
		var row: Dictionary = row_value
		var id := str(row.get("id", ""))
		if id == "" or seen_warnings.has(id): errors.append("warning id missing/duplicate: " + id)
		seen_warnings[id] = true
		if str(row.get("title", "")) == "": errors.append("warning title missing: " + id)
		if str(row.get("severity", "")) not in ["STOP", "URGENT_CHECK", "CHECK_SOON", "INFORMATION"]: errors.append("warning severity invalid: " + id)
		var image := str(row.get("image", ""))
		if not image.begins_with("res://") or not FileAccess.file_exists(image): errors.append("warning image missing: " + id)
		var warning_source: Dictionary = row.get("source", {})
		if warning_source.is_empty() or int(warning_source.get("manual_page", 0)) not in manual_pages: errors.append("warning source missing: " + id)
		var applicability: Dictionary = row.get("applicability", {})
		if applicability.get("make", "") != "Škoda" or applicability.get("model", "") != "Yeti 5L": errors.append("warning applicability invalid: " + id)
		for node_id in row.get("related_node_ids", []):
			if TechnicalCatalog.find_node(str(node_id), vehicle).is_empty(): errors.append("warning node missing: " + id + " -> " + str(node_id))
		for part_id in row.get("related_part_ids", []):
			if PartCatalog.get_part(str(part_id)).is_empty(): errors.append("warning part missing: " + id + " -> " + str(part_id))
		var flow := str(row.get("related_diagnostic_flow", ""))
		if flow != "" and DiagnosticService.flow(flow).is_empty(): errors.append("warning flow missing: " + id + " -> " + flow)
	var seen_codes: Dictionary = {}
	for row_value in _dtcs:
		var row: Dictionary = row_value
		var code := str(row.get("code", ""))
		if not valid_code(code) or seen_codes.has(code): errors.append("DTC code invalid/duplicate: " + code)
		seen_codes[code] = true
		if str(row.get("title_ru", "")) == "": errors.append("DTC title missing: " + code)
		var dtc_source: Dictionary = row.get("source", {})
		if dtc_source.is_empty() or not str(dtc_source.get("url", "")).begins_with("https://"): errors.append("DTC source missing: " + code)
		if str(row.get("verification_status", "")) not in ["GENERIC_OBD", "VAG_SPECIFIC", "REFERENCE_ONLY"]: errors.append("DTC verification status invalid: " + code)
		for node_id in row.get("related_node_ids", []):
			if TechnicalCatalog.find_node(str(node_id), vehicle).is_empty(): errors.append("DTC node missing: " + code + " -> " + str(node_id))
		for part_id in row.get("related_part_ids", []):
			if PartCatalog.get_part(str(part_id)).is_empty(): errors.append("DTC part missing: " + code + " -> " + str(part_id))
		var flow := str(row.get("related_diagnostic_flow", ""))
		if flow != "" and DiagnosticService.flow(flow).is_empty(): errors.append("DTC flow missing: " + code + " -> " + flow)
		var warning_id := str(row.get("dashboard_warning_id", ""))
		if warning_id != "" and warning(warning_id).is_empty(): errors.append("DTC warning missing: " + code + " -> " + warning_id)
	return errors

static func _load() -> void:
	if not _warnings.is_empty() and not _dtcs.is_empty(): return
	_warnings = _read_rows(DATA_PATH, "warnings")
	_dtcs = _read_rows(DTC_PATH, "dtcs")

static func _read_rows(path: String, key: String) -> Array:
	if not FileAccess.file_exists(path): return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.get(key, []) is Array: return []
	return parsed[key]

static func _manual_pages() -> Array:
	var pages: Array = []
	if not FileAccess.file_exists(MANUAL_PATH): return pages
	var file := FileAccess.open(MANUAL_PATH, FileAccess.READ)
	if file == null: return pages
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array: return pages
	for entry_value in parsed:
		var entry: Dictionary = entry_value
		var page := int(entry.get("manual_page", 0))
		if page > 0 and page not in pages: pages.append(page)
	return pages
