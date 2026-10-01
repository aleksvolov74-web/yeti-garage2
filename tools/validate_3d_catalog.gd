extends SceneTree

const PartCatalogService = preload("res://services/part_catalog_service.gd")
const Vehicle3DView = preload("res://scenes/vehicle_3d/vehicle_3d_view.gd")
const TechnicalCatalogService = preload("res://services/technical_catalog_service.gd")
const MobileTechnicalCatalogView = preload("res://scenes/technical_catalog/technical_catalog_view.gd")

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var failures: Array[String] = []
	if PartCatalogService.SYSTEMS.size() != 16:
		failures.append("expected 16 systems, found %d" % PartCatalogService.SYSTEMS.size())
	if PartCatalogService.PARTS.size() != 175:
		failures.append("expected 175 parts, found %d" % PartCatalogService.PARTS.size())
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

	var vehicle_profile := {"year":2011, "factory_engine_code":"CBZB", "current_engine_code":"CBZB", "drivetrain":"FWD", "transmission":"DSG 7", "transmission_family":"0AM / DQ200"}
	var technical_sections := TechnicalCatalogService.sections({"drivetrain":"AWD"})
	if technical_sections.size() != 24:
		failures.append("mobile technical catalog should define 24 sections, found %d" % technical_sections.size())
	if TechnicalCatalogService.sections(vehicle_profile).size() != 23:
		failures.append("4x4 section was not filtered for the saved FWD configuration")
	var recursive_nodes := 0
	var all_catalog_nodes := 0
	for section_value in TechnicalCatalogService.sections({"drivetrain":"AWD"}):
		var all_section: Dictionary = section_value
		all_catalog_nodes += _walk_nodes(all_section.get("nodes", []), {"drivetrain":"AWD"}).size()
	for section_value in TechnicalCatalogService.sections(vehicle_profile):
		var section: Dictionary = section_value
		for node_value in _walk_nodes(section.get("nodes", []), vehicle_profile):
			var node: Dictionary = node_value
			recursive_nodes += 1
			if str(node.get("id", "")) == "gearbox_group" and "dsg_mechatronic" not in node.get("part_ids", []):
				failures.append("DSG assembly is missing its mechatronic component")
			if str(node.get("id", "")) == "rear_carrier" and str(node.get("variant", "")) != "FWD_POST_CW22_2010":
				failures.append("FWD rear-carrier construction is not identified")
			if str(node.get("diagram", {}).get("source", {}).get("url", "")) == "":
				failures.append("catalog node %s has no source reference" % str(node.get("id", "")))
			for part_id in node.get("part_ids", []):
				if not PartCatalogService.PARTS.has(str(part_id)):
					failures.append("technical node %s refers to missing part %s" % [str(node.get("id", "")), str(part_id)])
	if all_catalog_nodes != 89:
		failures.append("expected 89 recursive technical nodes in the full catalog, found %d" % all_catalog_nodes)
	if recursive_nodes != 85:
		failures.append("expected 85 nodes applicable to the FWD vehicle profile, found %d" % recursive_nodes)
	var node_by_id: Dictionary = {}
	for section_value in TechnicalCatalogService.sections(vehicle_profile):
		var section: Dictionary = section_value
		for node_value in _walk_nodes(section.get("nodes", []), vehicle_profile):
			var node: Dictionary = node_value
			node_by_id[str(node.get("id", ""))] = node
	if "mass_air_flow_sensor" in node_by_id.get("fuel_sensors", {}).get("part_ids", []):
		failures.append("fuel sensor node incorrectly treats the mass-air-flow sensor as a fuel sensor")
	if "front_fender" in node_by_id.get("body_protection", {}).get("part_ids", []):
		failures.append("body-protection node incorrectly refers to the front fender")
	if not TechnicalCatalogService.find_part("haldex_coupling", vehicle_profile).is_empty():
		failures.append("AWD Haldex component was not filtered from the FWD vehicle profile")
	if "propshaft" in node_by_id.get("left_drive", {}).get("part_ids", []):
		failures.append("front drive node incorrectly refers to the propshaft")
	if "parking_brake_cable" not in node_by_id.get("parking_brake", {}).get("part_ids", []):
		failures.append("parking-brake node is missing its cable component")
	for part_id in PartCatalogService.PARTS.keys():
		var catalog_part: Dictionary = PartCatalogService.PARTS[part_id]
		if str(catalog_part.get("requires_drivetrain", "")) in ["AWD", "4WD", "4X4"]:
			continue
		if TechnicalCatalogService.find_part(str(part_id), vehicle_profile).is_empty():
			failures.append("existing part %s is unreachable in the mobile catalog" % part_id)
	var symptom_results := TechnicalCatalogService.search("стук спереди", {"drivetrain":"FWD"})
	var found_suspension_symptom := false
	for result_value in symptom_results:
		var result: Dictionary = result_value
		if str(result.get("kind", "")) == "diagnostic" and str(result.get("flow_id", "")) == "suspension_knock":
			found_suspension_symptom = true
	if not found_suspension_symptom:
		failures.append("symptom search did not return its existing diagnostic path")

	var mobile_view := MobileTechnicalCatalogView.new()
	root.add_child(mobile_view)
	mobile_view.size = Vector2(420.0, 780.0)
	await process_frame
	await process_frame
	if mobile_view.find_children("*", "ScrollContainer", true, false).size() != 0:
		failures.append("mobile catalog introduced a nested ScrollContainer")
	mobile_view.call("_open_section", "front_suspension")
	await process_frame
	mobile_view.call("_open_node", "front_suspension_overview")
	await process_frame
	if mobile_view.current_section_id != "front_suspension" or mobile_view.current_path.size() != 1:
		failures.append("mobile catalog did not open its nested front suspension node")
	mobile_view.focus_part("wheel_bearing")
	await process_frame
	if mobile_view.selected_part_id != "wheel_bearing" or mobile_view.current_section_id == "":
		failures.append("existing part deep link did not reach the mobile detail card")
	for button_node in mobile_view.find_children("*", "Button", true, false):
		var button := button_node as Button
		if button.get_signal_connection_list("pressed").is_empty():
			failures.append("mobile catalog button '%s' has no action" % button.text)
	mobile_view.queue_free()

	if failures.is_empty():
		print("Catalog smoke check passed: desktop 3D preserved; mobile 2D catalog has %d sections, %d systems, %d assemblies, %d parts" % [technical_sections.size(), PartCatalogService.SYSTEMS.size(), assembly_ids.size(), PartCatalogService.PARTS.size()])
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _walk_nodes(rows: Array, vehicle: Dictionary) -> Array:
	var result: Array = []
	for value in rows:
		var node: Dictionary = value
		if not TechnicalCatalogService.is_compatible(node, vehicle):
			continue
		result.append(node)
		result.append_array(_walk_nodes(node.get("children", []), vehicle))
	return result
