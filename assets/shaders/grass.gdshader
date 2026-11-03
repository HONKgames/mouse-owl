shader_type spatial;
render_mode cull_disabled;

uniform vec4 grass_color : source_color = vec4(0.12, 0.28, 0.13, 1.0);
uniform sampler2D grass_texture : source_color, filter_nearest;

global uniform vec3 player_position;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float wind_speed = 1.5;
	float wind_strength = 0.075;
	float wind_wave = sin(TIME * wind_speed + (world_pos.x + world_pos.z) * 0.08) * wind_strength;
	
	float height_weight = max(0.0, VERTEX.y);
	VERTEX.x += wind_wave * height_weight;
	VERTEX.z += (wind_wave * 0.6) * height_weight;
	
	vec3 world_dir = world_pos - player_position;
	world_dir.y = 0.0;
	
	float dist = length(world_dir);
	float interaction_radius = 2.0;
	
	if (dist < interaction_radius && dist > 0.001) {
		float push_strength = (1.0 - (dist / interaction_radius));
		float player_height_weight = max(0.0, VERTEX.y + 0.2); 
		
		vec3 world_offset = normalize(world_dir) * push_strength * player_height_weight * 1.2;
		
		mat4 inv_model = inverse(MODEL_MATRIX);
		vec3 local_offset = (inv_model * vec4(world_offset, 0.0)).xyz;
		
		VERTEX += local_offset;
	}
}

void fragment() {
	vec4 tex_color = texture(grass_texture, UV);
	
	float retro_shade = floor((NORMAL.y * 0.5 + 0.5) * 4.0) / 4.0;
	
	// Combines your texture, tint color, and retro lighting
	ALBEDO = tex_color.rgb * grass_color.rgb * (0.6 + retro_shade * 0.4);
	ROUGHNESS = 0.95;
}