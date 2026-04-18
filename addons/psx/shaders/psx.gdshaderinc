global uniform float psx_affine_strength;
global uniform float psx_precision_uv;
global uniform float psx_precision_xy;
global uniform float psx_precision_z;

instance uniform float i_precision_uv = 1.0;
instance uniform float i_precision_xy = 1.0;
instance uniform float i_precision_z = 1.0;

uniform bool u_vertex_color_use_as_albedo = true;

uniform sampler2D u_albedo_texture: hint_default_white, filter_nearest;
uniform vec4 u_albedo_color: source_color = vec4(1.0);

varying vec3 v_vertex_color;
varying vec4 v_clip;
varying vec2 v_uv;
varying vec2 v_uv2;

#ifdef ALPHA_SCISSOR
uniform float u_alpha_scissor_threshold: hint_range(0.0, 1.0, 0.01) = 0.5;
#endif

#ifdef EMISSION_ADD
uniform vec3 u_emission: source_color = vec3(0.0, 0.0, 0.0);
uniform float u_emission_energy_multiplier = 1.0;
uniform bool u_emission_on_uv2 = false;
uniform sampler2D u_emission_texture: hint_default_white, filter_nearest;
#endif
#ifdef EMISSION_MULTIPLY
uniform vec3 u_emission: source_color = vec3(0.0, 0.0, 0.0);
uniform float u_emission_energy_multiplier = 1.0;
uniform bool u_emission_on_uv2 = false;
uniform sampler2D u_emission_texture: hint_default_white, filter_nearest;
#endif

#ifdef VERTEX_FOG_ENABLED
global uniform vec4 psx_fog_color;
global uniform float psx_fog_far;
global uniform float psx_fog_near;

varying float v_fog_strength;
varying vec3 v_fog_color;
#endif


void vertex() {
    v_vertex_color = COLOR.rgb;

	vec2 viewport_ratio = VIEWPORT_SIZE / VIEWPORT_SIZE.y;
	float precision_xy = psx_precision_xy * i_precision_xy;
	float precision_z = psx_precision_z * i_precision_z;

	v_clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	//v_clip.xyz /= v_clip.w;
	v_clip.xy *= viewport_ratio;
	if (precision_xy != 0.0) {
		v_clip.xy = trunc((v_clip.xy / v_clip.z) * precision_xy) * v_clip.z / precision_xy;
	}
	if (precision_z != 0.0) {
		v_clip.z = trunc((v_clip.z) * precision_z) / precision_z;
	}
	v_clip.xy /= viewport_ratio;
	//v_clip.xyz *= v_clip.w;
	VERTEX = (inverse(PROJECTION_MATRIX * MODELVIEW_MATRIX) * v_clip).xyz;

	v_uv = UV * v_clip.w;
	v_uv2 = UV2 * v_clip.w;

#ifdef VERTEX_FOG_ENABLED
	v_fog_strength = psx_fog_near != psx_fog_far ?
		clamp(psx_fog_color.a * (v_clip.w - psx_fog_near) / (psx_fog_far - psx_fog_near), 0.0, 1.0) :
		0.0;
	v_fog_color = mix(vec3(0), psx_fog_color.rgb, v_fog_strength);
#endif
}


void fragment() {
	vec2 uv = mix(UV, v_uv / v_clip.w, psx_affine_strength);
	vec2 uv2 = mix(UV2, v_uv2 / v_clip.w, psx_affine_strength);
	float precision_uv = psx_precision_uv * i_precision_uv;

	if (precision_uv != 0.0) {
		uv = trunc(uv * precision_uv) / precision_uv;
		uv2 = trunc(uv2 * precision_uv) / precision_uv;
	}

	vec4 albedo = texture(u_albedo_texture, uv) * u_albedo_color;
	if (u_vertex_color_use_as_albedo) {
		albedo *= vec4(v_vertex_color, 1.0);
	}

#ifndef ALPHA_DISABLED
	ALPHA = albedo.a;
#endif
#ifdef ALPHA_SCISSOR
	ALPHA_SCISSOR_THRESHOLD = u_alpha_scissor_threshold;
#endif

#ifdef EMISSION_ADD
	vec3 emission = texture(u_emission_texture, u_emission_on_uv2 ? uv2 : uv).rgb + u_emission;
	EMISSION = emission * u_emission_energy_multiplier;
#endif
#ifdef EMISSION_MULTIPLY
	vec3 emission = texture(u_emission_texture, u_emission_on_uv2 ? uv2 : uv).rgb * u_emission;
	EMISSION = emission * u_emission_energy_multiplier;
#endif

#ifdef VERTEX_FOG_ENABLED
	ALBEDO = albedo.rgb * (1.0 - v_fog_strength) + v_fog_color;
	EMISSION += v_fog_color;
#else
	ALBEDO = albedo.rgb;
#endif

	SPECULAR = 0.0;
	ROUGHNESS = 0.0;
	METALLIC = 0.0;
	AO = 1.0;
}
