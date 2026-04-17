@tool class_name PsxShader extends Shader

var materials: Array[Material] = []

@export_storage var table_index: int = -1

func _init(__table_index__: int = -1) -> void:
	table_index = __table_index__


func _refresh() -> void:
	if table_index == -1 or not Engine.is_editor_hint(): return

	if materials.is_empty():
		DirAccess.remove_absolute(resource_path)
		take_over_path("")
	else:
		take_over_path(PsxMaterial3D.SHADER_PATH_TEMPLATE % table_index)
		ResourceSaver.save(self )
		PsxMaterial3D.SHADER_TABLE[table_index] = self
