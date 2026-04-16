@tool class_name PsxMaterial3D extends ShaderMaterial

const PSX_MATERIAL_TRANSFERABLE_PARAMS: PackedStringArray = [
	&"cull_mode",
	&"albedo_texture",
	&"albedo_color",
	&"alpha_scissor_threshold",
	&"emission_texture",
	&"emission",
]

const SHADER_TABLE_SIZE := 729
const SHADER_PATH_TEMPLATE := "res://addons/psx_visuals/shaders/precompile/psx_%03d.gdshader"
const SHADER_ALL_FLAGS := ["blend_mix", "diffuse_lambert", "specular_occlusion_disabled", "specular_disabled", "shadows_disabled"]
const SHADER_T_FLAGS := ["", "", "depth_draw_always"]
const SHADER_C_FLAGS := ["cull_back", "cull_front", "cull_disabled"]
const SHADER_D_FLAGS := ["depth_test_default", "depth_test_inverted", "depth_test_disabled"]
const SHADER_S_FLAGS := ["unshaded", "", "vertex_lighting"]
const SHADER_F_FLAGS := ["fog_disabled", "", "#VERTEX_FOG_ENABLED"]
const SHADER_E_FLAGS := ["", "#EMISSION_ADD", "#EMISSION_MULTIPLY"]
const SHADER_CODE_INSERTION := 20 ## "shader_type spatial;\n" == 20

static var SHADER_TABLE: Array[Shader]


static func _static_init() -> void:
	if Engine.is_editor_hint() and SHADER_TABLE.is_empty():
		_precompile_shaders()

		for material: PsxMaterial3D in PsxPlugin.get_resources(["res://"], "PsxMaterial3D"):
			material._refresh_shader()
			ResourceSaver.save(material)


static func _precompile_shaders() -> void:
	var shader_template := load("res://addons/psx_visuals/shaders/psx_template.gdshader")
	SHADER_TABLE.resize(SHADER_TABLE_SIZE)

	var shader_flags: PackedStringArray = SHADER_ALL_FLAGS.duplicate()
	shader_flags.resize(shader_flags.size() + 6)
	var idx := 0
	for t in 3:
		shader_flags[-6] = SHADER_T_FLAGS[t]
		for c in 3:
			shader_flags[-5] = SHADER_C_FLAGS[c]
			for d in 3:
				shader_flags[-4] = SHADER_D_FLAGS[d]
				for s in 3:
					shader_flags[-3] = SHADER_S_FLAGS[s]
					for f in 3:
						shader_flags[-2] = SHADER_F_FLAGS[f]
						for e in 3:
							shader_flags[-1] = SHADER_E_FLAGS[e]

							var path := SHADER_PATH_TEMPLATE % idx

							var shader := ResourceLoader.load(path) if ResourceLoader.exists(path) else Shader.new()
							shader.code = shader_template.code

							var render_flags_string: String
							var define_flags_string: String
							for flag in shader_flags:
								if flag.is_empty(): continue
								if flag.begins_with("#"):
									define_flags_string += "\n#define " + flag.right(-1) + ";"
								else:
									render_flags_string += flag + ", "

							if not render_flags_string.is_empty():
								render_flags_string = "\nrender_mode " + render_flags_string.left(-2) + ";"

							shader.code = shader.code.insert(SHADER_CODE_INSERTION, render_flags_string + define_flags_string)

							shader.take_over_path(path)
							ResourceSaver.save(shader)

							SHADER_TABLE[idx] = ResourceLoader.load(shader.resource_path)
							idx += 1


@export_subgroup("Transparency")

@export_enum("Opaque", "Cutout", "Transparent") var transparency_mode: int = 0:
	set(value):
		transparency_mode = value
		_refresh_shader()


@export_range(0.0, 1.0, 0.001) var alpha_scissor_threshold: float = 0.5:
	set(value):
		alpha_scissor_threshold = value
		set_shader_parameter(&"alpha_scissor_threshold", alpha_scissor_threshold if transparency_mode == 1 else 0.0)


@export var cull_mode := BaseMaterial3D.CullMode.CULL_BACK:
	set(value):
		cull_mode = value
		_refresh_shader()


@export_enum("Default", "Inverted", "Disabled") var depth_test: int = 0:
	set(value):
		depth_test = value
		_refresh_shader()


@export_subgroup("Shading")


@export_enum("Unshaded", "Per-Pixel", "Per-Vertex") var shading_mode: int = 2:
	set(value):
		shading_mode = value
		_refresh_shader()


@export_enum("Disabled", "Per-Pixel", "Per-Vertex") var fog_mode: int = 2:
	set(value):
		fog_mode = value
		_refresh_shader()


@export_subgroup("Color")

@export var vertex_color_use_as_albedo: bool = true:
	set(value):
		vertex_color_use_as_albedo = value
		set_shader_parameter(&"vertex_color_use_as_albedo", vertex_color_use_as_albedo)


@export var albedo_texture: Texture2D = null:
	set(value):
		albedo_texture = value
		set_shader_parameter(&"albedo_texture", albedo_texture)


@export var albedo_color: Color = Color.WHITE:
	set(value):
		albedo_color = value
		set_shader_parameter(&"albedo_color", albedo_color)


@export_subgroup("Emission", "emission_")


@export var emission_enabled: bool = false:
	set(value):
		emission_enabled = value
		_refresh_shader()


@export_color_no_alpha var emission: Color = Color.BLACK:
	set(value):
		emission = value
		set_shader_parameter(&"emission", emission)


@export_range(0.0, 16.0, 0.01, "or_greater") var emission_energy_multiplier: float = 1.0:
	set(value):
		emission_energy_multiplier = value
		set_shader_parameter(&"emission_energy_multiplier", emission_energy_multiplier)


@export_enum("Add", "Multiply") var emission_operator: int = BaseMaterial3D.EmissionOperator.EMISSION_OP_ADD:
	set(value):
		emission_operator = value


@export var emission_on_uv2: bool = false:
	set(value):
		emission_on_uv2 = value
		set_shader_parameter(&"emission_on_uv2", emission_on_uv2)


@export var emission_texture: Texture2D = null:
	set(value):
		emission_texture = value
		set_shader_parameter(&"emission_texture", emission_texture)


func _init() -> void:
	shader = SHADER_TABLE[24]


func _refresh_shader() -> void:
	shader = SHADER_TABLE[
		+ transparency_mode * 243
		+ cull_mode * 81
		+ depth_test * 27
		+ shading_mode * 9
		+ fog_mode * 3
		+ (emission_operator + 1 if emission_enabled else 0)
	]

	set_shader_parameter(&"alpha_scissor_threshold", alpha_scissor_threshold if transparency_mode == 1 else 0.0)
	set_shader_parameter(&"emission", emission)
	set_shader_parameter(&"emission_energy_multiplier", emission_energy_multiplier)
	set_shader_parameter(&"emission_operator", emission_operator)
	set_shader_parameter(&"emission_on_uv2", emission_on_uv2)
	set_shader_parameter(&"emission_texture", emission_texture)
