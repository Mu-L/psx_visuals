const float SNAP_DISTANCE_SCALAR = 0.005;

global uniform float psx_affine_strength;
global uniform float psx_snap_distance;

// If enabled, we will perform Gouraud shading and multiply vertex colors to [albedo_texture].
uniform bool vertex_color_use_as_albedo = true;

uniform sampler2D albedo_texture: hint_default_white, filter_nearest;
uniform vec4 albedo_color: source_color = vec4(1.0);
uniform float alpha_scissor_threshold: hint_range(0.0, 1.0, 0.01) = 0.5;

varying vec3 VERTEX_COLOR;
varying float VERTEX_DEPTH;
varying vec2 affine_uv_scaled;

#ifdef EMISSION_ADD
uniform vec3 emission: source_color = vec3(0.0, 0.0, 0.0);
uniform float emission_energy_multiplier = 1.0;
uniform bool emission_on_uv2 = false;
uniform sampler2D emission_texture: hint_default_white, filter_nearest;
#endif
#ifdef EMISSION_MULTIPLY
uniform vec3 emission: source_color = vec3(0.0, 0.0, 0.0);
uniform float emission_energy_multiplier = 1.0;
uniform bool emission_on_uv2 = false;
uniform sampler2D emission_texture: hint_default_white, filter_nearest;
#endif

#ifdef VERTEX_FOG_ENABLED
global uniform vec4 psx_fog_color;
global uniform float psx_fog_far;
global uniform float psx_fog_near;

varying float fog_strength;
varying vec3 fog_color;
#endif


vec3 snap(vec3 vertex, mat4 matrix) {
	if (psx_snap_distance == 0.0) return vertex;
	
	vec4 v = (matrix * vec4(vertex, 1.0));
	float snap_distance = psx_snap_distance * SNAP_DISTANCE_SCALAR;
	v.xy = round((v.xy / v.z) / snap_distance) * v.z * snap_distance;
	return (inverse(matrix) * v).xyz;
}


void vertex() {
    VERTEX_COLOR = COLOR.rgb;

	VERTEX = snap(VERTEX, MODELVIEW_MATRIX);
	vec3 vertex_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	VERTEX_DEPTH = distance(vertex_world, CAMERA_POSITION_WORLD);
	affine_uv_scaled = UV * VERTEX_DEPTH;
	
#ifdef VERTEX_FOG_ENABLED
	fog_strength = psx_fog_near != psx_fog_far ?
		clamp(psx_fog_color.a * (VERTEX_DEPTH - psx_fog_near) / (psx_fog_far - psx_fog_near), 0.0, 1.0) :
		0.0;
	fog_color = mix(vec3(0), psx_fog_color.rgb, fog_strength);
#endif
}


void fragment() {
	vec2 affine_uv = affine_uv_scaled / VERTEX_DEPTH;
	vec2 uv = mix(UV, affine_uv, psx_affine_strength);
	vec2 uv2 = mix(UV2, affine_uv, psx_affine_strength);

	vec4 albedo_final = texture(albedo_texture, uv) * albedo_color;
	if (vertex_color_use_as_albedo) {
		albedo_final *= vec4(VERTEX_COLOR, 1.0);
	}

#ifdef EMISSION_ADD
	vec3 emission_final = texture(emission_texture, emission_on_uv2 ? uv2 : uv).rgb + emission;
	EMISSION = emission_final * emission_energy_multiplier;
#endif
#ifdef EMISSION_MULTIPLY
	vec3 emission_final = texture(emission_texture, emission_on_uv2 ? uv2 : uv).rgb * emission;
	EMISSION = emission_final * emission_energy_multiplier;
#endif
	
#ifdef VERTEX_FOG_ENABLED
	ALBEDO = albedo_final.rgb * (1.0 - fog_strength) + fog_color;
	EMISSION += fog_color;
#else
	ALBEDO = albedo_color.rgb;
#endif

	ALPHA *= albedo_final.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;

	SPECULAR = 0.0;
	ROUGHNESS = 0.0;
	METALLIC = 0.0;
	AO = 1.0;
}
