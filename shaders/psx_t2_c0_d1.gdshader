shader_type spatial;
render_mode depth_test_inverted, cull_back, blend_mix, vertex_lighting, depth_draw_always, diffuse_lambert, specular_occlusion_disabled, specular_disabled, shadows_disabled, fog_disabled;

#include "res://addons/psx_visuals/shaders/psx.gdshaderinc"

global uniform float psx_affine_strength;
global uniform vec4 psx_fog_color;
global uniform float psx_fog_far;
global uniform float psx_fog_near;

// If enabled, we will perform Gouraud shading and multiply vertex colors to [albedo_texture].
uniform bool use_vertex_colors_in_albedo = true;

// If enabled, use global PSX fog. Otherwise, fog will not appear on these surfaces, as if there is a hole in the fog.
uniform bool use_global_fog = true;

uniform sampler2D albedo_texture: hint_default_white, filter_nearest;
uniform vec4 albedo_color: source_color = vec4(1);

uniform sampler2D emission_texture: hint_default_black, filter_nearest;
uniform vec3 emission: source_color = vec3(1);

varying vec3 VERTEX_COLOR;
varying float VERTEX_DEPTH;

varying float fog_strength;
varying vec2 affine_uv_scaled;

void vertex() {
    VERTEX_COLOR = COLOR.rgb;

	VERTEX = snap(VERTEX, MODELVIEW_MATRIX);
	vec3 vertex_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	VERTEX_DEPTH = distance(vertex_world, CAMERA_POSITION_WORLD);
	affine_uv_scaled = UV * VERTEX_DEPTH;
	fog_strength = (use_global_fog && psx_fog_near != psx_fog_far) ?
		clamp(psx_fog_color.a * (VERTEX_DEPTH - psx_fog_near) / (psx_fog_far - psx_fog_near), 0.0, 1.0) :
		0.0;
}

void fragment() {
	vec2 affine_uv = affine_uv_scaled / VERTEX_DEPTH;
	vec2 uv = mix(UV, affine_uv, psx_affine_strength);

	vec3 fog_rgb = mix(vec3(0), psx_fog_color.rgb, fog_strength);

	vec4 albedo_final = texture(albedo_texture, uv) * albedo_color;
	if (use_vertex_colors_in_albedo) {
		albedo_final *= vec4(VERTEX_COLOR, 1.0);
	}
	ALBEDO = albedo_final.rgb * (1.0 - fog_strength) + fog_rgb;
	ALPHA *= albedo_final.a;

	vec4 emission_final = texture(emission_texture, uv) * vec4(emission, 1.0);
	EMISSION = (emission_final.rgb * emission_final.a) + fog_rgb;

	SPECULAR = 0.0;
	ROUGHNESS = 0.0;
	METALLIC = 0.0;
	AO = 1.0;
}
