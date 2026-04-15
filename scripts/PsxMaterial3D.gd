@tool class_name PsxMaterial3D extends ShaderMaterial

const SHADER_TABLE: Array[Shader] = [
	preload("res://addons/psx_visuals/shaders/psx_t0_c0_d0.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c0_d1.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c0_d2.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c1_d0.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c1_d1.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c1_d2.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c2_d0.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c2_d1.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c2_d2.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c0_d0.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c0_d1.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c0_d2.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c1_d0.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c1_d1.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c1_d2.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c2_d0.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c2_d1.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t0_c2_d2.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t2_c0_d0.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t2_c0_d1.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t2_c0_d2.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t2_c1_d0.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t2_c1_d1.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t2_c1_d2.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t2_c2_d0.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t2_c2_d1.gdshader"),
	preload("res://addons/psx_visuals/shaders/psx_t2_c2_d2.gdshader"),
]

const PSX_MATERIAL_TRANSFERABLE_PARAMS: PackedStringArray = [
	&"cull_mode",
	&"albedo_texture",
	&"albedo_color",
	&"alpha_scissor_threshold",
	&"emission_texture",
	&"emission",
]

@export_enum("Opaque", "Cutout", "Transparent") var transparency_mode: int = 0:
	set(value):
		transparency_mode = value
		_refresh_shader()


@export var cull_mode := BaseMaterial3D.CullMode.CULL_BACK:
	set(value):
		cull_mode = value
		_refresh_shader()


@export_enum("Default", "Inverted", "Disabled") var depth_test: int = 0:
	set(value):
		depth_test = value
		_refresh_shader()

func _refresh_shader() -> void:
	shader = SHADER_TABLE[
		transparency_mode * 9 \
		+ cull_mode * 3 \
		+ depth_test
	]
	set_shader_parameter(&"alpha_scissor_threshold", alpha_scissor_threshold if transparency_mode == 1 else 0.0)


@export var use_vertex_colors_in_albedo: bool = true:
	get: return get_shader_parameter(&"use_vertex_colors_in_albedo")
	set(value): set_shader_parameter(&"use_vertex_colors_in_albedo", value)


@export var use_global_fog: bool = true:
	get: return get_shader_parameter(&"use_global_fog")
	set(value): set_shader_parameter(&"use_global_fog", value)


@export var albedo_texture: Texture2D = null:
	get: return get_shader_parameter(&"albedo_texture")
	set(value): set_shader_parameter(&"albedo_texture", value)


@export var albedo_color: Color = Color.WHITE:
	get: return get_shader_parameter(&"albedo_color")
	set(value): set_shader_parameter(&"albedo_color", value)


@export var emission_texture: Texture2D = null:
	get: return get_shader_parameter(&"emission_texture")
	set(value): set_shader_parameter(&"emission_texture", value)


@export var emission: Color = Color.BLACK:
	get: return get_shader_parameter(&"emission")
	set(value): set_shader_parameter(&"emission", value)


@export_range(0.0, 1.0, 0.001) var alpha_scissor_threshold: float = 0.5:
	set(value):
		alpha_scissor_threshold = value
		set_shader_parameter(&"alpha_scissor_threshold", value if transparency_mode == 1 else 0.0)


func _init() -> void:
	shader = SHADER_TABLE[0]
