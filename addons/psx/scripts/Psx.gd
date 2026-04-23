@tool class_name Psx extends EditorPlugin

#region Sub-Plugins

class PsxFileSystemContextMenuPlugin extends EditorContextMenuPlugin:
	var plugin: Psx


	func _init(__plugin__: Psx) -> void:
		plugin = __plugin__


	func _popup_menu(paths: PackedStringArray) -> void:
		add_context_menu_item("Convert Selected Resource(s) to PSX...", plugin.convert_resource_paths_context)


class PsxSceneTreeContextMenuPlugin extends EditorContextMenuPlugin:
	var plugin: Psx


	func _init(__plugin__: Psx) -> void:
		plugin = __plugin__


	func _popup_menu(paths: PackedStringArray) -> void:
		add_context_menu_item("Convert Node(s) to PSX...", plugin.convert_selected_nodes_context)


class PsxInspectorPlugin extends EditorInspectorPlugin:
	const META_IGNORE := &"_psx_ignore"
	const META_MATERIAL := &"_psx_material"


	func _can_handle(object: Object) -> bool:
		return object is Node


	func _parse_group(object: Object, group: String) -> void:
		if object is not Node or group != "Editor Description": return

		var container := VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL


		var ignore_container := HBoxContainer.new()
		ignore_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(ignore_container)

		var ignore_label := Label.new()
		ignore_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ignore_label.text = "PSX Ignore"
		ignore_label.mouse_filter = Control.MOUSE_FILTER_STOP
		ignore_label.tooltip_text = "Adds an editor-only meta value '%s' (int)\nwhich will determine if PSX Conversion can occur on this Node." % META_IGNORE
		ignore_container.add_child(ignore_label)

		var ignore_option := OptionButton.new()
		ignore_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ignore_option.add_item("None")
		ignore_option.add_item("Ignore Self")
		ignore_option.add_item("Ignore Self and Children")
		ignore_option.item_selected.connect(_ignore_option_selected.bind(object))
		if object.has_meta(META_IGNORE):
			ignore_option.select(object.get_meta(META_IGNORE))
		ignore_container.add_child(ignore_option)


		## This is dumb. If you're going to add this option, why not just set the material directly in the Node itself?

		# var auto_container := HBoxContainer.new()
		# auto_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# container.add_child(auto_container)

		# var auto_label := Label.new()
		# auto_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# auto_label.text = "PSX Auto Apply"
		# auto_label.tooltip_text = "Adds an editor-only meta value '%s' (Material).\nThis Material will be applied" % META_MATERIAL
		# auto_container.add_child(auto_label)

		# var auto_option := EditorResourcePicker.new()
		# auto_option.base_type = "Material"
		# auto_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# auto_option.resource_changed.connect(_auto_resource_changed.bind(object))
		# if object.has_meta(META_MATERIAL):
		# 	auto_option.edited_resource = object.get_meta(META_MATERIAL)
		# auto_container.add_child(auto_option)

		add_custom_control(container)


	func _ignore_option_selected(idx: int, node: Node) -> void:
		match idx:
			0: node.set_meta(META_IGNORE, null)
			1: node.set_meta(META_IGNORE, 1)
			2: node.set_meta(META_IGNORE, 2)


	func _auto_resource_changed(resource: Material, node: Node) -> void:
		node.set_meta(META_MATERIAL, resource if resource else null)

#endregion

#region Shader Globals

const GLOBAL_VARS := {
	&"psx_affine_strength": {
		"rtype": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"type": "float",
		"value": 1.0,
	},
	&"psx_bit_depth": {
		"rtype": RenderingServer.GLOBAL_VAR_TYPE_UINT,
		"type": "uint",
		"value": 5,
	},
	&"psx_fog_color": {
		"rtype": RenderingServer.GLOBAL_VAR_TYPE_COLOR,
		"type": "color",
		"value": Color(0.5, 0.5, 0.5, 0.0),
	},
	&"psx_fog_far": {
		"rtype": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"type": "float",
		"value": 20.0,
	},
	&"psx_fog_near": {
		"rtype": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"type": "float",
		"value": 10.0,
	},
	&"psx_precision_uv": {
		"rtype": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"type": "float",
		"value": 128.0,
	},
	&"psx_precision_xy": {
		"rtype": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"type": "float",
		"value": 256.0,
	},
	&"psx_precision_z": {
		"rtype": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"type": "float",
		"value": 512.0,
	},
}

static var affine_strength: float:
	get: return RenderingServer.global_shader_parameter_get(&"psx_affine_strength")
	set(value): RenderingServer.global_shader_parameter_set(&"psx_affine_strength", value)

static var bit_depth: int:
	get: return RenderingServer.global_shader_parameter_get(&"psx_bit_depth")
	set(value): RenderingServer.global_shader_parameter_set(&"psx_bit_depth", value)

static var fog_color: Color:
	get: return RenderingServer.global_shader_parameter_get(&"psx_fog_color")
	set(value): RenderingServer.global_shader_parameter_set(&"psx_fog_color", value)

static var fog_far: float:
	get: return RenderingServer.global_shader_parameter_get(&"psx_fog_far")
	set(value): RenderingServer.global_shader_parameter_set(&"psx_fog_far", value)

static var fog_near: float:
	get: return RenderingServer.global_shader_parameter_get(&"psx_fog_near")
	set(value): RenderingServer.global_shader_parameter_set(&"psx_fog_near", value)

static var precision_uv: float:
	get: return RenderingServer.global_shader_parameter_get(&"psx_precision_uv")
	set(value): RenderingServer.global_shader_parameter_set(&"psx_precision_uv", value)

static var precision_xy: float:
	get: return RenderingServer.global_shader_parameter_get(&"psx_precision_xy")
	set(value): RenderingServer.global_shader_parameter_set(&"psx_precision_xy", value)

static var precision_z: float:
	get: return RenderingServer.global_shader_parameter_get(&"psx_precision_z")
	set(value): RenderingServer.global_shader_parameter_set(&"psx_precision_z", value)


static func touch_shader_globals() -> void:
	for k: StringName in GLOBAL_VARS.keys():
		var setting := "shader_globals/" + k
		if not ProjectSettings.has_setting(setting):
			var data: Dictionary = GLOBAL_VARS[k].duplicate()
			RenderingServer.global_shader_parameter_add(k, data[&"rtype"], data[&"value"])
			data.erase(&"rtype")
			ProjectSettings.set_setting(setting, data)
			ProjectSettings.set_initial_value(setting, data[&"value"])

	ProjectSettings.save()

#endregion

const AUTOLOAD_NAME := "psx_post_process"
const AUTOLOAD_PATH := "res://addons/psx/scripts/PsxPostProcessAutoload.gd"
const CONVERT_CURRENT_SCENE_NAME := "Convert Current Scene to PSX..."
const CONVERT_CURRENT_SCENE_KEY := "psx/convert_current_scene"
const CONVERT_SELECTED_NODE_NAME := "Convert Selected Node(s) to PSX..."
const CONVERT_SELECTED_NODE_KEY := "psx/convert_selected_node"
const CONVERT_ENTIRE_PROJECT_NAME := "Convert Entire Project to PSX..."
const CONVERT_ENTIRE_PROJECT_KEY := "psx/convert_entire_project"
const PURGE_SHADERS_NAME := "Purge Unused Shaders"
const PURGE_SHADERS_KEY := "psx/purge_unused_shaders"
const REBUILD_SHADERS_NAME := "Rebuild Unused Shaders"
const REBUILD_SHADERS_KEY := "psx/rebuild_unused_shaders"


static var MAT_DEFAULT: PsxMaterial3D:
	get: return load("res://addons/psx/materials/psx_mat_default.tres")
static var MAT_PLACEHOLDER: PsxMaterial3D:
	get: return load("res://addons/psx/materials/psx_mat_placeholder.tres")


static func get_path_file_name(path: String) -> String:
	return path.right(path.rfind("/")).left(path.rfind("."))


static func append_suffix_to_path(path: String, suffix: String = "_psx") -> String:
	return path.left(path.rfind(".")) + suffix + "." + path.get_extension()


static func get_resources(paths: Array, type: String, result: Array = []) -> Array:
	var valid_exts: PackedStringArray = ResourceLoader.get_recognized_extensions_for_type(type)
	for path: String in paths:
		if DirAccess.dir_exists_absolute(path):
			var sub_paths := PackedStringArray()
			for sub_path in DirAccess.get_files_at(path):
				sub_paths.push_back(path.path_join(sub_path))

			for sub_path in DirAccess.get_directories_at(path):
				sub_paths.push_back(path.path_join(sub_path))

			get_resources(sub_paths, type, result)

		elif path.get_extension() in valid_exts:
			var resource := ResourceLoader.load(path)
			if not resource.is_class(type): continue
			if resource in result: continue

			result.push_back(resource)

	return result


var file_system_context_menu_plugin: PsxFileSystemContextMenuPlugin
var scene_tree_context_menu_plugin: PsxSceneTreeContextMenuPlugin
var inspector_plugin: PsxInspectorPlugin
var post_process_node: Node


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _enter_tree() -> void:
	touch_shader_globals()

	var command_palette := get_editor_interface().get_command_palette()
	command_palette.add_command(CONVERT_CURRENT_SCENE_NAME, CONVERT_CURRENT_SCENE_KEY, convert_current_scene)
	command_palette.add_command(CONVERT_SELECTED_NODE_NAME, CONVERT_SELECTED_NODE_KEY, convert_selected_nodes)
	command_palette.add_command(CONVERT_ENTIRE_PROJECT_NAME, CONVERT_ENTIRE_PROJECT_KEY, convert_entire_project)
	command_palette.add_command(PURGE_SHADERS_NAME, PURGE_SHADERS_KEY, PsxMaterial3D.purge_unused_shaders)
	command_palette.add_command(REBUILD_SHADERS_NAME, REBUILD_SHADERS_KEY, PsxMaterial3D.rebuild_shaders)

	if file_system_context_menu_plugin == null:
		file_system_context_menu_plugin = PsxFileSystemContextMenuPlugin.new(self )
		add_context_menu_plugin(EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_FILESYSTEM, file_system_context_menu_plugin)

	if scene_tree_context_menu_plugin == null:
		scene_tree_context_menu_plugin = PsxSceneTreeContextMenuPlugin.new(self )
		add_context_menu_plugin(EditorContextMenuPlugin.ContextMenuSlot.CONTEXT_SLOT_SCENE_TREE, scene_tree_context_menu_plugin)

	if inspector_plugin == null:
		inspector_plugin = PsxInspectorPlugin.new()
		add_inspector_plugin(inspector_plugin)

	if post_process_node == null:
		post_process_node = CanvasLayer.new()
		post_process_node.set_script(preload(AUTOLOAD_PATH))
		get_editor_interface().get_editor_viewport_3d().add_child(post_process_node)


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _exit_tree() -> void:
	var command_palette := get_editor_interface().get_command_palette()
	command_palette.remove_command(CONVERT_CURRENT_SCENE_KEY)
	command_palette.remove_command(CONVERT_SELECTED_NODE_KEY)
	command_palette.remove_command(CONVERT_ENTIRE_PROJECT_KEY)
	command_palette.remove_command(PURGE_SHADERS_KEY)
	command_palette.remove_command(REBUILD_SHADERS_KEY)

	if file_system_context_menu_plugin != null:
		remove_context_menu_plugin(file_system_context_menu_plugin)
		file_system_context_menu_plugin = null

	if scene_tree_context_menu_plugin != null:
		remove_context_menu_plugin(scene_tree_context_menu_plugin)
		scene_tree_context_menu_plugin = null

	if inspector_plugin != null:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null

	if post_process_node != null:
		post_process_node.queue_free()


signal options_retrieved(response: bool)
func prompt_options_dialog():
	PsxConversionDialog.prompt(get_editor_interface().get_editor_main_screen())

	if not PsxConversionDialog.inst.confirmed.is_connected(options_retrieved.emit):
		PsxConversionDialog.inst.confirmed.connect(options_retrieved.emit.bind(true))
		PsxConversionDialog.inst.canceled.connect(options_retrieved.emit.bind(false))

	return await options_retrieved

func convert_entire_project() -> void:
	convert_resource_paths_context(["res://"])


func convert_current_scene() -> void:
	convert_selected_nodes_context([get_editor_interface().get_edited_scene_root()])
	get_editor_interface().mark_scene_as_unsaved()


func convert_selected_nodes() -> void:
	convert_selected_nodes_context(get_editor_interface().get_selection().get_top_selected_nodes(), get_editor_interface().get_edited_scene_root())
	get_editor_interface().mark_scene_as_unsaved()


func convert_selected_nodes_context(nodes: Array, root: Node = nodes[0]) -> void:
	if not await prompt_options_dialog(): return
	var options := PsxConversionDialog.get_options()

	if nodes.is_empty():
		printerr("No nodes selected!")
		return

	for node in nodes:
		_convert_node_recursive(node, options, root)


func convert_resource_paths_context(paths: Array) -> void:
	if not await prompt_options_dialog(): return
	var options := PsxConversionDialog.get_options()

	var resources: Array
	if options[&"include_all_properties"]:
		resources = get_resources(paths, "Resource")
	else:
		if options[&"convert_shader_materials"]:
			resources.append_array(get_resources(paths, "ShaderMaterial"))
		if options[&"convert_base_material_3ds"]:
			resources.append_array(get_resources(paths, "BaseMaterial3D"))
		if options[&"include_scenes"]:
			resources.append_array(get_resources(paths, "PackedScene"))

	for res in resources.duplicate():
		if res is PsxMaterial3D: resources.erase(res)

	if resources.is_empty():
		printerr("No convertible paths were selected in the FileSystem.")
		return

	for res in resources:
		if res is PackedScene:
			_convert_packed_scene(res, options)
		elif res is Material:
			_convert_material(res, options)
		else:
			assert(false, "Unconvertible resource '%s' found." % res)


func _convert_packed_scene(scene: PackedScene, options: Dictionary) -> PackedScene:
	var root := scene.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)
	if root == null:
		printerr("Error opening scene for conversion: '%s' " % scene.resource_path)
		return null

	_convert_node_recursive(root, options, root)

	var new_scene := PackedScene.new()
	var err := new_scene.pack(root)
	root.queue_free()

	if err:
		printerr("Error packing scene '%s' after conversion: %s" % [scene.resource_path, error_string(err)])
		return null

	new_scene.take_over_path(scene.resource_path)
	ResourceSaver.save(new_scene)

	return new_scene


func _convert_node_recursive(node: Node, options: Dictionary, root: Node = node) -> void:
	var meta_ignore: int = node.get_meta(PsxInspectorPlugin.META_IGNORE, 0)
	match meta_ignore:
		2: return
		0: _convert_single_node(node, options)

	for child in node.get_children():
		if child.owner != root: continue

		_convert_node_recursive(child, options, root)


func _convert_single_node(node: Node, options: Dictionary) -> void:
	if node is MeshInstance3D:
		for idx in node.get_surface_override_material_count():
			var mat_prev: Material = node.get_surface_override_material(idx)
			var mat_prev_from_override := true

			if mat_prev == null:
				mat_prev = node.mesh.surface_get_material(idx)
				mat_prev_from_override = false

			if mat_prev is PsxMaterial3D: continue

			var mat_new: PsxMaterial3D
			if mat_prev == null:
				match options[&"node_replace_null_with"]:
					0: continue
					1: mat_new = MAT_PLACEHOLDER
					2: mat_new = MAT_DEFAULT
			else:
				mat_new = _convert_material(mat_prev, options)

			if mat_new == null or mat_new == mat_prev: continue

			if options[&"resource_deep"] and not mat_prev_from_override:
				node.mesh.surface_set_material(idx, mat_new)
			else:
				node.set_surface_override_material(idx, mat_new)

	if node is GeometryInstance3D:
		if options[&"node_convert_override"]:
			var mat_prev: Material = node.material_override
			if mat_prev != null and mat_prev is not PsxMaterial3D:
				var mat_new: PsxMaterial3D = _convert_material(mat_prev, options)
				if mat_new is PsxMaterial3D:
					node.material_override = mat_new

		if options[&"node_convert_overlay"]:
			var mat_prev: Material = node.material_overlay
			if mat_prev != null and mat_prev is not PsxMaterial3D:
				var mat_new := _convert_material(mat_prev, options)
				if mat_new:
					node.material_overlay = mat_new

	if options[&"include_all_properties"]:
		_convert_object_plist(node, options)


func _convert_object_plist(obj: Object, options: Dictionary) -> void:
	print("obj : %s" % [obj])
	for prop in obj.get_property_list():
		if prop[&"type"] != TYPE_OBJECT: continue
		if not prop[&"usage"] & PROPERTY_USAGE_STORAGE: continue

		print("prop : %s" % [prop])

		var mat_prev = obj.get(prop[&"name"])
		if mat_prev is not Material: continue

		var mat_new := _convert_material(mat_prev, options)
		if mat_new == null: continue

		obj.set(prop[&"name"], mat_new)


func _convert_material(material: Material, options: Dictionary) -> PsxMaterial3D:
	var is_material_saved := not material.resource_path.is_empty()
	var new_path: String

	if is_material_saved:
		new_path = material.resource_path if options[&"resource_overwrite"] else append_suffix_to_path(material.resource_path)
		if material.resource_path != new_path and ResourceLoader.exists(new_path):
			return load(new_path)
	else:
		##TODO: get from ledger if no path.
		pass

	var result := _create_psx_material_from(material, options)
	if result == null or result == material:
		return null

	if is_material_saved:
		result.take_over_path(new_path)
		ResourceSaver.save(result)
	else:
		##TODO: store in ledger.
		pass

	return result


func _create_psx_material_from(material: Material, options: Dictionary) -> PsxMaterial3D:
	if material is PsxMaterial3D:
		printerr("This Material is already a PsxMaterial3D.")
		return null

	var result: PsxMaterial3D = null

	if material is BaseMaterial3D:
		result = PsxMaterial3D.new()

		match material.transparency:
			BaseMaterial3D.TRANSPARENCY_DISABLED:
				result.transparency_mode = 0
			BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
				result.transparency_mode = 1
			_:
				result.transparency_mode = 2

		result.shading_mode = (
			BaseMaterial3D.SHADING_MODE_PER_VERTEX
			if options[&"material_force_vertex_lighting"] and material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
			else material.shading_mode
		)

		result.fog_mode = (
			BaseMaterial3D.SHADING_MODE_PER_VERTEX
			if options[&"material_force_vertex_fog"] and not material.disable_fog
			else int(not material.disable_fog)
		)

		for param in PsxMaterial3D.TRANSFERABLE_PARAMS:
			result.set(param, material.get(param))

	if material is ShaderMaterial and material.shader.get_mode() == Shader.MODE_SPATIAL:
		result = PsxMaterial3D.new()

		var transferable_params: Dictionary[String, String]
		for uniform in material.shader.get_shader_uniform_list():
			for param in PsxMaterial3D.TRANSFERABLE_PARAMS:
				if not uniform[&"name"].ends_with(param): continue
				transferable_params[uniform[&"name"]] = param
				break

		for k in transferable_params.keys():
			var param_value = material.get_shader_parameter(k)
			if param_value == null: continue

			var start_value = result.get(transferable_params[k])
			if start_value != null and typeof(start_value) != typeof(param_value): continue

			result.set(transferable_params[k], param_value)

	if result:
		result.render_priority = material.render_priority
		if material.next_pass:
			result.next_pass = _create_psx_material_from(material.next_pass, options)

	return result
