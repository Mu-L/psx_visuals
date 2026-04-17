@tool extends CanvasLayer

const POST_PROCESS_LAYER: int = RenderingServer.CANVAS_LAYER_MAX
const POST_PROCESS_MATERIAL: ShaderMaterial = preload("uid://da2sluxj84btb")


func _init() -> void:
	layer = POST_PROCESS_LAYER if not Engine.is_editor_hint() else RenderingServer.CANVAS_LAYER_MIN

	var color_rect := ColorRect.new()
	color_rect.material = POST_PROCESS_MATERIAL
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.focus_mode = Control.FOCUS_NONE
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	add_child(color_rect)
