@tool class_name PsxPlugin extends EditorPlugin

class PsxFileSystemContextMenuPlugin extends EditorContextMenuPlugin:
	var plugin: PsxPlugin


	func _init(__plugin__: PsxPlugin) -> void:
		plugin = __plugin__


	func _popup_menu(paths: PackedStringArray) -> void:
		add_context_menu_item("Convert Scene(s) to PSX...", plugin.convert_scene_paths_context)
		add_context_menu_item("Convert Material(s) to PSX...", plugin.convert_material_paths_context)


class PsxSceneTreeContextMenuPlugin extends EditorContextMenuPlugin:
	var plugin: PsxPlugin


	func _init(__plugin__: PsxPlugin) -> void:
		plugin = __plugin__


	func _popup_menu(paths: PackedStringArray) -> void:
		add_context_menu_item("Convert Node(s) to PSX...", plugin.convert_selected_nodes_context)


const AUTOLOAD_NAME := "psx_autoload"
const AUTOLOAD_PATH := "scripts/PsxAutoload.gd"
const CONVERT_CURRENT_SCENE_NAME := "Convert Current Scene to PSX..."
const CONVERT_CURRENT_SCENE_KEY := "psx/convert_current_scene"
const CONVERT_SELECTED_NODE_NAME := "Convert Selected Node(s) to PSX..."
const CONVERT_SELECTED_NODE_KEY := "psx/convert_selected_node"
const CONVERT_ENTIRE_PROJECT_NAME := "Convert Entire Project to PSX..."
const CONVERT_ENTIRE_PROJECT_KEY := "psx/convert_entire_project"
const PRECOMPILE_SHADERS_NAME := "Precompile PSX Shaders"
const PRECOMPILE_SHADERS_KEY := "psx/precompile_shaders"


var file_system_context_menu_plugin: PsxFileSystemContextMenuPlugin
var scene_tree_context_menu_plugin: PsxSceneTreeContextMenuPlugin
var inspector_plugin: PsxInspectorPlugin
var post_process_node: Node

const CONVERSION_OPTIONS_DEFAULT := {
	&"exclude_addons": false,
	&"material_take_over_path": true,
	&"material_force_vertex_lighting": true,
}

func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	Psx.touch_shader_globals()
	PsxMaterial3D._precompile_shaders()


func _enter_tree() -> void:
	var command_palette := get_editor_interface().get_command_palette()
	command_palette.add_command(CONVERT_CURRENT_SCENE_NAME, CONVERT_CURRENT_SCENE_KEY, convert_current_scene)
	command_palette.add_command(CONVERT_SELECTED_NODE_NAME, CONVERT_SELECTED_NODE_KEY, convert_selected_nodes)
	command_palette.add_command(CONVERT_ENTIRE_PROJECT_NAME, CONVERT_ENTIRE_PROJECT_KEY, convert_entire_project)
	command_palette.add_command(PRECOMPILE_SHADERS_NAME, PRECOMPILE_SHADERS_KEY, PsxMaterial3D._precompile_shaders)

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
		post_process_node.set_script(preload("res://addons/psx_visuals/scripts/PsxAutoload.gd"))
		get_editor_interface().get_editor_viewport_3d().add_child(post_process_node)
		get_editor_interface().get_editor_viewport_3d().print_tree_pretty()

func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _exit_tree() -> void:
	var command_palette := get_editor_interface().get_command_palette()
	command_palette.remove_command(CONVERT_CURRENT_SCENE_KEY)
	command_palette.remove_command(CONVERT_SELECTED_NODE_KEY)
	command_palette.remove_command(CONVERT_ENTIRE_PROJECT_KEY)
	command_palette.remove_command(PRECOMPILE_SHADERS_KEY)

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


func convert_entire_project() -> void:
	convert_scene_paths_context(["res://"], CONVERSION_OPTIONS_DEFAULT)


func convert_current_scene() -> void:
	convert_node_recursive(get_editor_interface().get_edited_scene_root(), CONVERSION_OPTIONS_DEFAULT)


func convert_selected_nodes() -> void:
	convert_selected_nodes_context(get_editor_interface().get_selection().get_top_selected_nodes())


func convert_selected_nodes_context(nodes: Array, options := CONVERSION_OPTIONS_DEFAULT) -> void:
	if nodes.is_empty():
		printerr("No nodes selected!")
		return

	for node in nodes:
		convert_node_recursive(node, options)


func convert_scenes_in_file_system() -> void:
	convert_scene_paths_context(get_editor_interface().get_selected_paths(), CONVERSION_OPTIONS_DEFAULT)


func convert_scene_paths_context(paths: Array, options := CONVERSION_OPTIONS_DEFAULT) -> void:
	var scenes := get_resources(paths, "PackedScene")
	if scenes.is_empty():
		printerr("No scene paths were selected in the FileSystem.")
		return

	for scene: PackedScene in scenes:
		convert_scene(scene, options, false)

	MATERIAL_LEDGER.clear()


func convert_scene(scene: PackedScene, options: Dictionary, clear_ledger := false) -> PackedScene:
	var root := scene.instantiate(PackedScene.GenEditState.GEN_EDIT_STATE_INSTANCE)
	if root == null:
		printerr("Error opening scene for conversion: '%s' " % scene.resource_path)
		return null

	convert_node_recursive(root, options, clear_ledger)

	var new_scene := PackedScene.new()
	var err := new_scene.pack(root)
	root.queue_free()

	if err:
		printerr("Error packing scene '%s' after conversion: %s" % [scene.resource_path, error_string(err)])
		return null

	new_scene.take_over_path(scene.resource_path)
	ResourceSaver.save(new_scene)

	return new_scene


func convert_selected_materials_in_file_system() -> void:
	convert_material_paths_context(get_editor_interface().get_selected_paths())


func convert_material_paths_context(paths: Array, options := CONVERSION_OPTIONS_DEFAULT) -> void:
	var materials := get_resources(paths, "Material")
	if materials.is_empty():
		printerr("No material paths were selected in the FileSystem.")
		return

	for material: Material in materials:
		convert_material(material, options)

	MATERIAL_LEDGER.clear()


static var MATERIAL_LEDGER: Dictionary[Material, PsxMaterial3D] = {}

func convert_material(material: Material, options := CONVERSION_OPTIONS_DEFAULT) -> Material:
	var is_material_saved := not material.resource_path.is_empty()
	var new_path: String

	if is_material_saved:
		if options[&"exclude_addons"] and material.resource_path.begins_with("res://addons/"):
			new_path = "res://" + material.resource_path.right(material.resource_path.rfind("/"))

		elif options[&"material_take_over_path"]:
			new_path = material.resource_path

		else:
			new_path = append_suffix_to_path(material.resource_path)

	if is_material_saved:
		if material.resource_path != new_path and ResourceLoader.exists(new_path):
			return load(new_path)
	else:
		if MATERIAL_LEDGER.has(material):
			return MATERIAL_LEDGER[material]

	var result := create_psx_material_from(material)
	if result == null:
		return null

	if is_material_saved:
		result.take_over_path(new_path)
		ResourceSaver.save(result)
	else:
		MATERIAL_LEDGER[material] = result

	return result


func convert_node_recursive(node: Node, options: Dictionary, clear_ledger := false) -> void:
	_convert_node_recursive(node, node, options, clear_ledger)
func _convert_node_recursive(node: Node, root: Node, options: Dictionary, clear_ledger := false) -> void:
	var meta_ignore: int = node.get_meta(PsxInspectorPlugin.META_IGNORE, 0)
	if meta_ignore == 2: return

	if meta_ignore != 1 and node is MeshInstance3D:
		_convert_node(node, options)

	for child in node.get_children():
		if child.owner != root: continue

		_convert_node_recursive(child, root, options)

	if clear_ledger:
		MATERIAL_LEDGER.clear()


func _convert_node(node: MeshInstance3D, options: Dictionary, clear_ledger := false) -> void:
	var affected_surfaces: Dictionary[int, Material]
	for idx in node.get_surface_override_material_count():
		var current_mat := node.get_surface_override_material(idx)
		if current_mat is PsxMaterial3D: continue
		if current_mat == null:
			current_mat = node.mesh.surface_get_material(idx)
			if current_mat == null or current_mat is PsxMaterial3D: continue

		var new_mat := convert_material(current_mat, options)
		if new_mat == null: continue

		node.set_surface_override_material(idx, new_mat)

	if clear_ledger:
		MATERIAL_LEDGER.clear()


func create_psx_material_from(material: Material, options := CONVERSION_OPTIONS_DEFAULT) -> PsxMaterial3D:
	if material is PsxMaterial3D:
		printerr("This Material is already a PsxMaterial3D.")
		return null

	if material is BaseMaterial3D:
		var result := PsxMaterial3D.new()

		match material.transparency:
			BaseMaterial3D.TRANSPARENCY_ALPHA, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
				result.transparency_mode = 1
			_:
				result.transparency_mode = 0

		if options[&"material_force_vertex_lighting"] and material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL:
			result.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		else:
			result.shading_mode = material.shading_mode

		for param in PsxMaterial3D.PSX_MATERIAL_TRANSFERABLE_PARAMS:
			result.set(param, material.get(param))

		return result

	if material is ShaderMaterial:
		var result := PsxMaterial3D.new()

		for param in PsxMaterial3D.PSX_MATERIAL_TRANSFERABLE_PARAMS:
			var param_value = material.get_shader_parameter(param)
			if param_value == null: continue
			var start_value = result.get(param)
			if start_value != null and typeof(start_value) != typeof(param_value):
				printerr("Error transferring material parameters: Type mismatch. Material: '%s' Param: '%s'" % [material, param])
				continue
			result.set(param, param_value)

		return result

	return null


func create_options_dialog() -> ConfirmationDialog:
	return null


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
			print("path : %s" % [path])
			var resource := ResourceLoader.load(path)
			if not resource.is_class(type): continue
			if resource in result: continue

			result.push_back(resource)

	return result
