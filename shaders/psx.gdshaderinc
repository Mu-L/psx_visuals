
global uniform int psx_bit_depth;

const float PSX_DITHER_MATRIX[16] = float[](
    0.0,  8.0,  2.0, 10.0,
    12.0, 4.0, 14.0, 6.0,
    3.0, 11.0, 1.0,  9.0,
    15.0, 7.0, 13.0, 5.0
);
vec4 dither(vec4 color, vec2 uv) {
	ivec2 p = ivec2(floor(uv));
	int xi = int(p.x & 3);
	int yi = int(p.y & 3);
	int index = xi + yi * 4;
	
	float norm = PSX_DITHER_MATRIX[index] / 16.0;
	float bit_levels = float((1 << psx_bit_depth) - 1);
	return floor((color + norm / bit_levels) * bit_levels) / bit_levels;
}


global uniform float psx_snap_distance;

vec3 snap(vec3 vertex, mat4 matrix) {
	if (psx_snap_distance == 0.0) return vertex;
	
	vec4 v = (matrix * vec4(vertex, 1.0));
	float snap_distance = psx_snap_distance * 0.005;
	v.xy = round((v.xy / v.z) / snap_distance) * v.z * snap_distance;
	return (inverse(matrix) * v).xyz;
}
