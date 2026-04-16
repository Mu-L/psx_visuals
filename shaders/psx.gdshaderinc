
global uniform float psx_snap_distance;

vec3 snap(vec3 vertex, mat4 matrix) {
	if (psx_snap_distance == 0.0) return vertex;
	
	vec4 v = (matrix * vec4(vertex, 1.0));
	float snap_distance = psx_snap_distance * 0.005;
	v.xy = round((v.xy / v.z) / snap_distance) * v.z * snap_distance;
	return (inverse(matrix) * v).xyz;
}
