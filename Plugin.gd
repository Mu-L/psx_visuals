
@tool extends EditorPlugin

const AUTOLOAD_NAME := "psx_autoload"
const AUTOLOAD_PATH := "scripts/PsxAutoload.gd"
const TOOL_MENU_ITEM_NAME := "Convert Scene(s) to PSX..."
const COMMAND_KEY := "PSX"

func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

	Psx.touch_shader_globals()

	add_tool_menu_item(TOOL_MENU_ITEM_NAME, _prompt_scene_convert)
	_enter_tree()


func _enter_tree() -> void:
	get_editor_interface().get_command_palette().add_command(TOOL_MENU_ITEM_NAME, COMMAND_KEY, _prompt_scene_convert)



func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)

	remove_tool_menu_item(TOOL_MENU_ITEM_NAME)
	get_editor_interface().get_command_palette().remove_command(TOOL_MENU_ITEM_NAME)


func _prompt_scene_convert() -> void:
	pass
