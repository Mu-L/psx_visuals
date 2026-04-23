@tool class_name PsxConversionDialog extends ConfirmationDialog

static var inst: PsxConversionDialog


static func prompt(parent: Node) -> void:
	if inst == null:
		inst = load("res://addons/psx/scenes/PsxConversionDialog.tscn").instantiate()
		parent.add_child(inst)

	inst.popup_centered()


static func get_options() -> Dictionary:
	return inst._get_options()


func _get_options() -> Dictionary:
	var result := {}
	for child in %list.get_children():
		if child is not PsxConversionDialogOption: continue
		result[child.name] = child.get_option_value()

	print("result: ", result)

	return result
