@tool class_name PsxConversionDialog extends ConfirmationDialog

enum {
	CONVERT_NONE,
	CONVERT_OVERWRITE,
	CONVERT_CREATE_NEW,
}

const CACHE_PATH := "res://addons/psx/convert_cache.cfg"
const CACHE_SECTION := "cache"
const CACHE_KEY := "cache"
const PSX_SUFFIX := "_psx"
const NATIVE_EXTENSIONS: PackedStringArray = [
	"tscn",
	"scn",
	"res",
]


static var MAT_DEFAULT: PsxMaterial3D:
	get: return load("res://addons/psx/materials/psx_mat_default.tres")
static var MAT_PLACEHOLDER: PsxMaterial3D:
	get: return load("res://addons/psx/materials/psx_mat_placeholder.tres")


static func path_is_psx(path: String) -> bool:
	return path.left(-path.get_extension().length() - 1).right(PSX_SUFFIX.length()).to_lower() == PSX_SUFFIX


static func resource_is_native(scene: Resource) -> bool:
	return scene.resource_path.get_extension() in NATIVE_EXTENSIONS


static func modify_resource_import_data(resource: Resource, data: Dictionary = {}, template: Resource = resource) -> void:
	assert(ResourceLoader.exists(template.resource_path), "Can't modify import data without a file to edit.")

	var import_file := ConfigFile.new()
	import_file.load(template.resource_path + ".import")

	for section in data:
		for key in data[section]:
			import_file.set_value(section, key, data[section][key])

	import_file.save(resource.resource_path + ".import")


signal closed(response: bool)


var options: Dictionary
var cache_file: ConfigFile
var cache: Dictionary


func _init() -> void:
	confirmed.connect(closed.emit.bind(true))
	canceled.connect(closed.emit.bind(false))


func _enter_tree() -> void:
	hide()
	cache_file = ConfigFile.new()
	load_cache()


func _exit_tree() -> void:
	save_cache()


func load_cache() -> void:
	if cache_file.load(CACHE_PATH) != OK: return

	cache.clear()
	for key in cache_file.get_section_keys(CACHE_SECTION):
		var key_resource := ResourceLoader.load(key, "", ResourceLoader.CACHE_MODE_REUSE)
		cache[key_resource] = ResourceLoader.load(cache_file.get_value(CACHE_SECTION, key), "", ResourceLoader.CACHE_MODE_REUSE)


func save_cache() -> void:
	cache_file.clear()
	for key: Resource in cache:
		cache_file.set_value(CACHE_SECTION, key.resource_path, cache[key].resource_path)

	cache_file.save(CACHE_PATH)


func prompt() -> bool:
	popup_centered()
	var result: bool = await closed

	for child in %list.get_children():
		if child is not PsxConversionDialogOption: continue
		options[child.name] = child.get_option_value()

	return result


func get_convert_response(resource: Resource) -> int:
	if resource is PackedScene:
		return options.get(&"convert_native_scenes" if resource_is_native(resource) else &"convert_", CONVERT_NONE)

	if resource is Mesh:
		return options.get(&"convert_meshes", CONVERT_NONE)

	if resource is BaseMaterial3D:
		return options.get(&"convert_base_material_3ds", CONVERT_NONE)

	if resource is PsxMaterial3D:
		return CONVERT_NONE

	if resource is ShaderMaterial and resource.shader.get_mode() == Shader.MODE_SPATIAL:
		return options.get(&"convert_shader_materials", CONVERT_NONE)

	return CONVERT_NONE


func convert_nodes(nodes: Array[Node]) -> void:
	for node in nodes:
		convert_node(node)


func convert_resource_paths(paths: PackedStringArray) -> void:
	for path in paths:
		if DirAccess.dir_exists_absolute(path):
			convert_resource_paths(DirAccess.get_directories_at(path))
			convert_resource_paths(DirAccess.get_files_at(path))
		elif ResourceLoader.exists(path):
			convert_resource(ResourceLoader.load(path))
		else:
			printerr("The path '%s' is neither a valid resource file nor a folder.")
			continue


func convert_resource(resource: Resource) -> Variant:
	var response := get_convert_response(resource)
	match response:
		CONVERT_NONE: return resource

	if cache.has(resource):
		return cache[resource]

	var resource_is_saved := ResourceLoader.exists(resource.resource_path)
	var new_path: String

	if resource_is_saved:
		if path_is_psx(resource.resource_path):
			return resource

		new_path = resource.resource_path if response == CONVERT_OVERWRITE else resource.resource_path.insert(-resource.resource_path.get_extension().length() - 1, PSX_SUFFIX)

		if resource.resource_path != new_path and ResourceLoader.exists(new_path):
			assert(path_is_psx(new_path))
			cache[resource] = ResourceLoader.load(new_path)
			return cache[resource]

	var result: Variant = null

	if resource is PackedScene:
		result = convert_scene_from(resource)

	elif resource is Mesh:
		result = convert_mesh_from(resource)

	elif resource is Material:
		result = convert_material_from(resource)

	if result == null:
		return null

	if options.get(&"convert_object_properties", true):
		convert_object_plist(result)

	if resource_is_saved:
		result.take_over_path(new_path)
		ResourceSaver.save(result)
		cache[resource] = ResourceLoader.load(new_path)
	else:
		cache[resource] = result

	return cache[resource]


func convert_scene_from(scene: PackedScene) -> PackedScene:
	var root := scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var result := PackedScene.new()

	if resource_is_native(scene):
		convert_tree(root)

		var err := result.pack(root)

	else:
		var materials := get_materials_used_in_tree(root)
		var data: Dictionary
		for k in materials:
			var converted_material := convert_resource(materials[k])
			data[k] = {
				"use_external/enabled": true,
				"use_external/fallback_path": converted_material.resource_path,
				"use_external/path": ResourceUID.path_to_uid(converted_material.resource_path)
			}

		modify_resource_import_data(result, {
			"params": {
				"_subresources": {
					"materials": data
				}
			}
		}, scene)

	root.queue_free()

	return result


func convert_tree(node: Node, root: Node = node) -> void:
	var meta_ignore: int = node.get_meta(Psx.PsxInspectorPlugin.META_IGNORE, 0)
	match meta_ignore:
		2: return
		0: convert_node(node)

	for child in node.get_children():
		if child.owner != root: continue
		convert_tree(child, root)


func convert_node(node: Node) -> void:
	if node is MeshInstance3D:
		if options.get(&"deep", false):
			node.mesh = convert_resource(node.mesh)

		for idx in node.get_surface_override_material_count():
			node.set_surface_override_material(idx, convert_resource(node.get_surface_override_material(idx)))

	elif node is GPUParticles3D:
		for idx in GPUParticles3D.MAX_DRAW_PASSES:
			var prop_name: StringName = &"draw_pass_" + str(idx + 1)
			node.set(prop_name, convert_resource(node.get(prop_name)))

	if node is GeometryInstance3D:
		node.material_override = convert_resource(node.material_override)
		node.material_overlay = convert_resource(node.material_overlay)

	if options.get(&"all_properties", false):
		convert_object_plist(node)


func convert_object_plist(obj: Object) -> void:
	for prop in obj.get_property_list():
		if (
				prop[&"type"] != TYPE_OBJECT or
			not prop[&"usage"] & PROPERTY_USAGE_STORAGE or
			not ClassDB.is_parent_class(prop[&"class_name"], "Resource")
		): continue

		var old = obj.get(prop[&"name"])
		var new := convert_resource(old)

		if new == null or new == old: continue

		obj.set(prop[&"name"], new)


func get_materials_used_in_tree(node: Node, root: Node = node) -> Dictionary:
	var result: Dictionary
	for child in node.get_children():
		if child.owner == root and node is MeshInstance3D:
			for i in node.mesh.get_surface_count():
				print("node.mesh['surface_0/name'] : %s" % [node.mesh['surface_0/name']])

				result[node.mesh["surface_%s/name" % str(i)]] = node.mesh.surface_get_material(i)

		result.merge(get_materials_used_in_tree(child, root))

	return result


func convert_mesh_from(mesh: Mesh) -> Mesh:
	if mesh == null: return null
	var result: Mesh = mesh.duplicate()

	for idx in mesh.get_surface_count():
		result.surface_set_material(idx, convert_resource(mesh.surface_get_material(idx)))

	return result


func convert_material_from(material: Material) -> PsxMaterial3D:
	if material == null:
		match options.get(&"material_null_fallback", 0):
			0: return null
			1: return MAT_PLACEHOLDER
			2: return MAT_DEFAULT

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
			if options.get(&"material_force_vertex_lighting", true) and material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
			else material.shading_mode
		)

		result.fog_mode = (
			BaseMaterial3D.SHADING_MODE_PER_VERTEX
			if options.get(&"material_force_vertex_fog", true) and not material.disable_fog
			else int(not material.disable_fog)
		)

		match options.get(&"material_force_vertex_colors", 0):
			0: result.vertex_color_use_as_albedo = material.vertex_color_use_as_albedo
			1: result.vertex_color_use_as_albedo = false
			2: result.vertex_color_use_as_albedo = true

		for param in PsxMaterial3D.TRANSFERABLE_PARAMS:
			result.set(param, material.get(param))

	elif material is ShaderMaterial \
		and material.shader.get_mode() == Shader.MODE_SPATIAL:
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

	else:
		return material

	if result:
		result.render_priority = material.render_priority
		if material.next_pass:
			result.next_pass = convert_resource(material.next_pass)

	return result


# func convert_entire_project() -> void:
# 	convert_resource_paths_context(["res://"])
# func convert_current_scene() -> void:
# 	convert_selected_nodes_context([get_editor_interface().get_edited_scene_root()])
# 	get_editor_interface().mark_scene_as_unsaved()
# func convert_selected_nodes() -> void:
# 	convert_selected_nodes_context(get_editor_interface().get_selection().get_top_selected_nodes())
# 	get_editor_interface().mark_scene_as_unsaved()
# func convert_selected_nodes_context(nodes: Array, root: Node = get_editor_interface().get_edited_scene_root()) -> void:
# 	if not await prompt_options_dialog(): return
# 	var options := PsxConversionDialog.get_options()
# 	if nodes.is_empty():
# 		printerr("No nodes selected!")
# 		return
# 	for node in nodes:
# 		_convert_node_recursive(node, options, root)
# func convert_resource_paths_context(paths: Array) -> void:
# 	if not await prompt_options_dialog(): return
# 	var options := PsxConversionDialog.get_options()
# 	var resources: Array
# 	if options[&"convert_object_properties"]:
# 		resources = get_resources(paths, "Resource")
# 	else:
# 		if options[&"convert_shader_materials"]:
# 			resources.append_array(get_resources(paths, "ShaderMaterial"))
# 		if options[&"convert_base_material_3ds"]:
# 			resources.append_array(get_resources(paths, "BaseMaterial3D"))
# 		if options[&"include_scenes"]:
# 			resources.append_array(get_resources(paths, "PackedScene"))
# 	for res in resources.duplicate():
# 		if res is PsxMaterial3D: resources.erase(res)
# 	if resources.is_empty():
# 		printerr("No convertible paths were selected in the FileSystem.")
# 		return
# 	for res in resources:
# 		if res is PackedScene:
# 			_convert_imported_scene(res, options)
# 		elif res is Material:
# 			_convert_material(res, options)
# 		else:
# 			assert(false, "Unconvertible resource '%s' found." % res)
# func _convert_packed_scene(scene: PackedScene, options: Dictionary) -> PackedScene:
# 	var root := scene.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)
# 	if root == null:
# 		printerr("Error opening scene for conversion: '%s' " % scene.resource_path)
# 		return null
# 	_convert_node_recursive(root, options, root)
# 	var new_scene := PackedScene.new()
# 	var err := new_scene.pack(root)
# 	root.queue_free()
# 	if err:
# 		printerr("Error packing scene '%s' after conversion: %s" % [scene.resource_path, error_string(err)])
# 		return null
# 	new_scene.take_over_path(scene.resource_path)
# 	ResourceSaver.save(new_scene)
# 	return new_scene
# func _convert_imported_scene(scene: PackedScene, options: Dictionary) -> void:
# 	var root := scene.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)
# 	if root == null:
# 		printerr("Error opening scene for conversion: '%s' " % scene.resource_path)
# 		return
# 	var materials := get_materials_used_in_node(root)
# 	root.queue_free()
# 	var external_materials: Dictionary
# 	for k in materials.keys():
# 		external_materials[k] = create_external_material_injection(preload("res://test/Assets/gltf/tiny_treats.tres"))
# 	var data: Dictionary = {
# 		"_subresources": {
# 			"materials": external_materials
# 		}
# 	}
# 	_modify_import_data(scene, data)
# func get_materials_used_in_node(node: Node, root: Node = node) -> Dictionary:
# 	var result: Dictionary
# 	for child in node.get_children():
# 		if child.owner == root and node is MeshInstance3D:
# 			for i in node.mesh.get_surface_count():
# 				print("node.mesh['surface_0/name'] : %s" % [node.mesh['surface_0/name']])
# 				result[node.mesh["surface_%s/name" % str(i)]] = node.mesh.surface_get_material(i)
# 		result.merge(get_materials_used_in_node(child, root))
# 	print("result : %s" % [result])
# 	return result
# func create_external_material_injection(material: Material) -> Dictionary:
# 	return {
# 		"use_external/enabled": true,
# 		"use_external/fallback_path": material.resource_path,
# 		"use_external/path": ResourceUID.path_to_uid(material.resource_path)
# 	}
# func _modify_import_data(resource: Resource, data: Dictionary = {}) -> void:
# 	if resource.resource_path.is_empty():
# 		printerr("Can't modify import data without a file to edit.")
# 		return
# 	var import_path := resource.resource_path + ".import"
# 	var import_file := ConfigFile.new()
# 	import_file.load(import_path)
# 	for k in data.keys():
# 		import_file.set_value("params", k, data[k])
# 	import_file.save(import_path)
# func _convert_node_recursive(node: Node, options: Dictionary, root: Node = node) -> void:
# 	var meta_ignore: int = node.get_meta(PsxInspectorPlugin.META_IGNORE, 0)
# 	match meta_ignore:
# 		2: return
# 		0: _convert_single_node(node, options)
# 	for child in node.get_children():
# 		if child.owner != root: continue
# 		_convert_node_recursive(child, options, root)
# func _convert_single_node(node: Node, options: Dictionary) -> void:
# 	print("node : %s" % [node])
# 	if options[&"deep"]:
# 		if node is MeshInstance3D:
# 			_convert_mesh(node.mesh, options)
# 		if node is CPUParticles3D:
# 			_convert_mesh(node.mesh, options)
# 		if node is GPUParticles3D:
# 			for i in node.draw_passes:
# 				_convert_mesh(node.get(&"draw_pass_" + str(i + 1)), options)
# 	elif node is MeshInstance3D and node.mesh != null:
# 		for idx in node.get_surface_override_material_count():
# 			var mat_prev: Material = node.get_surface_override_material(idx)
# 			var mat_prev_from_override := true
# 			if mat_prev == null:
# 				mat_prev = node.mesh.surface_get_material(idx)
# 				mat_prev_from_override = false
# 			if mat_prev is PsxMaterial3D: continue
# 			print("mat_prev : %s" % [mat_prev])
# 			var mat_new := _convert_material(mat_prev, options)
# 			if mat_new == null or mat_new == mat_prev: continue
# 			print("mat_new : %s" % [mat_new])
# 			if options[&"deep"] and not mat_prev_from_override:
# 				node.mesh.surface_set_material(idx, mat_new)
# 			else:
# 				node.set_surface_override_material(idx, mat_new)
# 	elif node is GeometryInstance3D:
# 		if options[&"node_convert_override"]:
# 			var mat_prev: Material = node.material_override
# 			if mat_prev != null and mat_prev is not PsxMaterial3D:
# 				var mat_new: PsxMaterial3D = _convert_material(mat_prev, options)
# 				if mat_new is PsxMaterial3D:
# 					node.material_override = mat_new
# 		if options[&"node_convert_overlay"]:
# 			var mat_prev: Material = node.material_overlay
# 			if mat_prev != null and mat_prev is not PsxMaterial3D:
# 				var mat_new := _convert_material(mat_prev, options)
# 				if mat_new:
# 					node.material_overlay = mat_new
# 	if options[&"convert_object_properties"]:
# 		_convert_object_plist(node, options)
# func _convert_mesh(mesh: Mesh, options: Dictionary) -> void:
# 	if mesh == null: return
# 	for idx in mesh.get_surface_count():
# 		mesh.surface_set_material(idx, _convert_material(mesh.surface_get_material(idx), options))
# 	if ResourceLoader.exists(mesh.resource_path):
# 		ResourceSaver.save(mesh)
# func _convert_object_plist(obj: Object, options: Dictionary) -> void:
# 	for prop in obj.get_property_list():
# 		if prop[&"type"] != TYPE_OBJECT: continue
# 		if not prop[&"usage"] & PROPERTY_USAGE_STORAGE: continue
# 		if not ClassDB.is_parent_class(prop[&"class_name"], "Material"): continue
# 		var prop_value = obj.get(prop[&"name"])
# 		if prop_value is Mesh and options[&"deep"]:
# 			_convert_mesh(prop_value, options)
# 			if ResourceLoader.exists(prop_value.resource_path):
# 				obj.set(prop[&"name"], ResourceLoader.load(prop_value.resource_path))
# 			continue
# 		if prop_value is not Material: continue
# 		var mat_new := _convert_material(prop_value, options)
# 		if mat_new == null: continue
# 		obj.set(prop[&"name"], mat_new)
# func _convert_material(material: Material, options: Dictionary) -> PsxMaterial3D:
# 	var is_material_saved := not material.resource_path.is_empty()
# 	var new_path: String
# 	if is_material_saved:
# 		new_path = material.resource_path if options[&"resource_overwrite"] else append_suffix_to_path(material.resource_path)
# 		if material.resource_path != new_path and ResourceLoader.exists(new_path):
# 			return load(new_path)
# 	else:
# 		##TODO: get from ledger if no path.
# 		pass
# 	var result := _create_psx_material_from(material, options)
# 	if result == null or result == material:
# 		return null
# 	if is_material_saved:
# 		result.take_over_path(new_path)
# 		ResourceSaver.save(result)
# 	else:
# 		##TODO: store in ledger.
# 		pass
# 	return result
# func _create_psx_material_from(material: Material, options: Dictionary) -> PsxMaterial3D:
# 	if material is PsxMaterial3D:
# 		printerr("This Material is already a PsxMaterial3D.")
# 		return null
# 	var result: PsxMaterial3D = null
# 	if material == null:
# 		match options[&"node_replace_null_with"]:
# 			0: return null
# 			1: return MAT_PLACEHOLDER
# 			2: return MAT_DEFAULT
# 	if material is BaseMaterial3D:
# 		result = PsxMaterial3D.new()
# 		match material.transparency:
# 			BaseMaterial3D.TRANSPARENCY_DISABLED:
# 				result.transparency_mode = 0
# 			BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
# 				result.transparency_mode = 1
# 			_:
# 				result.transparency_mode = 2
# 		result.shading_mode = (
# 			BaseMaterial3D.SHADING_MODE_PER_VERTEX
# 			if options[&"material_force_vertex_lighting"] and material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
# 			else material.shading_mode
# 		)
# 		result.fog_mode = (
# 			BaseMaterial3D.SHADING_MODE_PER_VERTEX
# 			if options[&"material_force_vertex_fog"] and not material.disable_fog
# 			else int(not material.disable_fog)
# 		)
# 		for param in PsxMaterial3D.TRANSFERABLE_PARAMS:
# 			result.set(param, material.get(param))
# 	if material is ShaderMaterial and material.shader.get_mode() == Shader.MODE_SPATIAL:
# 		result = PsxMaterial3D.new()
# 		var transferable_params: Dictionary[String, String]
# 		for uniform in material.shader.get_shader_uniform_list():
# 			for param in PsxMaterial3D.TRANSFERABLE_PARAMS:
# 				if not uniform[&"name"].ends_with(param): continue
# 				transferable_params[uniform[&"name"]] = param
# 				break
# 		for k in transferable_params.keys():
# 			var param_value = material.get_shader_parameter(k)
# 			if param_value == null: continue
# 			var start_value = result.get(transferable_params[k])
# 			if start_value != null and typeof(start_value) != typeof(param_value): continue
# 			result.set(transferable_params[k], param_value)
# 	if result:
# 		result.render_priority = material.render_priority
# 		if material.next_pass:
# 			result.next_pass = _create_psx_material_from(material.next_pass, options)
# 	return result
