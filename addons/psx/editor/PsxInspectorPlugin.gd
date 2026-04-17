class_name PsxInspectorPlugin extends EditorInspectorPlugin

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
	ignore_label.tooltip_text = "Adds an editor-only meta value '%s' of type int." % META_IGNORE
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


	var auto_container := HBoxContainer.new()
	auto_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(auto_container)

	var auto_label := Label.new()
	auto_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_label.text = "PSX Auto Apply"
	auto_label.tooltip_text = "Adds an editor-only meta value '%s' of type Material." % META_IGNORE
	auto_container.add_child(auto_label)

	var auto_option := EditorResourcePicker.new()
	auto_option.base_type = "Material"
	auto_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_option.resource_changed.connect(_auto_resource_changed.bind(object))
	if object.has_meta(META_MATERIAL):
		auto_option.edited_resource = object.get_meta(META_MATERIAL)
	auto_container.add_child(auto_option)

	add_custom_control(container)


func _ignore_option_selected(idx: int, node: Node) -> void:
	match idx:
		0: node.set_meta(META_IGNORE, null)
		1: node.set_meta(META_IGNORE, 1)
		2: node.set_meta(META_IGNORE, 2)


func _auto_resource_changed(resource: Material, node: Node) -> void:
	node.set_meta(META_MATERIAL, resource if resource else null)
