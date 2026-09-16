shader_type spatial;
render_mode cull_disabled;

uniform vec3 low_color : source_color = vec3(0.25, 0.45, 0.15);
uniform vec3 mid_color : source_color = vec3(0.45, 0.4, 0.3);
uniform vec3 high_color : source_color = vec3(0.9, 0.9, 0.95);
uniform float mid_height = 4.0;
uniform float high_height = 9.0;

varying float world_height;

void vertex() {
	world_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	vec3 color = mix(low_color, mid_color, smoothstep(0.0, mid_height, world_height));
	color = mix(color, high_color, smoothstep(mid_height, high_height, world_height));
	ALBEDO = color;
	ROUGHNESS = 0.95;
}
