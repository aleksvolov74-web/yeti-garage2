extends SceneTree

const PartCatalogService = preload("res://services/part_catalog_service.gd")
const Vehicle3DView = preload("res://scenes/vehicle_3d/vehicle_3d_view.gd")
const TechnicalCatalogService = preload("res://services/technical_catalog_service.gd")
const MobileTechnicalCatalogView = preload("res://scenes/technical_catalog/technical_catalog_view.gd")
const GlobalSearchLayout = preload("res://scenes/app/global_search_layout.gd")

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var failures: Array[String] = []
	if PartCatalogService.SYSTEMS.size() != 16:
		failures.append("expected 16 systems, found %d" % PartCatalogService.SYSTEMS.size())
	if PartCatalogService.PARTS.size() != 266:
		failures.append("expected 266 parts after electrical and lighting visual batch integration, found %d" % PartCatalogService.PARTS.size())
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
	var all_image_nodes := 0
	var all_marker_total := 0
	var verified_architecture_total := 0
	var reference_only_total := 0
	var fwd_ui_image_node_count := 0
	var fwd_ui_marker_total := 0
	var all_node_rows: Array = []
	for all_section_value in TechnicalCatalogService.catalog().get("sections", []):
		var all_section: Dictionary = all_section_value
		all_node_rows.append_array(_all_nodes_unfiltered(all_section.get("nodes", [])))
	all_catalog_nodes = all_node_rows.size()
	for all_node_value in all_node_rows:
		var all_node: Dictionary = all_node_value
		var all_diagram: Dictionary = all_node.get("diagram", {})
		if str(all_diagram.get("image", "")) != "":
			all_image_nodes += 1
		all_marker_total += all_diagram.get("markers", []).size()
		match str(all_diagram.get("verification_level", "")):
			"VERIFIED_ARCHITECTURE": verified_architecture_total += 1
			"REFERENCE_ONLY": reference_only_total += 1
	for section_value in TechnicalCatalogService.sections(vehicle_profile):
		var section: Dictionary = section_value
		for node_value in _walk_nodes(section.get("nodes", []), vehicle_profile):
			var node: Dictionary = node_value
			recursive_nodes += 1
			if str(node.get("diagram", {}).get("image", "")) != "":
				fwd_ui_image_node_count += 1
			fwd_ui_marker_total += node.get("diagram", {}).get("markers", []).size()
			if str(node.get("id", "")) == "gearbox_group" and "dsg_mechatronics" not in node.get("part_ids", []):
				failures.append("DSG assembly is missing its mechatronic component")
			if str(node.get("id", "")) == "rear_carrier" and str(node.get("variant", "")) != "FWD_POST_CW22_2010":
				failures.append("FWD rear-carrier construction is not identified")
			if str(node.get("diagram", {}).get("source", {}).get("url", "")) == "":
				failures.append("catalog node %s has no source reference" % str(node.get("id", "")))
			for part_id in node.get("part_ids", []):
				if not PartCatalogService.PARTS.has(str(part_id)):
					failures.append("technical node %s refers to missing part %s" % [str(node.get("id", "")), str(part_id)])
	if all_catalog_nodes != 90:
		failures.append("expected 90 recursive technical nodes in the full catalog, found %d" % all_catalog_nodes)
	if all_image_nodes != 90:
		failures.append("expected 90 technical nodes with images, found %d" % all_image_nodes)
	if all_marker_total != 376:
		failures.append("expected 376 technical markers, found %d" % all_marker_total)
	if verified_architecture_total != 57 or reference_only_total != 33:
		failures.append("expected 57 VERIFIED_ARCHITECTURE / 33 REFERENCE_ONLY, found %d / %d" % [verified_architecture_total, reference_only_total])
	if recursive_nodes != 86:
		failures.append("expected 86 nodes applicable to the FWD vehicle profile, found %d" % recursive_nodes)
	if fwd_ui_image_node_count != 86:
		failures.append("expected 86 FWD UI nodes with images, found %d" % fwd_ui_image_node_count)
	if fwd_ui_marker_total != 367:
		failures.append("expected 367 FWD UI markers, found %d" % fwd_ui_marker_total)
	var node_by_id: Dictionary = {}
	for section_value in TechnicalCatalogService.sections(vehicle_profile):
		var section: Dictionary = section_value
		for node_value in _walk_nodes(section.get("nodes", []), vehicle_profile):
			var node: Dictionary = node_value
			node_by_id[str(node.get("id", ""))] = node
	var ignition_node: Dictionary = node_by_id.get("ignition", {})
	if str(PartCatalogService.get_part("ignition_coil").get("name", "")) != "Модуль / трансформатор зажигания N152":
		failures.append("CBZB ignition transformer does not use the N152 catalog name")
	if ignition_node.get("part_ids", []) != ["ignition_coil", "ignition_cables", "spark_plugs", "camshaft_position_sensor", "crankshaft_position_sensor"]:
		failures.append("CBZB ignition node must contain one N152, ignition leads, four plugs, and both timing sensors")
	if str(PartCatalogService.get_part("body_control_module").get("name", "")) != "Блок бортовой сети (BCM)":
		failures.append("BCM is not identified as the body network control unit")
	var fuse_node: Dictionary = node_by_id.get("fuses_relays", {})
	if not str(fuse_node.get("variant_note", "")).contains("не точная карта предохранителей"):
		failures.append("fuse and relay diagram lacks its non-map disclaimer")
	for reference_node_id in ["power_start", "fuses_relays", "control_units", "wiring", "front_lamps", "rear_lamps", "interior_lamps"]:
		if str(node_by_id.get(reference_node_id, {}).get("diagram", {}).get("verification_level", "")) != "REFERENCE_ONLY":
			failures.append("electrical/lighting node %s must remain REFERENCE_ONLY" % reference_node_id)
	if str(node_by_id.get("interior_lamps", {}).get("variant_note", "")) != "Исполнение и органы управления освещением салона зависят от комплектации автомобиля.":
		failures.append("interior lighting variant note is missing")

	var dsg6_profile := {"year":2011, "factory_engine_code":"CBZB", "current_engine_code":"CBZB", "drivetrain":"FWD", "transmission":"DSG 6", "transmission_family":"02E / DQ250"}
	for part_id in ["gearbox_housing", "dsg_mechatronics", "dsg_mechatronics_connector", "dsg_mechatronics_actuators", "clutch_k1", "clutch_k2", "clutch_engagement_levers", "gearbox_selector_lever", "selector_cable_support"]:
		if TechnicalCatalogService.find_part(part_id, dsg6_profile).is_empty():
			continue
		failures.append("DQ200-only part %s leaked into the DSG6 profile" % part_id)
	for part_id in ["oil_pump_drive", "gearbox_housing", "dsg_mechatronics", "dsg_mechatronics_connector", "dsg_mechatronics_actuators", "clutch_k1", "clutch_k2", "clutch_engagement_levers", "gearbox_selector_lever", "selector_cable_support"]:
		if PartCatalogService.get_part(part_id).is_empty():
			failures.append("new technical-catalog part %s is missing from searchable part catalog" % part_id)
		elif PartCatalogService.search(str(PartCatalogService.get_part(part_id).get("name", ""))).is_empty():
			failures.append("new technical-catalog part %s is not returned by part search" % part_id)

	for rear_node_id in ["rear_suspension_overview", "rear_carrier", "rear_springs_dampers", "rear_hub"]:
		var rear_node: Dictionary = node_by_id.get(rear_node_id, {})
		if rear_node.is_empty() or str(rear_node.get("requires_drivetrain", "")) != "FWD" or str(rear_node.get("variant", "")) != "FWD_POST_CW22_2010":
			failures.append("rear suspension node %s is not restricted to the FWD post-CW22/2010 branch" % rear_node_id)
		for forbidden_id in ["haldex_coupling", "propshaft", "rear_drive_shaft_left", "rear_drive_shaft_right"]:
			if forbidden_id in rear_node.get("part_ids", []):
				failures.append("rear FWD node %s contains AWD-only component %s" % [rear_node_id, forbidden_id])
	var air_path_parts: Array = node_by_id.get("air_path", {}).get("part_ids", [])
	if "mass_air_flow_sensor" in air_path_parts or "air_to_air_intercooler" in air_path_parts:
		failures.append("CBZB air path contains MAF or an external air-to-air intercooler")
	if "charge_air_cooler" not in air_path_parts:
		failures.append("CBZB air path is missing its integrated liquid-cooled charge-air cooler")
	if "injectors" not in node_by_id.get("fuel_delivery", {}).get("part_ids", []):
		failures.append("CBZB direct-injection delivery node is missing injectors")
	if "dpf" in str(node_by_id.get("exhaust_aftertreatment", {}).get("part_ids", [])).to_lower():
		failures.append("gasoline CBZB exhaust aftertreatment contains a DPF")
	for reference_node_id in ["rear_carrier", "abs_esp_block", "brake_hydraulics", "fuel_storage", "coolant_circuit"]:
		if str(node_by_id.get(reference_node_id, {}).get("diagram", {}).get("verification_level", "")) != "REFERENCE_ONLY":
			failures.append("reference-only node %s was promoted to another verification status" % reference_node_id)
	for new_part_id in ["rear_subframe", "rear_upper_control_arm", "rear_lower_control_arm", "rear_trailing_arm", "rear_track_rod", "rear_anti_roll_bar", "rear_hub_carrier", "rear_suspension_bushings", "rear_spring_upper_seat", "rear_spring_lower_seat", "rear_shock_upper_mount", "rear_shock_bump_stop", "rear_abs_encoder_ring", "rear_wheel_speed_sensor", "steering_input_shaft", "steering_rack_boot", "tie_rod_lock_nut", "abs_hydraulic_unit", "abs_control_unit", "abs_pump_motor", "abs_mounting_bracket", "brake_pushrod", "brake_lines", "wheel_speed_sensor", "wheel_speed_sensor_connector", "abs_encoder_ring", "wheel_bearing_housing", "air_filter_housing", "charge_air_cooler", "intake_manifold_pressure_sensor", "charge_pressure_sensor", "charge_pressure_regulator_v465", "turbo_oil_feed_line", "turbo_coolant_lines", "charge_air_pipe", "fuel_pressure_sensor_g247", "fuel_pressure_control_valve_n276", "evap_charcoal_canister", "fuel_tank_straps", "low_temperature_radiator", "cooling_fan_secondary", "coolant_recirculation_pump_v50", "engine_oil_cooler", "turbo_heat_shield", "exhaust_flex_joint", "catalyst_heat_shield", "exhaust_clamp", "exhaust_mounts", "exhaust_heat_shield", "hvac_housing", "fresh_air_blower_control_unit_j126", "recirculation_air_flap", "ac_expansion_valve", "ac_pressure_sensor_g65", "battery_positive_cable", "battery_ground_cable", "battery_terminal_clamps", "relay_carrier", "high_current_fuse_block", "automotive_relays", "blade_fuses", "control_unit_connectors", "engine_bay_wiring_harness", "cabin_wiring_harness", "ground_straps", "bulkhead_wiring_grommet", "ignition_cables", "headlamp_bulbs", "headlamp_level_actuator", "tail_lamp_bulb_carrier", "rear_lamp_connector", "rear_interior_light", "luggage_compartment_lamp", "interior_light_bulbs", "interior_light_connector"]:
		var manifest_part := PartCatalogService.get_part(new_part_id)
		if manifest_part.is_empty():
			failures.append("new manifest part %s is not searchable in PartCatalogService" % new_part_id)
		elif PartCatalogService.search(str(manifest_part.get("name", ""))).is_empty():
			failures.append("new manifest part %s is not returned by text search" % new_part_id)

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
	await _check_front_suspension_images(failures)
	await _check_awd_reference_images(failures)
	await _check_responsive_catalog_layout(failures)
	_check_app_icon_assets(failures)

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

func _check_front_suspension_images(failures: Array[String]) -> void:
	var view := MobileTechnicalCatalogView.new()
	root.add_child(view)
	view.size = Vector2(420.0, 780.0)
	var vehicle_profile := {"year":2011, "factory_engine_code":"CBZB", "current_engine_code":"CBZB", "drivetrain":"FWD", "transmission":"DSG 7", "transmission_family":"0AM / DQ200"}
	view.set_vehicle_profile(vehicle_profile)
	await process_frame
	var expected := {
		"front_subframe_arms": {"section":"front_suspension", "count":5, "tap_part":"control_arm_left", "level":"VERIFIED_ARCHITECTURE"},
		"front_strut": {"section":"front_suspension", "count":6, "tap_part":"strut_bearing", "level":"VERIFIED_ARCHITECTURE"},
		"front_knuckle_hub": {"section":"front_suspension", "count":6, "tap_part":"steering_knuckle", "level":"VERIFIED_ARCHITECTURE"},
		"front_brake_assembly": {"section":"front_brakes", "count":7, "tap_part":"brake_caliper", "level":"VERIFIED_ARCHITECTURE"},
		"timing_chain": {"section":"timing", "count":3, "tap_part":"timing_chain", "level":"VERIFIED_ARCHITECTURE"},
		"timing_gears": {"section":"timing", "count":2, "tap_part":"timing_sprockets", "level":"VERIFIED_ARCHITECTURE"},
		"oil_pump_circuit": {"section":"lubrication", "count":3, "tap_part":"oil_pump_drive", "level":"VERIFIED_ARCHITECTURE"},
		"gearbox_group": {"section":"transmission", "count":5, "tap_part":"gearbox_housing", "level":"REFERENCE_ONLY"},
		"clutch_group": {"section":"transmission", "count":5, "tap_part":"clutch_k1", "level":"VERIFIED_ARCHITECTURE"},
		"dsg_mechatronics": {"section":"transmission", "count":3, "tap_part":"dsg_mechatronics_connector", "level":"REFERENCE_ONLY"},
		"gear_selector": {"section":"transmission", "count":4, "tap_part":"selector_cable_support", "level":"VERIFIED_ARCHITECTURE"},
		"rear_suspension_overview": {"section":"rear_suspension", "count":9, "tap_part":"rear_subframe", "level":"VERIFIED_ARCHITECTURE"},
		"rear_carrier": {"section":"rear_suspension", "count":6, "tap_part":"rear_lower_control_arm", "level":"REFERENCE_ONLY"},
		"rear_springs_dampers": {"section":"rear_suspension", "count":6, "tap_part":"rear_shock_absorber", "level":"VERIFIED_ARCHITECTURE"},
		"rear_hub": {"section":"rear_suspension", "count":7, "tap_part":"rear_hub_carrier", "level":"VERIFIED_ARCHITECTURE"},
		"steering_rack": {"section":"steering", "count":6, "tap_part":"steering_input_shaft", "level":"VERIFIED_ARCHITECTURE"},
		"steering_linkage": {"section":"steering", "count":4, "tap_part":"tie_rod_lock_nut", "level":"VERIFIED_ARCHITECTURE"},
		"abs_esp_block": {"section":"abs_esp", "count":5, "tap_part":"abs_hydraulic_unit", "level":"REFERENCE_ONLY"},
		"brake_hydraulics": {"section":"abs_esp", "count":6, "tap_part":"brake_lines", "level":"REFERENCE_ONLY"},
		"wheel_sensors": {"section":"abs_esp", "count":5, "tap_part":"wheel_speed_sensor", "level":"VERIFIED_ARCHITECTURE"},
		"air_path": {"section":"intake_boost", "count":7, "tap_part":"charge_air_cooler", "level":"VERIFIED_ARCHITECTURE"},
		"boost_group": {"section":"intake_boost", "count":6, "tap_part":"charge_pressure_regulator_v465", "level":"VERIFIED_ARCHITECTURE"},
		"fuel_delivery": {"section":"fuel", "count":5, "tap_part":"fuel_pressure_sensor_g247", "level":"VERIFIED_ARCHITECTURE"},
		"fuel_storage": {"section":"fuel", "count":6, "tap_part":"evap_charcoal_canister", "level":"REFERENCE_ONLY"},
		"radiator_pack": {"section":"cooling", "count":6, "tap_part":"low_temperature_radiator", "level":"VERIFIED_ARCHITECTURE"},
		"coolant_circuit": {"section":"cooling", "count":9, "tap_part":"coolant_recirculation_pump_v50", "level":"REFERENCE_ONLY"},
		"exhaust_front": {"section":"exhaust", "count":5, "tap_part":"exhaust_flex_joint", "level":"VERIFIED_ARCHITECTURE"},
		"exhaust_aftertreatment": {"section":"exhaust", "count":6, "tap_part":"catalyst_heat_shield", "level":"VERIFIED_ARCHITECTURE"},
		"exhaust_rear": {"section":"exhaust", "count":5, "tap_part":"exhaust_heat_shield", "level":"VERIFIED_ARCHITECTURE"},
		"engine_complete": {"section":"engine", "count":7, "tap_part":"turbocharger", "level":"VERIFIED_ARCHITECTURE"},
		"engine_bottom_end": {"section":"engine", "count":4, "tap_part":"crankshaft", "level":"VERIFIED_ARCHITECTURE"},
		"engine_block_group": {"section":"engine", "count":4, "tap_part":"piston_group", "level":"VERIFIED_ARCHITECTURE"},
		"engine_upper_end": {"section":"engine", "count":3, "tap_part":"camshafts", "level":"VERIFIED_ARCHITECTURE"},
		"cylinder_head_group": {"section":"engine", "count":3, "tap_part":"valve_cover", "level":"VERIFIED_ARCHITECTURE"},
		"engine_mounts": {"section":"engine", "count":1, "tap_part":"engine_mount", "level":"VERIFIED_ARCHITECTURE"},
		"engine_accessories": {"section":"engine", "count":3, "tap_part":"alternator", "level":"VERIFIED_ARCHITECTURE"},
		"timing_drive_node": {"section":"timing", "count":6, "tap_part":"timing_chain", "level":"VERIFIED_ARCHITECTURE"},
		"oil_filter_node": {"section":"lubrication", "count":1, "tap_part":"oil_filter", "level":"VERIFIED_ARCHITECTURE"},
		"oil_pan_node": {"section":"lubrication", "count":1, "tap_part":"oil_pan", "level":"VERIFIED_ARCHITECTURE"},
		"coolant_reservoir": {"section":"cooling", "count":1, "tap_part":"coolant_expansion_tank", "level":"VERIFIED_ARCHITECTURE"},
		"heater_box": {"section":"climate", "count":5, "tap_part":"hvac_housing", "level":"VERIFIED_ARCHITECTURE"},
		"blower": {"section":"climate", "count":5, "tap_part":"fresh_air_blower_control_unit_j126", "level":"VERIFIED_ARCHITECTURE"},
		"ac_circuit": {"section":"climate", "count":6, "tap_part":"ac_pressure_sensor_g65", "level":"VERIFIED_ARCHITECTURE"},
		"power_start": {"section":"electrical", "count":6, "tap_part":"battery_positive_cable", "level":"REFERENCE_ONLY"},
		"fuses_relays": {"section":"electrical", "count":5, "tap_part":"relay_carrier", "level":"REFERENCE_ONLY"},
		"control_units": {"section":"electrical", "count":5, "tap_part":"control_unit_connectors", "level":"REFERENCE_ONLY"},
		"wiring": {"section":"electrical", "count":5, "tap_part":"ground_straps", "level":"REFERENCE_ONLY"},
		"ignition": {"section":"electrical", "count":5, "tap_part":"ignition_cables", "level":"VERIFIED_ARCHITECTURE"},
		"front_lamps": {"section":"lighting", "count":6, "tap_part":"headlamp_bulbs", "level":"REFERENCE_ONLY"},
		"rear_lamps": {"section":"lighting", "count":5, "tap_part":"tail_lamp_bulb_carrier", "level":"REFERENCE_ONLY"},
		"interior_lamps": {"section":"lighting", "count":5, "tap_part":"rear_interior_light", "level":"REFERENCE_ONLY"},
		"body_front": {"section":"body", "count":3, "tap_part":"front_bumper", "level":"REFERENCE_ONLY"},
		"doors": {"section":"body", "count":4, "tap_part":"front_left_door", "level":"REFERENCE_ONLY"},
		"body_rear": {"section":"body", "count":2, "tap_part":"tailgate", "level":"REFERENCE_ONLY"},
		"body_protection": {"section":"body", "count":3, "tap_part":"front_wheel_arch_liner", "level":"REFERENCE_ONLY"},
		"mirrors": {"section":"body", "count":1, "tap_part":"side_mirrors", "level":"VERIFIED_ARCHITECTURE"},
		"glazing": {"section":"glass_wipers", "count":2, "tap_part":"windshield", "level":"REFERENCE_ONLY"},
		"front_wipers": {"section":"glass_wipers", "count":3, "tap_part":"wiper_motor_front", "level":"VERIFIED_ARCHITECTURE"},
		"rear_wiper": {"section":"glass_wipers", "count":1, "tap_part":"wiper_motor_rear", "level":"VERIFIED_ARCHITECTURE"},
		"washers": {"section":"glass_wipers", "count":3, "tap_part":"washer_pump", "level":"REFERENCE_ONLY"},
		"fuel_sensors": {"section":"fuel", "count":2, "tap_part":"fuel_pressure_sensor", "level":"VERIFIED_ARCHITECTURE"},
		"left_drive": {"section":"front_drive", "count":5, "tap_part":"drive_shaft", "level":"VERIFIED_ARCHITECTURE"},
		"right_drive": {"section":"front_drive", "count":5, "tap_part":"drive_shaft", "level":"VERIFIED_ARCHITECTURE"},
		"front_suspension_overview": {"section":"front_suspension", "count":9, "tap_part":"subframe", "level":"VERIFIED_ARCHITECTURE"},
		"front_left_corner": {"section":"front_suspension", "count":9, "tap_part":"control_arm", "level":"VERIFIED_ARCHITECTURE"},
		"front_right_corner": {"section":"front_suspension", "count":6, "tap_part":"control_arm", "level":"VERIFIED_ARCHITECTURE"},
		"front_axle_carrier": {"section":"front_suspension", "count":3, "tap_part":"subframe", "level":"VERIFIED_ARCHITECTURE"},
		"front_hub_bearing": {"section":"front_suspension", "count":2, "tap_part":"hub", "level":"VERIFIED_ARCHITECTURE"},
		"front_brake_at_hub": {"section":"front_suspension", "count":4, "tap_part":"brake_disc", "level":"VERIFIED_ARCHITECTURE"},
		"front_drive_at_hub": {"section":"front_suspension", "count":3, "tap_part":"drive_shaft", "level":"VERIFIED_ARCHITECTURE"},
		"front_stabilizer": {"section":"front_suspension", "count":2, "tap_part":"anti_roll_bar", "level":"VERIFIED_ARCHITECTURE"},
		"steering_column": {"section":"steering", "count":3, "tap_part":"steering_wheel", "level":"VERIFIED_ARCHITECTURE"},
		"front_brake_hose": {"section":"front_brakes", "count":4, "tap_part":"brake_carrier", "level":"VERIFIED_ARCHITECTURE"},
		"rear_brake_assembly": {"section":"rear_brakes", "count":7, "tap_part":"brake_disc", "level":"VERIFIED_ARCHITECTURE"},
		"parking_brake": {"section":"rear_brakes", "count":2, "tap_part":"parking_brake_cable", "level":"VERIFIED_ARCHITECTURE"},
		"dashboard": {"section":"interior", "count":4, "tap_part":"dashboard", "level":"REFERENCE_ONLY"},
		"console": {"section":"interior", "count":2, "tap_part":"center_console", "level":"REFERENCE_ONLY"},
		"seats": {"section":"interior", "count":3, "tap_part":"driver_seat", "level":"REFERENCE_ONLY"},
		"interior_trim": {"section":"interior", "count":2, "tap_part":"front_left_door", "level":"REFERENCE_ONLY"},
		"airbags": {"section":"safety", "count":3, "tap_part":"driver_airbag", "level":"REFERENCE_ONLY"},
		"belts": {"section":"safety", "count":2, "tap_part":"seat_belts", "level":"VERIFIED_ARCHITECTURE"},
		"srs_sensors": {"section":"safety", "count":2, "tap_part":"crash_sensors_front", "level":"REFERENCE_ONLY"},
		"filters": {"section":"maintenance", "count":4, "tap_part":"oil_filter", "level":"REFERENCE_ONLY"},
		"fluids": {"section":"maintenance", "count":3, "tap_part":"oil_system", "level":"REFERENCE_ONLY"},
		"service_ignition": {"section":"maintenance", "count":2, "tap_part":"spark_plugs", "level":"VERIFIED_ARCHITECTURE"},
		"service_brakes": {"section":"maintenance", "count":2, "tap_part":"brake_pads", "level":"REFERENCE_ONLY"}
	}
	var cbzb_dq200_marker_total := 0
	var all_image_marker_total := 0
	var expected_marker_total := 0
	for expected_value in expected.values():
		expected_marker_total += int(expected_value.get("count", 0))
	var opened_image_node_count := 0
	for node_id_value in expected:
		var node_id := str(node_id_value)
		var expected_row: Dictionary = expected[node_id]
		var section_id := str(expected_row["section"])
		view.call("_open_section", section_id)
		await process_frame
		view.call("_open_node", node_id)
		await process_frame
		var canvas = view.get("_diagram")
		if canvas == null:
			failures.append("technical diagram node %s did not create an image viewer" % node_id)
			continue
		if canvas.texture == null or canvas.markers.size() != int(expected_row["count"]):
			failures.append("technical diagram node %s image/marker count mismatch" % node_id)
			continue
		opened_image_node_count += 1
		all_image_marker_total += canvas.markers.size()
		cbzb_dq200_marker_total += canvas.markers.size() if node_id in ["timing_chain", "timing_gears", "oil_pump_circuit", "gearbox_group", "clutch_group", "dsg_mechatronics", "gear_selector"] else 0
		var current_node: Dictionary = view.call("_current_node")
		if expected_row.has("level") and str(current_node.get("diagram", {}).get("verification_level", "")) != str(expected_row["level"]):
			failures.append("technical diagram node %s has an incorrect verification level" % node_id)
		var unique_numbers: Dictionary = {}
		for marker_value in canvas.markers:
			var marker: Dictionary = marker_value
			if not PartCatalogService.PARTS.has(str(marker.get("part_id", ""))):
				failures.append("technical diagram node %s has an unknown marker part %s" % [node_id, str(marker.get("part_id", ""))])
			var marker_number := int(marker.get("number", -1))
			if unique_numbers.has(marker_number):
				failures.append("technical diagram node %s has duplicate marker number %d" % [node_id, marker_number])
			unique_numbers[marker_number] = true
			if float(marker.get("x", -1.0)) < 0.0 or float(marker.get("x", 2.0)) > 1.0 or float(marker.get("y", -1.0)) < 0.0 or float(marker.get("y", 2.0)) > 1.0:
				failures.append("technical diagram node %s has an out-of-range marker" % node_id)
		view.call("_toggle_markers")
		if canvas.markers_visible:
			failures.append("technical diagram node %s could not hide its markers" % node_id)
		view.call("_toggle_markers")
		if not canvas.markers_visible:
			failures.append("technical diagram node %s could not show its markers again" % node_id)
		canvas.size = Vector2(420.0, 320.0)
		canvas.call("reset_view")
		var touch_a := InputEventScreenTouch.new()
		touch_a.index = 0
		touch_a.pressed = true
		touch_a.position = Vector2(120.0, 120.0)
		canvas.call("_gui_input", touch_a)
		var touch_b := InputEventScreenTouch.new()
		touch_b.index = 1
		touch_b.pressed = true
		touch_b.position = Vector2(220.0, 120.0)
		canvas.call("_gui_input", touch_b)
		var pinch := InputEventScreenDrag.new()
		pinch.index = 1
		pinch.position = Vector2(250.0, 120.0)
		canvas.call("_gui_input", pinch)
		if float(canvas.get("_zoom")) <= 1.0:
			failures.append("technical diagram node %s pinch zoom did not change scale" % node_id)
		var touch_release_a := InputEventScreenTouch.new()
		touch_release_a.index = 0
		touch_release_a.pressed = false
		touch_release_a.position = Vector2(120.0, 120.0)
		canvas.call("_gui_input", touch_release_a)
		var touch_release_b := InputEventScreenTouch.new()
		touch_release_b.index = 1
		touch_release_b.pressed = false
		touch_release_b.position = Vector2(250.0, 120.0)
		canvas.call("_gui_input", touch_release_b)
		canvas.call("reset_view")
		canvas.set("_zoom", 2.0)
		var pan_touch := InputEventScreenTouch.new()
		pan_touch.index = 0
		pan_touch.pressed = true
		pan_touch.position = Vector2(120.0, 120.0)
		canvas.call("_gui_input", pan_touch)
		var pan_drag := InputEventScreenDrag.new()
		pan_drag.index = 0
		pan_drag.position = Vector2(145.0, 135.0)
		canvas.call("_gui_input", pan_drag)
		if Vector2(canvas.get("_pan")).is_zero_approx():
			failures.append("technical diagram node %s pan did not move the zoomed image" % node_id)
		var pan_release := InputEventScreenTouch.new()
		pan_release.index = 0
		pan_release.pressed = false
		pan_release.position = Vector2(145.0, 135.0)
		canvas.call("_gui_input", pan_release)
		canvas.call("reset_view")
		if not is_equal_approx(float(canvas.get("_zoom")), 1.0) or not Vector2(canvas.get("_pan")).is_zero_approx():
			failures.append("technical diagram node %s reset did not restore the initial view" % node_id)
		var marker: Dictionary = canvas.markers[0]
		var image_rect: Rect2 = canvas.call("_image_rect")
		var point := image_rect.position + Vector2(float(marker["x"]), float(marker["y"])) * image_rect.size
		canvas.call("_pick_marker", point)
		await process_frame
		if str(view.get("selected_part_id")) != str(marker.get("part_id", "")):
			failures.append("technical diagram node %s marker tap did not select its part" % node_id)
		var selected_canvas = view.get("_diagram")
		if selected_canvas == null or str(selected_canvas.get("selected_part_id")) != str(marker.get("part_id", "")):
			failures.append("technical diagram node %s marker selection was not highlighted" % node_id)
		var list_button: Button
		for button_node in view.find_children("*", "Button", true, false):
			var button := button_node as Button
			if button.has_meta("part_id") and str(button.get_meta("part_id")) == str(expected_row["tap_part"]):
				list_button = button
				break
		if list_button == null:
			failures.append("technical diagram node %s has no tappable part-list row" % node_id)
		else:
			list_button.pressed.emit()
			await process_frame
			if str(view.get("selected_part_id")) != str(expected_row["tap_part"]):
				failures.append("technical diagram node %s list tap did not select its part" % node_id)
			var selected_after_list = view.get("_diagram")
			if selected_after_list == null or str(selected_after_list.get("selected_part_id")) != str(expected_row["tap_part"]):
				failures.append("technical diagram node %s list selection did not highlight its marker" % node_id)
		var expected_part := PartCatalogService.get_part(str(expected_row["tap_part"]))
		var has_part_card := false
		for label_node in view.find_children("*", "Label", true, false):
			if str((label_node as Label).text) == str(expected_part.get("name", "")):
				has_part_card = true
		if not has_part_card:
			failures.append("technical diagram node %s part card did not open the selected component" % node_id)
		var has_clear_selection := false
		for button_node in view.find_children("*", "Button", true, false):
			if str((button_node as Button).text) == "Снять выделение":
				has_clear_selection = true
		if not has_clear_selection:
			failures.append("technical diagram node %s part card selection action is missing" % node_id)
		var node_name := str(current_node.get("name", ""))
		var node_breadcrumb: Button
		for button_node in (view.get("_breadcrumb") as HFlowContainer).get_children():
			if button_node is Button and str((button_node as Button).get_meta("full_breadcrumb_text", (button_node as Button).text)) == node_name:
				node_breadcrumb = button_node as Button
				break
		if node_breadcrumb == null:
			failures.append("technical diagram node %s has no back path from the part card" % node_id)
		else:
			node_breadcrumb.pressed.emit()
			await process_frame
			if str(view.get("selected_part_id")) != "" or view.get("_diagram") == null:
				failures.append("technical diagram node %s could not navigate back from its part card" % node_id)
		view.set("selected_part_id", "")
		view.call("_render")
		await process_frame
		if view.get("_diagram") == null or str(view.get("current_section_id")) != section_id:
			failures.append("technical diagram node %s did not return to its diagram in the catalog" % node_id)
		var section_name := str(TechnicalCatalogService.section(section_id, vehicle_profile).get("name", ""))
		var section_breadcrumb: Button
		for button_node in (view.get("_breadcrumb") as HFlowContainer).get_children():
			if button_node is Button and str((button_node as Button).text) == section_name:
				section_breadcrumb = button_node as Button
				break
		if section_breadcrumb == null:
			failures.append("technical diagram node %s has no section back navigation" % node_id)
		else:
			section_breadcrumb.pressed.emit()
			await process_frame
			var section_path: Array = view.get("current_path")
			if not section_path.is_empty():
				failures.append("technical diagram node %s did not return to its section list" % node_id)
		view.call("_open_section", section_id)
		var search_edit := view.get("_search_edit") as LineEdit
		search_edit.text = str(expected_part.get("name", ""))
		await process_frame
		var search_hit := false
		for result_value in TechnicalCatalogService.search(str(expected_part.get("name", "")), vehicle_profile):
			var result: Dictionary = result_value
			if str(result.get("part_id", "")) == str(expected_row["tap_part"]):
				search_hit = true
				view.call("open_catalog_result", result)
				break
		await process_frame
		if not search_hit or str(view.get("selected_part_id")) != str(expected_row["tap_part"]):
			failures.append("technical diagram node %s component is not searchable/openable" % node_id)
		for label_node in view.find_children("*", "Label", true, false):
			if str((label_node as Label).text) == "Изображение готовится":
				failures.append("technical diagram node %s shows an image placeholder" % node_id)
		print("Technical catalog UI flow PASS: %s" % node_id)
	if expected.size() != 86:
		failures.append("expected 86 FWD diagram nodes in the UI map, found %d" % expected.size())
	if all_image_marker_total != 367:
		failures.append("FWD technical diagrams should have 367 markers, found %d" % all_image_marker_total)
	if cbzb_dq200_marker_total != 25:
		failures.append("CBZB/DQ200 batch should have 25 markers, found %d" % cbzb_dq200_marker_total)
	if opened_image_node_count != expected.size() or all_image_marker_total != expected_marker_total:
		failures.append("expected %d image nodes / %d markers, found %d opened nodes / %d markers" % [expected.size(), expected_marker_total, opened_image_node_count, all_image_marker_total])
	view.queue_free()

func _check_awd_reference_images(failures: Array[String]) -> void:
	var view := MobileTechnicalCatalogView.new()
	root.add_child(view)
	view.size = Vector2(420.0, 780.0)
	# A separate 4x4 reference profile uses the AWD-era 02E context; it never
	# replaces the saved FWD/DQ200 profile used by the app.
	var awd_profile := {"year":2011, "factory_engine_code":"CBZB", "current_engine_code":"CBZB", "drivetrain":"AWD", "transmission":"DSG 6", "transmission_family":"02E / DQ250"}
	view.set_vehicle_profile(awd_profile)
	await process_frame
	var expected := {
		"angle_drive":{"count":2, "tap_part":"gearbox"},
		"propshaft":{"count":2, "tap_part":"propshaft"},
		"haldex":{"count":1, "tap_part":"haldex_coupling"},
		"rear_differential":{"count":4, "tap_part":"differential"}
	}
	var marker_total := 0
	for section_value in TechnicalCatalogService.sections(awd_profile):
		var section: Dictionary = section_value
		for node_value in _walk_nodes(section.get("nodes", []), awd_profile):
			var catalog_node: Dictionary = node_value
			if str(catalog_node.get("id", "")) in expected:
				if str(catalog_node.get("diagram", {}).get("verification_level", "")) != "REFERENCE_ONLY":
					failures.append("AWD reference node %s must remain REFERENCE_ONLY" % catalog_node.get("id", ""))
				marker_total += catalog_node.get("diagram", {}).get("markers", []).size()
	if marker_total != 9:
		failures.append("AWD reference nodes should have 9 markers total, found %d" % marker_total)
	if not TechnicalCatalogService.find_part("haldex_coupling", awd_profile).is_empty():
		print("AWD reference part lookup available only in temporary AWD smoke profile")
	else:
		failures.append("temporary AWD profile did not expose the Haldex reference part")
	view.call("_open_section", "awd")
	await process_frame
	for node_id_value in expected:
		var node_id := str(node_id_value)
		var row: Dictionary = expected[node_id]
		view.call("_open_node", node_id)
		await process_frame
		var node: Dictionary = view.call("_current_node")
		var canvas = view.get("_diagram")
		if node.is_empty() or canvas == null or canvas.texture == null:
			failures.append("AWD reference node %s did not load an image" % node_id)
			continue
		if str(node.get("diagram", {}).get("verification_level", "")) != "REFERENCE_ONLY":
			failures.append("AWD reference node %s was promoted beyond REFERENCE_ONLY" % node_id)
		if canvas.markers.size() != int(row["count"]):
			failures.append("AWD reference node %s marker count mismatch" % node_id)
		var seen_numbers: Dictionary = {}
		for marker_value in canvas.markers:
			var marker: Dictionary = marker_value
			var part_id := str(marker.get("part_id", ""))
			var number := int(marker.get("number", -1))
			if not PartCatalogService.PARTS.has(part_id) or part_id not in node.get("part_ids", []):
				failures.append("AWD reference node %s has an invalid marker part %s" % [node_id, part_id])
			if seen_numbers.has(number):
				failures.append("AWD reference node %s has duplicate marker number %d" % [node_id, number])
			seen_numbers[number] = true
			if float(marker.get("x", -1.0)) < 0.0 or float(marker.get("x", 2.0)) > 1.0 or float(marker.get("y", -1.0)) < 0.0 or float(marker.get("y", 2.0)) > 1.0:
				failures.append("AWD reference node %s has an out-of-range marker" % node_id)
		view.call("_toggle_markers")
		if canvas.markers_visible:
			failures.append("AWD reference node %s could not hide markers" % node_id)
		view.call("_toggle_markers")
		if not canvas.markers_visible:
			failures.append("AWD reference node %s could not show markers" % node_id)
		canvas.size = Vector2(420.0, 320.0)
		canvas.call("reset_view")
		var touch_a := InputEventScreenTouch.new()
		touch_a.index = 0
		touch_a.pressed = true
		touch_a.position = Vector2(120.0, 120.0)
		canvas.call("_gui_input", touch_a)
		var touch_b := InputEventScreenTouch.new()
		touch_b.index = 1
		touch_b.pressed = true
		touch_b.position = Vector2(220.0, 120.0)
		canvas.call("_gui_input", touch_b)
		var pinch := InputEventScreenDrag.new()
		pinch.index = 1
		pinch.position = Vector2(250.0, 120.0)
		canvas.call("_gui_input", pinch)
		if float(canvas.get("_zoom")) <= 1.0:
			failures.append("AWD reference node %s pinch zoom did not change scale" % node_id)
		var release_a := InputEventScreenTouch.new()
		release_a.index = 0
		release_a.pressed = false
		release_a.position = Vector2(120.0, 120.0)
		canvas.call("_gui_input", release_a)
		var release_b := InputEventScreenTouch.new()
		release_b.index = 1
		release_b.pressed = false
		release_b.position = Vector2(250.0, 120.0)
		canvas.call("_gui_input", release_b)
		canvas.set("_zoom", 2.0)
		var pan_touch := InputEventScreenTouch.new()
		pan_touch.index = 0
		pan_touch.pressed = true
		pan_touch.position = Vector2(120.0, 120.0)
		canvas.call("_gui_input", pan_touch)
		var pan_drag := InputEventScreenDrag.new()
		pan_drag.index = 0
		pan_drag.position = Vector2(145.0, 135.0)
		canvas.call("_gui_input", pan_drag)
		if Vector2(canvas.get("_pan")).is_zero_approx():
			failures.append("AWD reference node %s pan did not move the zoomed image" % node_id)
		var pan_release := InputEventScreenTouch.new()
		pan_release.index = 0
		pan_release.pressed = false
		pan_release.position = Vector2(145.0, 135.0)
		canvas.call("_gui_input", pan_release)
		canvas.call("reset_view")
		if not is_equal_approx(float(canvas.get("_zoom")), 1.0) or not Vector2(canvas.get("_pan")).is_zero_approx():
			failures.append("AWD reference node %s reset did not restore the initial view" % node_id)
		var marker: Dictionary = canvas.markers[0]
		var image_rect: Rect2 = canvas.call("_image_rect")
		var tap_point := image_rect.position + Vector2(float(marker["x"]), float(marker["y"])) * image_rect.size
		canvas.call("_pick_marker", tap_point)
		await process_frame
		if str(view.get("selected_part_id")) != str(marker.get("part_id", "")):
			failures.append("AWD reference node %s marker tap selected the wrong part" % node_id)
		var list_button: Button
		for button_node in view.find_children("*", "Button", true, false):
			var button := button_node as Button
			if button.has_meta("part_id") and str(button.get_meta("part_id")) == str(row["tap_part"]):
				list_button = button
				break
		if list_button == null:
			failures.append("AWD reference node %s has no matching part list row" % node_id)
		else:
			list_button.pressed.emit()
			await process_frame
			var list_selected_canvas = view.get("_diagram")
			if str(view.get("selected_part_id")) != str(row["tap_part"]) or list_selected_canvas == null or str(list_selected_canvas.get("selected_part_id")) != str(row["tap_part"]):
				failures.append("AWD reference node %s list/marker selection is out of sync" % node_id)
		var part: Dictionary = PartCatalogService.get_part(str(row["tap_part"]))
		var found_card := false
		for label_node in view.find_children("*", "Label", true, false):
			if str((label_node as Label).text) == str(part.get("name", "")):
				found_card = true
			if str((label_node as Label).text) == "Изображение готовится":
				failures.append("AWD reference node %s shows an image placeholder" % node_id)
		if not found_card:
			failures.append("AWD reference node %s did not show the selected part card" % node_id)
		var node_name := str(node.get("name", ""))
		var node_crumb: Button
		for crumb_value in (view.get("_breadcrumb") as HFlowContainer).get_children():
			if crumb_value is Button and str((crumb_value as Button).text) == node_name:
				node_crumb = crumb_value as Button
				break
		if node_crumb == null:
			failures.append("AWD reference node %s has no back navigation" % node_id)
		else:
			node_crumb.pressed.emit()
			await process_frame
			if str(view.get("selected_part_id")) != "" or view.get("_diagram") == null:
				failures.append("AWD reference node %s could not return from the part card" % node_id)
		var section_name := str(TechnicalCatalogService.section("awd", awd_profile).get("name", ""))
		var section_crumb: Button
		for crumb_value in (view.get("_breadcrumb") as HFlowContainer).get_children():
			if crumb_value is Button and str((crumb_value as Button).text) == section_name:
				section_crumb = crumb_value as Button
				break
		if section_crumb == null:
			failures.append("AWD reference node %s has no back navigation to AWD list" % node_id)
		else:
			section_crumb.pressed.emit()
			await process_frame
			if not (view.get("current_path") as Array).is_empty():
				failures.append("AWD reference node %s did not return to AWD section list" % node_id)
		view.call("_open_section", "awd")
		var search_edit := view.get("_search_edit") as LineEdit
		search_edit.text = str(part.get("name", ""))
		await process_frame
		var search_opened := false
		for result_value in TechnicalCatalogService.search(str(part.get("name", "")), awd_profile):
			var result: Dictionary = result_value
			if str(result.get("part_id", "")) == str(row["tap_part"]):
				view.call("open_catalog_result", result)
				search_opened = true
				break
		await process_frame
		if not search_opened or str(view.get("selected_part_id")) != str(row["tap_part"]):
			failures.append("AWD reference node %s detail was not searchable" % node_id)
		print("AWD reference UI flow PASS: %s" % node_id)
	view.queue_free()

func _check_responsive_catalog_layout(failures: Array[String]) -> void:
	var fwd_profile := {"year":2011, "factory_engine_code":"CBZB", "current_engine_code":"CBZB", "drivetrain":"FWD", "transmission":"DSG 7", "transmission_family":"0AM / DQ200"}
	for viewport_width in [360, 420]:
		var test_viewport := SubViewport.new()
		test_viewport.size = Vector2i(viewport_width, 780)
		test_viewport.size_2d_override = Vector2i(viewport_width, 780)
		test_viewport.size_2d_override_stretch = true
		test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		test_viewport.gui_embed_subwindows = true
		root.add_child(test_viewport)
		await process_frame
		var host := Control.new()
		host.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		host.position = Vector2.ZERO
		host.size = Vector2(viewport_width, 780)
		test_viewport.add_child(host)
		var outer := ScrollContainer.new()
		outer.name = "Technical catalog test scroll"
		outer.position = Vector2.ZERO
		outer.size = Vector2(viewport_width, 780)
		outer.custom_minimum_size = outer.size
		outer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		outer.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		outer.scroll_deadzone = 10
		outer.mouse_filter = Control.MOUSE_FILTER_STOP
		host.add_child(outer)
		outer.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		outer.anchor_left = 0.0
		outer.anchor_right = 0.0
		outer.anchor_top = 0.0
		outer.anchor_bottom = 0.0
		outer.offset_left = 0.0
		outer.offset_top = 0.0
		outer.offset_right = float(viewport_width)
		outer.offset_bottom = 780.0
		outer.size = Vector2(viewport_width, 780)
		var page := VBoxContainer.new()
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		page.mouse_filter = Control.MOUSE_FILTER_PASS
		outer.add_child(page)
		var view := MobileTechnicalCatalogView.new()
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		view.set_vehicle_profile(fwd_profile)
		page.add_child(view)
		await _wait_for_layout(4)
		var content: VBoxContainer = view.get("_content")
		var grids := content.find_children("*", "GridContainer", true, false)
		if grids.is_empty():
			failures.append("%dpx system page has no responsive grid" % viewport_width)
			outer.queue_free()
			continue
		var section_grid := grids[0] as GridContainer
		print("Mobile layout dimensions: requested=%d subviewport=%s outer=%s host=%s page=%s view=%s content=%s grid=%s columns=%d" % [viewport_width, test_viewport.size, outer.size, host.size, page.size, view.size, content.size, section_grid.size, section_grid.columns])
		if section_grid.columns != 1:
			failures.append("%dpx system page should use one readable column, found %d" % [viewport_width, section_grid.columns])
		if section_grid.size.x > outer.size.x + 1.0 or section_grid.get_global_rect().end.x > outer.get_global_rect().end.x + 1.0:
			failures.append("%dpx system grid exceeds the mobile viewport" % viewport_width)
		var section_card: Button
		if section_grid.get_child_count() > 0:
			section_card = section_grid.get_child(0) as Button
		if section_card == null:
			failures.append("%dpx system grid has no section card" % viewport_width)
		else:
			if section_card.mouse_filter != Control.MOUSE_FILTER_PASS or section_card.get_child_count() == 0:
				failures.append("%dpx system card does not pass touch or contain its full-rect layout" % viewport_width)
			else:
				var section_margin := section_card.get_child(0) as MarginContainer
				if section_margin.size.x < section_card.size.x - 4.0 or section_margin.get_global_rect().end.x > outer.get_global_rect().end.x + 1.0:
					failures.append("%dpx system card text container is narrower than the card or overflows" % viewport_width)
			await _send_mobile_drag(test_viewport, section_card.get_global_rect().get_center(), section_card.get_global_rect().get_center() + Vector2(0, -110))
			if outer.scroll_vertical <= 0 or view.get("current_section_id") != "":
				failures.append("%dpx swipe over a section card did not scroll without activating it" % viewport_width)

		outer.scroll_vertical = 0
		view.call("_open_section", "engine")
		await _wait_for_layout(3)
		var node_card := _first_catalog_card(content, false)
		if node_card == null:
			failures.append("%dpx engine node list has no tappable node card" % viewport_width)
		else:
			if node_card.mouse_filter != Control.MOUSE_FILTER_PASS or node_card.size.x > outer.size.x + 1.0 or node_card.get_global_rect().end.x > outer.get_global_rect().end.x + 1.0:
				failures.append("%dpx node card has incorrect touch policy or horizontal overflow" % viewport_width)
			await _send_mobile_drag(test_viewport, node_card.get_global_rect().get_center(), node_card.get_global_rect().get_center() + Vector2(0, -100))
			if outer.scroll_vertical <= 0 or not (view.get("current_path") as Array).is_empty():
				failures.append("%dpx swipe over a node card did not scroll without opening it" % viewport_width)

		outer.scroll_vertical = 0
		view.call("_open_node", "engine_upper_end")
		await _wait_for_layout(4)
		var part_card := _first_catalog_card(content, true)
		if part_card == null:
			failures.append("%dpx cylinder-head page has no part list card" % viewport_width)
		else:
			outer.scroll_vertical = maxi(0, int(part_card.position.y - 180.0))
			await _wait_for_layout(2)
			if part_card.mouse_filter != Control.MOUSE_FILTER_PASS or part_card.size.x > outer.size.x + 1.0:
				failures.append("%dpx part card has incorrect touch policy or horizontal overflow" % viewport_width)
			await _send_mobile_drag(test_viewport, part_card.get_global_rect().get_center(), part_card.get_global_rect().get_center() + Vector2(0, -100))
			if outer.scroll_vertical <= 0 or str(view.get("selected_part_id")) != "":
				failures.append("%dpx swipe over a part card did not scroll without selecting it" % viewport_width)

		view.call("_open_node", "cylinder_head_group")
		outer.scroll_vertical = 0
		await _wait_for_layout(4)
		var viewport_rect := outer.get_global_rect()
		var title: Label = view.get("_title")
		if title.get_global_rect().end.x > viewport_rect.end.x + 1.0 or title.size.x < viewport_width - 24.0 or title.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
			failures.append("%dpx long node title overflows or does not use the available width" % viewport_width)
		var breadcrumb: HFlowContainer = view.get("_breadcrumb")
		if breadcrumb.get_global_rect().end.x > viewport_rect.end.x + 1.0:
			failures.append("%dpx breadcrumb container exceeds viewport width" % viewport_width)
		for breadcrumb_child in breadcrumb.get_children():
			if breadcrumb_child is Button:
				var crumb := breadcrumb_child as Button
				if crumb.mouse_filter != Control.MOUSE_FILTER_PASS or crumb.get_global_rect().end.x > viewport_rect.end.x + 1.0:
					failures.append("%dpx breadcrumb item overflows or blocks navigation gestures" % viewport_width)

		var canvas: Control = view.get("_diagram")
		if canvas == null:
			failures.append("%dpx long-title node has no diagram canvas" % viewport_width)
		else:
			var marker: Dictionary = canvas.get("markers")[0]
			var image_rect: Rect2 = canvas.call("_image_rect")
			var marker_position := canvas.global_position + image_rect.position + Vector2(float(marker["x"]), float(marker["y"])) * image_rect.size
			outer.scroll_vertical = 0
			await _send_mobile_drag(test_viewport, marker_position, marker_position + Vector2(0, -115))
			if outer.scroll_vertical <= 0:
				failures.append("%dpx zoom=1 swipe over the diagram did not scroll the page" % viewport_width)
			if not Vector2(canvas.get("_pan")).is_zero_approx() or str(view.get("selected_part_id")) != "":
				failures.append("%dpx zoom=1 scroll panned the image or falsely selected a marker" % viewport_width)

			outer.scroll_vertical = 0
			canvas.set("_zoom", 2.0)
			canvas.call("_update_input_routing")
			var zoomed_origin := canvas.get_global_rect().get_center()
			await _send_mobile_drag(test_viewport, zoomed_origin, zoomed_origin + Vector2(-100, 0))
			if Vector2(canvas.get("_pan")).is_zero_approx() or outer.scroll_vertical != 0:
				failures.append("%dpx zoomed diagram drag did not pan exclusively inside the image" % viewport_width)

			canvas.call("reset_view")
			outer.scroll_vertical = 0
			await _send_mobile_drag(test_viewport, canvas.get_global_rect().get_center(), canvas.get_global_rect().get_center() + Vector2(0, -115))
			if outer.scroll_vertical <= 0 or not Vector2(canvas.get("_pan")).is_zero_approx():
				failures.append("%dpx reset zoom did not restore page scrolling over the diagram" % viewport_width)

			outer.scroll_vertical = 0
			await _send_mobile_pinch(test_viewport, canvas.get_global_rect().get_center(), 28.0)
			if float(canvas.get("_zoom")) <= 1.01:
				failures.append("%dpx two-finger pinch did not zoom the diagram" % viewport_width)
			canvas.call("reset_view")
			var final_part_card := _first_catalog_card(content, true)
			if final_part_card != null:
				var bar := outer.get_v_scroll_bar()
				outer.scroll_vertical = maxi(0, int(bar.max_value - bar.page))
				await _wait_for_layout(3)
				var last_content := content.get_child(content.get_child_count() - 1) as Control
				if outer.scroll_vertical <= 0 or last_content.get_global_rect().end.y > outer.get_global_rect().end.y + 2.0:
					failures.append("%dpx technical catalog page bottom is not reachable" % viewport_width)
		print("Responsive catalog layout and scroll PASS: %dpx" % viewport_width)
		test_viewport.queue_free()
		await process_frame

	var app_source_file := FileAccess.open("res://scenes/app/app.gd", FileAccess.READ)
	var app_source := app_source_file.get_as_text() if app_source_file != null else ""
	if not app_source.contains("_style_global_search_result_button(catalog_button)") or not app_source.contains("GlobalSearchLayout.style_result_button(button)"):
		failures.append("global search result rows are not wired to the responsive layout helper")
	for viewport_width in [360, 420]:
		var popup_size: Vector2i = GlobalSearchLayout.popup_size(Vector2i(400, 700), Vector2i(viewport_width, 780))
		var content_width := GlobalSearchLayout.content_width(370.0, float(viewport_width))
		if popup_size.x > viewport_width or content_width > viewport_width - 24.0:
			failures.append("global search popup sizing exceeds %dpx viewport" % viewport_width)
		var results := VBoxContainer.new()
		results.size = Vector2(content_width - 28.0, 500)
		results.custom_minimum_size.x = content_width - 28.0
		root.add_child(results)
		var long_result := Button.new()
		long_result.text = "Головка блока цилиндров и клапанный механизм — техническое описание"
		long_result.custom_minimum_size.y = 48
		GlobalSearchLayout.style_result_button(long_result)
		results.add_child(long_result)
		await _wait_for_layout(2)
		if not long_result.clip_text or long_result.text_overrun_behavior != TextServer.OVERRUN_TRIM_ELLIPSIS or long_result.size.x > results.size.x + 1.0:
			failures.append("global search result is not safely ellipsized within its %dpx popup" % viewport_width)
		results.queue_free()
	print("Responsive global search layout PASS: 360px / 420px")

func _first_catalog_card(content: VBoxContainer, require_part_id: bool) -> Button:
	for button_value in content.find_children("*", "Button", true, false):
		var button := button_value as Button
		if require_part_id and button.has_meta("part_id"):
			return button
		if not require_part_id and button.get_child_count() > 0 and button.get_child(0) is MarginContainer and not button.has_meta("part_id"):
			return button
	return null

func _wait_for_layout(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame

func _send_mobile_drag(viewport: Viewport, start: Vector2, finish: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.device = 0
	press.index = 0
	press.pressed = true
	press.position = start
	viewport.push_input(press)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.device = 0
	drag.index = 0
	drag.position = finish
	drag.relative = finish - start
	viewport.push_input(drag)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.device = 0
	release.index = 0
	release.pressed = false
	release.position = finish
	viewport.push_input(release)
	await _wait_for_layout(2)

func _send_mobile_pinch(viewport: Viewport, center: Vector2, radius: float) -> void:
	var first := InputEventScreenTouch.new()
	first.device = 0
	first.index = 0
	first.pressed = true
	first.position = center + Vector2(-radius, 0)
	viewport.push_input(first)
	await process_frame
	var second := InputEventScreenTouch.new()
	second.device = 0
	second.index = 1
	second.pressed = true
	second.position = center + Vector2(radius, 0)
	viewport.push_input(second)
	await process_frame
	var pinch := InputEventScreenDrag.new()
	pinch.device = 0
	pinch.index = 1
	pinch.position = center + Vector2(radius * 2.0, 0)
	pinch.relative = Vector2(radius, 0)
	viewport.push_input(pinch)
	await process_frame
	second.pressed = false
	viewport.push_input(second)
	await process_frame
	first.pressed = false
	viewport.push_input(first)
	await _wait_for_layout(2)

func _check_app_icon_assets(failures: Array[String]) -> void:
	var expected_sizes := {
		"res://assets/icons/app_icon_192.png": Vector2i(192, 192),
		"res://assets/icons/app_icon_512.png": Vector2i(512, 512),
		"res://assets/icons/adaptive_foreground_432.png": Vector2i(432, 432),
		"res://assets/icons/adaptive_background_432.png": Vector2i(432, 432)
	}
	for path_value in expected_sizes:
		var path := str(path_value)
		var texture := ResourceLoader.load(path) as Texture2D
		if texture == null or Vector2i(texture.get_width(), texture.get_height()) != expected_sizes[path]:
			failures.append("application icon asset %s is missing, unreadable, or has the wrong size" % path)
	if str(ProjectSettings.get_setting("application/config/icon", "")) != "res://assets/icons/app_icon_512.png":
		failures.append("project icon setting does not use the refreshed 512px app icon")
	var presets := ConfigFile.new()
	if presets.load("res://export_presets.cfg") != OK:
		failures.append("Android export presets could not be loaded for icon validation")
	else:
		for key in ["launcher_icons/main_192x192", "launcher_icons/adaptive_foreground_432x432", "launcher_icons/adaptive_background_432x432"]:
			var path := str(presets.get_value("preset.0.options", key, ""))
			if not expected_sizes.has(path):
				failures.append("Android export preset %s does not point to a checked updated icon" % key)

func _walk_nodes(rows: Array, vehicle: Dictionary) -> Array:
	var result: Array = []
	for value in rows:
		var node: Dictionary = value
		if not TechnicalCatalogService.is_compatible(node, vehicle):
			continue
		result.append(node)
		result.append_array(_walk_nodes(node.get("children", []), vehicle))
	return result

func _all_nodes_unfiltered(rows: Array) -> Array:
	var result: Array = []
	for value in rows:
		var node: Dictionary = value
		result.append(node)
		result.append_array(_all_nodes_unfiltered(node.get("children", [])))
	return result

func _count_all_nodes(rows: Array) -> int:
	var count := 0
	for value in rows:
		var node: Dictionary = value
		count += 1 + _count_all_nodes(node.get("children", []))
	return count
