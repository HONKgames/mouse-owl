shader_type spatial;
render_mode cull_disabled;

uniform vec4 grass_color : source_color = vec4(0.06, 0.15, 0.08, 1.0);

global uniform vec3 player_position;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	vec3 dir = world_pos - player_position;
	dir.y = 0.0;
	
	float dist = length(dir);
	float interaction_radius = 1.5;
	
	if (dist < interaction_radius && dist > 0.001) {
		float push_strength = (1.0 - (dist / interaction_radius));
		float height_weight = max(0.0, VERTEX.y); 
		
		vec3 push_offset = normalize(dir) * push_strength * height_weight * 0.7;
		VERTEX.xz += push_offset.xz;
	}
}

void fragment() {
	ALBEDO = grass_color.rgb;
	ROUGHNESS = 0.9;
}