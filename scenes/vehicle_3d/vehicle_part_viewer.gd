extends Control
class_name VehiclePartViewer

signal part_selected(part_id: String)

const ACCENT := Color("38dce4")
const SURFACE := Color("0b1c25")

var subviewport_container: SubViewportContainer
var subviewport: SubViewport
var model_root: Node3D
var camera: Camera3D
var model_id := ""
var assembly_title := ""
var assembly_parts: Array = []
var focus_points: Dictionary = {}
var default_camera_focus := Vector3.ZERO
var default_camera_distance := 4.2
var component_nodes: Dictionary = {}
var selected_part_id := ""
var _touch_positions: Dictionary = {}
var _touch_start := Vector2.ZERO
var _dragged := false
var _mouse_down := false
var _mouse_start := Vector2.ZERO
var _previous_pinch_distance := 0.0
var _target := Vector3.ZERO
var _camera_distance := 4.2

func _ready() -> void:
	custom_minimum_size = Vector2(0, 300)
	clip_contents = true
	_build_viewport()
	_build_lighting()
	call_deferred("reset_view")

func load_assembly(configuration: Dictionary) -> void:
	var assembly_id := str(configuration.get("model_id", configuration.get("id", "")))
	if model_id == assembly_id and not component_nodes.is_empty():
		return
	model_id = assembly_id
	assembly_title = str(configuration.get("name", ""))
	assembly_parts = configuration.get("parts", [])
	focus_points = configuration.get("focus_points", {})
	default_camera_focus = configuration.get("camera_focus", Vector3.ZERO)
	default_camera_distance = float(configuration.get("camera_distance", 4.2))
	for child in model_root.get_children():
		if child is StaticBody3D or child is Node3D:
			child.queue_free()
	component_nodes.clear()
	if configuration.has("scene_path"):
		var packed_scene := load(str(configuration.get("scene_path", ""))) as PackedScene
		if packed_scene != null:
			model_root.add_child(packed_scene.instantiate())
		_collect_scene_components(model_root)
	elif assembly_id == "engine_front":
		_build_engine_front()
	else:
		_build_configured_components(configuration.get("components", []))
	call_deferred("reset_view")
	if not selected_part_id.is_empty():
		call_deferred("focus_part", selected_part_id)

func _build_configured_components(component_definitions: Array) -> void:
	for definition_value in component_definitions:
		var definition: Dictionary = definition_value
		var part_id := str(definition.get("id", ""))
		if part_id.is_empty():
			continue
		var position: Vector3 = definition.get("position", Vector3.ZERO)
		var size: Vector3 = definition.get("size", Vector3.ONE)
		var body := _new_component(part_id, str(definition.get("name", part_id)), position, size, component_nodes.size())
		var color: Color = definition.get("color", Color("7d898f"))
		match str(definition.get("shape", "box")):
			"sphere":
				_add_sphere_mesh(body, Vector3.ZERO, size * 0.5, color)
			"cylinder":
				_add_cylinder_mesh(body, Vector3.ZERO, maxf(size.x, size.z) * 0.5, size.y, color, Vector3.ZERO)
			_:
				_add_box_mesh(body, Vector3.ZERO, size, color)

func _collect_scene_components(node: Node) -> void:
	if node is StaticBody3D and node.has_meta("part_id"):
		var body := node as StaticBody3D
		var part_id := str(body.get_meta("part_id"))
		var meshes: Array[MeshInstance3D] = []
		var materials: Array[StandardMaterial3D] = []
		_collect_meshes(body, meshes, materials)
		component_nodes[part_id] = {"body":body, "meshes":meshes, "materials":materials, "position":body.position, "label":part_id, "index":component_nodes.size()}
	for child in node.get_children():
		_collect_scene_components(child)

func _collect_meshes(node: Node, meshes: Array[MeshInstance3D], materials: Array[StandardMaterial3D]) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override is StandardMaterial3D:
			meshes.append(mesh_instance)
			materials.append(mesh_instance.material_override as StandardMaterial3D)
	for child in node.get_children():
		_collect_meshes(child, meshes, materials)

func _build_viewport() -> void:
	var shell := PanelContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_stylebox_override("panel", _panel_style())
	add_child(shell)
	subviewport_container = SubViewportContainer.new()
	subviewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	subviewport_container.stretch = true
	subviewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	subviewport_container.gui_input.connect(_on_viewport_input)
	shell.add_child(subviewport_container)
	subviewport = SubViewport.new()
	subviewport.size = Vector2i(900, 620)
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subviewport.own_world_3d = true
	subviewport.physics_object_picking = true
	subviewport_container.add_child(subviewport)
	var world := Node3D.new()
	subviewport.add_child(world)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("08121a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("aec3d0")
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	world.add_child(environment_node)
	model_root = Node3D.new()
	model_root.name = "AssemblyModel"
	world.add_child(model_root)
	camera = Camera3D.new()
	camera.fov = 42.0
	camera.near = 0.05
	camera.far = 40.0
	world.add_child(camera)
	camera.make_current()

func _build_lighting() -> void:
	var world := model_root.get_parent()
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40.0, -28.0, 0.0)
	key.light_color = Color("e7f2ff")
	key.light_energy = 1.55
	world.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(3.0, 2.0, 3.2)
	fill.light_color = Color("b9d8e8")
	fill.omni_range = 8.0
	fill.light_energy = 1.6
	world.add_child(fill)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-3.0, 2.6, -2.6)
	rim.light_color = ACCENT
	rim.omni_range = 7.0
	rim.light_energy = 1.1
	world.add_child(rim)

func _build_engine_front() -> void:
	model_id = "engine_front"
	var block := _new_component("engine_block", "Блок двигателя", Vector3(0.0, -0.24, 0.0), Vector3(1.42, 0.78, 0.9), 0)
	_add_box_mesh(block, Vector3(0.0, -0.08, 0.0), Vector3(1.38, 0.66, 0.86), Color("65737a"))
	_add_box_mesh(block, Vector3(-0.54, -0.47, 0.0), Vector3(0.22, 0.18, 0.7), Color("4d5a60"))
	var head := _new_component("cylinder_head", "Головка блока цилиндров", Vector3(0.0, 0.36, 0.0), Vector3(1.32, 0.54, 0.84), 1)
	_add_box_mesh(head, Vector3.ZERO, Vector3(1.28, 0.5, 0.8), Color("8c999d"))
	var cover := _new_component("valve_cover", "Клапанная крышка", Vector3(0.0, 0.74, 0.0), Vector3(1.04, 0.22, 0.68), 2)
	_add_box_mesh(cover, Vector3.ZERO, Vector3(1.02, 0.18, 0.65), Color("202b30"))
	var turbo := _new_component("turbocharger", "Турбокомпрессор", Vector3(0.94, 0.03, 0.12), Vector3(0.68, 0.72, 0.62), 3)
	_add_sphere_mesh(turbo, Vector3.ZERO, Vector3(0.34, 0.36, 0.32), Color("9d6941"))
	_add_cylinder_mesh(turbo, Vector3(0.19, 0.0, 0.04), 0.18, 0.48, Color("b38a5e"), Vector3(PI / 2.0, 0.0, 0.0))
	var alternator := _new_component("alternator", "Генератор", Vector3(-0.88, -0.52, 0.28), Vector3(0.66, 0.58, 0.64), 4)
	_add_cylinder_mesh(alternator, Vector3.ZERO, 0.27, 0.5, Color("8999a2"), Vector3(PI / 2.0, 0.0, 0.0))
	_add_cylinder_mesh(alternator, Vector3(0.0, -0.02, 0.31), 0.17, 0.12, Color("46545b"), Vector3(PI / 2.0, 0.0, 0.0))
	_add_box_mesh(alternator, Vector3(0.0, -0.24, 0.0), Vector3(0.42, 0.1, 0.5), Color("5d6970"))
	var belt_drive := _new_component("accessory_belt_drive", "Ременной привод навесных агрегатов", Vector3(-0.1, -0.61, 0.48), Vector3(1.5, 0.58, 0.18), 5)
	_add_belt_loop_mesh(belt_drive)
	_add_cylinder_mesh(belt_drive, Vector3(-0.44, 0.0, -0.02), 0.21, 0.16, Color("4a5559"), Vector3(PI / 2.0, 0.0, 0.0))
	_add_cylinder_mesh(belt_drive, Vector3(0.44, 0.0, -0.02), 0.19, 0.16, Color("68757b"), Vector3(PI / 2.0, 0.0, 0.0))

func _new_component(part_id: String, display_name: String, position: Vector3, size: Vector3, index: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = part_id
	body.position = position
	body.collision_layer = 1
	body.set_meta("part_id", part_id)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size * 1.08
	collision.shape = shape
	body.add_child(collision)
	model_root.add_child(body)
	component_nodes[part_id] = {"body":body, "meshes":[], "materials":[], "position":position, "label":display_name, "index":index}
	return body


func _add_box_mesh(body: StaticBody3D, position: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	_register_mesh(body, mesh_instance, color)

func _add_sphere_mesh(body: StaticBody3D, position: Vector3, scale_value: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 8
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.scale = scale_value
	_register_mesh(body, mesh_instance, color)

func _add_cylinder_mesh(body: StaticBody3D, position: Vector3, radius: float, height: float, color: Color, rotation_value: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation = rotation_value
	_register_mesh(body, mesh_instance, color)

func _add_belt_loop_mesh(body: StaticBody3D) -> void:
	var path: Array[Vector2] = []
	var half_distance := 0.42
	var radius := 0.2
	for index in range(9):
		path.append(Vector2(lerpf(-half_distance, half_distance, float(index) / 8.0), radius))
	for index in range(1, 13):
		var angle := lerpf(PI / 2.0, -PI / 2.0, float(index) / 12.0)
		path.append(Vector2(half_distance + cos(angle) * radius, sin(angle) * radius))
	for index in range(1, 9):
		path.append(Vector2(lerpf(half_distance, -half_distance, float(index) / 8.0), -radius))
	for index in range(1, 12):
		var angle := lerpf(-PI / 2.0, -3.0 * PI / 2.0, float(index) / 12.0)
		path.append(Vector2(-half_distance + cos(angle) * radius, sin(angle) * radius))
	var rings: Array[PackedVector3Array] = []
	for index in range(path.size()):
		var before: Vector2 = path[(index - 1 + path.size()) % path.size()]
		var after: Vector2 = path[(index + 1) % path.size()]
		var tangent := (after - before).normalized()
		var width_axis := Vector2(-tangent.y, tangent.x) * 0.035
		var point: Vector2 = path[index]
		var ring := PackedVector3Array([
			Vector3(point.x + width_axis.x, point.y + width_axis.y, 0.045),
			Vector3(point.x - width_axis.x, point.y - width_axis.y, 0.045),
			Vector3(point.x - width_axis.x, point.y - width_axis.y, -0.045),
			Vector3(point.x + width_axis.x, point.y + width_axis.y, -0.045)
		])
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(rings.size()):
		var next := (index + 1) % rings.size()
		for side in range(4):
			var next_side := (side + 1) % 4
			var a: Vector3 = rings[index][side]
			var b: Vector3 = rings[index][next_side]
			var c: Vector3 = rings[next][next_side]
			var d: Vector3 = rings[next][side]
			surface.add_vertex(a)
			surface.add_vertex(b)
			surface.add_vertex(c)
			surface.add_vertex(a)
			surface.add_vertex(c)
			surface.add_vertex(d)
	surface.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = surface.commit()
	_register_mesh(body, mesh_instance, Color("202b2e"))

func _register_mesh(body: StaticBody3D, mesh_instance: MeshInstance3D, color: Color) -> void:
	var material := _material(color)
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var record: Dictionary = component_nodes[str(body.get_meta("part_id"))]
	var meshes: Array = record["meshes"]
	var materials: Array = record["materials"]
	meshes.append(mesh_instance)
	materials.append(material)
	record["meshes"] = meshes
	record["materials"] = materials
	component_nodes[str(body.get_meta("part_id"))] = record

func select_part(part_id: String) -> void:
	if not component_nodes.has(part_id):
		selected_part_id = ""
		return
	selected_part_id = part_id
	for key in component_nodes.keys():
		var row: Dictionary = component_nodes[key]
		for material_value in row["materials"]:
			var material := material_value as StandardMaterial3D
			material.emission_enabled = str(key) == selected_part_id
			material.emission = ACCENT if str(key) == selected_part_id else Color.BLACK
			material.emission_energy_multiplier = 0.7 if str(key) == selected_part_id else 0.0

func reset_view() -> void:
	if camera == null:
		return
	_target = model_root.global_transform * default_camera_focus
	_camera_distance = default_camera_distance
	model_root.rotation = Vector3(-0.13, -0.52, 0.0)
	_update_camera()

func focus_part(part_id: String) -> void:
	if not component_nodes.has(part_id):
		return
	select_part(part_id)
	var row: Dictionary = component_nodes[part_id]
	var local_focus: Vector3 = focus_points.get(part_id, row["position"])
	_target = model_root.global_transform * local_focus
	_camera_distance = 2.65
	_update_camera()

func _update_camera() -> void:
	if camera == null:
		return
	var direction := Vector3(1.0, 0.45, 1.0).normalized()
	camera.position = _target + direction * _camera_distance
	camera.look_at(_target, Vector3.UP)

func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_positions[touch.index] = touch.position
			if _touch_positions.size() == 1:
				_touch_start = touch.position
				_dragged = false
			elif _touch_positions.size() == 2:
				_previous_pinch_distance = _pinch_distance()
		else:
			if _touch_positions.size() == 1 and not _dragged:
				_pick_part(touch.position)
			_touch_positions.erase(touch.index)
			if _touch_positions.size() < 2:
				_previous_pinch_distance = 0.0
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if not _touch_positions.has(drag.index):
			return
		_touch_positions[drag.index] = drag.position
		if _touch_positions.size() >= 2:
			var distance := _pinch_distance()
			if _previous_pinch_distance > 0.0:
				_zoom((_previous_pinch_distance - distance) * 0.012)
			_previous_pinch_distance = distance
		else:
			if drag.position.distance_to(_touch_start) > 7.0:
				_dragged = true
			_rotate(drag.relative)
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mouse := event as InputEventMouseButton
		if mouse.pressed:
			_mouse_down = true
			_mouse_start = mouse.position
			_dragged = false
		else:
			if _mouse_down and not _dragged:
				_pick_part(mouse.position)
			_mouse_down = false
		return
	if event is InputEventMouseMotion and _mouse_down:
		var motion := event as InputEventMouseMotion
		if motion.position.distance_to(_mouse_start) > 5.0:
			_dragged = true
		_rotate(motion.relative)

func _rotate(delta: Vector2) -> void:
	model_root.rotation.y = wrapf(model_root.rotation.y - delta.x * 0.008, -TAU, TAU)
	model_root.rotation.x = clampf(model_root.rotation.x - delta.y * 0.008, -0.85, 0.85)

func _zoom(amount: float) -> void:
	_camera_distance = clampf(_camera_distance + amount, 1.8, 7.0)
	_update_camera()

func _pick_part(screen_position: Vector2) -> void:
	if camera == null:
		return
	var local_position := screen_position
	var display_size := subviewport_container.size
	if display_size.x > 0.0 and display_size.y > 0.0:
		local_position = Vector2(screen_position.x * float(subviewport.size.x) / display_size.x, screen_position.y * float(subviewport.size.y) / display_size.y)
	var origin := camera.project_ray_origin(local_position)
	var end := origin + camera.project_ray_normal(local_position) * 20.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 1
	var hit := subviewport.world_3d.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider := hit.get("collider") as Node
	if collider != null and collider.has_meta("part_id"):
		var part_id := str(collider.get_meta("part_id"))
		if not assembly_parts.is_empty() and part_id not in assembly_parts:
			return
		select_part(part_id)
		part_selected.emit(part_id)

func _pinch_distance() -> float:
	if _touch_positions.size() < 2:
		return 0.0
	var points := _touch_positions.values()
	return (points[0] as Vector2).distance_to(points[1] as Vector2)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.48 if color.r > 0.38 else 0.1
	material.roughness = 0.46
	return material

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SURFACE
	style.border_color = Color("1a4651")
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	return style
