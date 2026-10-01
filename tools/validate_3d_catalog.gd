extends SceneTree

const PartCatalogService = preload("res://services/part_catalog_service.gd")
const Vehicle3DView = preload("res://scenes/vehicle_3d/vehicle_3d_view.gd")

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var failures: Array[String] = []
	if PartCatalogService.SYSTEMS.size() != 16:
		failures.append("expected 16 systems, found %d" % PartCatalogService.SYSTEMS.size())
	if PartCatalogService.PARTS.size() != 141:
		failures.append("expected 141 parts, found %d" % PartCatalogService.PARTS.size())
	var covered_parts: Dictionary = {}
	var assembly_ids: Dictionary = {}
	for system_id in PartCatalogService.SYSTEMS.keys():
		var system: Dictionary = PartCatalogService.SYSTEMS[system_id]
		var assemblies := PartCatalogService.assemblies_for_system(str(system_id))
		if assemblies.is_empty():
			failures.append("system %s has no assemblies" % system_id)
		for part_id in system.get("parts", []):
			if not PartCatalogService.PARTS.has(part_id):
				failures.append("system %s refers to missing part %s" % [system_id, part_id])
		for assembly in assemblies:
			var assembly_id := str(assembly.get("id", ""))
			if assembly_ids.has(assembly_id):
				failures.append("duplicate assembly id %s" % assembly_id)
			assembly_ids[assembly_id] = true
			for part_id in assembly.get("parts", []):
				if not PartCatalogService.PARTS.has(part_id):
					failures.append("assembly %s refers to missing part %s" % [assembly_id, part_id])
				covered_parts[str(part_id)] = true
	for part_id in PartCatalogService.PARTS.keys():
		var part: Dictionary = PartCatalogService.PARTS[part_id]
		var system_id := str(part.get("system", ""))
		if not PartCatalogService.SYSTEMS.has(system_id):
			failures.append("part %s refers to missing system %s" % [part_id, system_id])
		elif part_id not in PartCatalogService.SYSTEMS[system_id].get("parts", []):
			failures.append("part %s is absent from system %s" % [part_id, system_id])
		if not covered_parts.has(str(part_id)):
			failures.append("part %s is not reachable through any assembly" % part_id)

	var engine_front: Dictionary = {}
	for assembly_value in PartCatalogService.assemblies_for_system("engine"):
		var assembly: Dictionary = assembly_value
		if str(assembly.get("id", "")) == "engine_front":
			engine_front = assembly
	var required_engine_parts := ["engine_block", "cylinder_head", "valve_cover", "turbocharger", "alternator", "accessory_belt_drive"]
	for part_id in required_engine_parts:
		if part_id not in engine_front.get("parts", []):
			failures.append("engine front assembly is missing %s" % part_id)

	var view := Vehicle3DView.new()
	root.add_child(view)
	view.size = Vector2(420.0, 780.0)
	await process_frame
	await process_frame
	if view.level != "systems":
		failures.append("catalog did not start at the system level")
	if view.find_children("*", "ScrollContainer", true, false).size() != 0:
		failures.append("3D catalog introduced an inner ScrollContainer")
	for button_node in view.find_children("*", "Button", true, false):
		var button := button_node as Button
		if button.get_signal_connection_list("pressed").is_empty():
			failures.append("visible button '%s' has no action" % button.text)
	view.call("_select_system", "engine")
	await process_frame
	if view.selected_system != "engine" or view.level != "assemblies":
		failures.append("system selection did not open its assembly list")
	view.call("_select_assembly", "engine_front")
	await process_frame
	await process_frame
	if view.level != "node" or view.viewer == null:
		failures.append("engine front node did not create the shared 3D viewer")
	else:
		for part_id in required_engine_parts:
			if not view.viewer.component_nodes.has(part_id):
				failures.append("engine viewer has no selectable model for %s" % part_id)
		view.call("_select_part", "turbocharger")
		await process_frame
		if view.selected_part != "turbocharger" or view.level != "part":
			failures.append("selecting a 3D component did not open its detail card")
		if view.viewer == null or view.viewer.selected_part_id != "turbocharger":
			failures.append("selected component and 3D highlight are not synchronized")
		view.call("_open_level", "systems")
		await process_frame
		if view.viewer != null:
			failures.append("leaving the assembly did not release its 3D viewer")

	if failures.is_empty():
		print("3D catalog smoke check passed: %d systems, %d assemblies, %d parts; engine front viewer has %d selectable components" % [PartCatalogService.SYSTEMS.size(), assembly_ids.size(), PartCatalogService.PARTS.size(), required_engine_parts.size()])
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
