extends SceneTree

const PartCatalogService = preload("res://services/part_catalog_service.gd")
const Vehicle3DView = preload("res://scenes/vehicle_3d/vehicle_3d_view.gd")

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var failures: Array[String] = []
	if PartCatalogService.SYSTEMS.size() != 16:
		failures.append("expected 16 systems, found %d" % PartCatalogService.SYSTEMS.size())
	if PartCatalogService.PARTS.size() != 140:
		failures.append("expected 140 parts, found %d" % PartCatalogService.PARTS.size())
	for system_id in PartCatalogService.SYSTEMS.keys():
		var system: Dictionary = PartCatalogService.SYSTEMS[system_id]
		if not Vehicle3DView.SYSTEM_FOCUS.has(system_id) or not Vehicle3DView.SYSTEM_FOCUS_SCALE.has(system_id):
			failures.append("system %s has no camera/highlight focus" % system_id)
		for part_id in system.get("parts", []):
			if not PartCatalogService.PARTS.has(part_id):
				failures.append("system %s refers to missing part %s" % [system_id, part_id])
	for part_id in PartCatalogService.PARTS.keys():
		var part: Dictionary = PartCatalogService.PARTS[part_id]
		var system_id := str(part.get("system", ""))
		if not PartCatalogService.SYSTEMS.has(system_id):
			failures.append("part %s refers to missing system %s" % [part_id, system_id])
		elif part_id not in PartCatalogService.SYSTEMS[system_id].get("parts", []):
			failures.append("part %s is absent from system %s list" % [part_id, system_id])
	for assembly in PartCatalogService.all_assemblies():
		for part_id in assembly.get("parts", []):
			if not PartCatalogService.PARTS.has(part_id):
				failures.append("assembly %s refers to missing part %s" % [assembly.get("id", "?"), part_id])

	var required_physical := ["wheel", "brake_disc", "brake_caliper", "brake_pads", "brake_hose", "hub", "wheel_bearing", "strut", "spring", "control_arm", "ball_joint", "stabilizer_link", "tie_rod_end", "steering_tie_rod", "steering_rack", "cv_joint_outer", "drive_shaft", "cv_joint_inner"]
	var view := Vehicle3DView.new()
	root.add_child(view)
	await process_frame
	for part_id in required_physical:
		if not view.parts.has(part_id):
			failures.append("physical scene is missing %s" % part_id)
	if view.parts.size() < 18:
		failures.append("physical scene has only %d parts" % view.parts.size())
	if view.camera == null or view.vehicle_root == null or view.assembly_root == null:
		failures.append("vehicle view did not create camera and scene roots")
	if view.system_selector == null or view.assembly_selector == null or view.part_selector == null:
		failures.append("system / assembly / part selectors were not created")
	if view._find_button("Передний левый узел") != null:
		failures.append("obsolete global view-mode controls still exist")

	if failures.is_empty():
		print("3D catalog smoke check passed: %d systems, %d assemblies, %d parts, %d physical parts" % [PartCatalogService.SYSTEMS.size(), PartCatalogService.all_assemblies().size(), PartCatalogService.PARTS.size(), view.parts.size()])
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
