@tool class_name PsxMaterial3D extends ShaderMaterial

const TRANSFERABLE_PARAMS: PackedStringArray = [
	&"alpha_scissor_threshold",
	&"cull_mode",
	&"depth_test",
	&"vertex_color_use_as_albedo",
	&"albedo_texture",
	&"albedo_color",
	&"emission_enabled",
	&"emission",
	&"emission_energy_multiplier",
	&"emission_operator",
	&"emission_on_uv2",
	&"emission_texture",
]


#region Shader Precompilation

const SHADER_CODE_INSERT_POSITION := 20 ## "shader_type spatial;\n" == 20
const SHADER_PATH_DIR := "res://addons/psx_visuals/shaders/precompile"
const SHADER_PATH_TEMPLATE := "res://addons/psx_visuals/shaders/precompile/psx_%04d.gdshader"
const SHADER_FLAGS_ALWAYS := ["blend_mix", "diffuse_lambert", "specular_occlusion_disabled", "specular_disabled", "shadows_disabled"]
const SHADER_FLAGS := [
	["", "", "depth_draw_always"],
	["cull_back", "cull_front", "cull_disabled"],
	["depth_test_default", "depth_test_inverted", "depth_test_disabled"],
	["unshaded", "", "vertex_lighting"],
	["fog_disabled", "", "#VERTEX_FOG_ENABLED"],
	["", "#EMISSION_ADD", "#EMISSION_MULTIPLY"],
]

static var SHADER_FLAGS_PERMUTATION_SIZES: PackedInt32Array
static var SHADER_TABLE: Array[Shader]


static func _precompile_shaders() -> void:
	var template := load("res://addons/psx_visuals/shaders/psx_template.gdshader")
	SHADER_TABLE.resize(SHADER_FLAGS_PERMUTATION_SIZES[-1])

	var flags: PackedStringArray = SHADER_FLAGS_ALWAYS.duplicate()

	for f in SHADER_FLAGS.size():
		flags.append(SHADER_FLAGS[f][0])

	for idx in SHADER_FLAGS_PERMUTATION_SIZES[-1]:
		for fdx in SHADER_FLAGS.size():
			flags[fdx + SHADER_FLAGS_ALWAYS.size()] = SHADER_FLAGS[fdx][(idx / SHADER_FLAGS_PERMUTATION_SIZES[fdx] % SHADER_FLAGS[fdx].size())]

		var path := SHADER_PATH_TEMPLATE % idx
		var shader := ResourceLoader.load(path) if ResourceLoader.exists(path) else Shader.new()
		shader.take_over_path(path)

		var render_flags_string: String
		var define_flags_string: String
		for flag in flags:
			if flag.is_empty(): continue
			if flag.begins_with("#"):
				define_flags_string += "\n#define " + flag.right(-1) + ";"
			else:
				render_flags_string += flag + ", "

		render_flags_string = "\nrender_mode " + render_flags_string.left(-2) + ";"

		shader.code = template.code.insert(SHADER_CODE_INSERT_POSITION, render_flags_string + define_flags_string)
		ResourceSaver.save(shader)

		SHADER_TABLE[idx] = ResourceLoader.load(shader.resource_path)
		idx += 1


static func _preload_shaders() -> void:
	SHADER_TABLE.resize(SHADER_FLAGS_PERMUTATION_SIZES[-1])
	for idx in SHADER_FLAGS_PERMUTATION_SIZES[-1]:
		var path := SHADER_PATH_TEMPLATE % idx
		if not ResourceLoader.exists(path): continue

		SHADER_TABLE[idx] = ResourceLoader.load(path)

#endregion


static func _static_init() -> void:
	SHADER_FLAGS_PERMUTATION_SIZES.resize(SHADER_FLAGS.size() + 1)
	SHADER_FLAGS_PERMUTATION_SIZES.fill(1)
	for f in SHADER_FLAGS.size():
		for fi in f:
			SHADER_FLAGS_PERMUTATION_SIZES[-f - 2] *= SHADER_FLAGS[f - fi].size()
		SHADER_FLAGS_PERMUTATION_SIZES[-1] *= SHADER_FLAGS_PERMUTATION_SIZES[-f]

	if Engine.is_editor_hint():
		if not SHADER_TABLE.is_empty(): return

		_precompile_shaders()

		for material: PsxMaterial3D in PsxPlugin.get_resources(["res://"], "PsxMaterial3D"):
			material._refresh_shader()
			ResourceSaver.save(material)

	else:
		_preload_shaders()


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
		_refresh_shader()


@export var emission_on_uv2: bool = false:
	set(value):
		emission_on_uv2 = value
		set_shader_parameter(&"emission_on_uv2", emission_on_uv2)


@export var emission_texture: Texture2D = null:
	set(value):
		emission_texture = value
		set_shader_parameter(&"emission_texture", emission_texture)


func _init() -> void:
	if not Engine.is_editor_hint(): return

	shader = SHADER_TABLE[24]


func _refresh_shader() -> void:
	shader = SHADER_TABLE[_get_shader_index()]

	set_shader_parameter(&"alpha_scissor_threshold", alpha_scissor_threshold if transparency_mode == 1 else 0.0)
	set_shader_parameter(&"emission", emission)
	set_shader_parameter(&"emission_energy_multiplier", emission_energy_multiplier)
	set_shader_parameter(&"emission_operator", emission_operator)
	set_shader_parameter(&"emission_on_uv2", emission_on_uv2)
	set_shader_parameter(&"emission_texture", emission_texture)


func _get_shader_index() -> int:
	return (
		+ transparency_mode * 243
		+ cull_mode * 81
		+ depth_test * 27
		+ shading_mode * 9
		+ fog_mode * 3
		+ (emission_operator + 1 if emission_enabled else 0)
	)
