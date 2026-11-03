extends Node3D

@export_category("Lights")
@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var extra: DirectionalLight3D
@export var world_env: WorldEnvironment

@export_category("Sprites")
@export var sun_sprite: Sprite3D
@export var moon_sprite: Sprite3D
@export var clouds: Node3D

@export_category("Settings")
@export var orbit_distance: float = 1000.0
@export var day_color: Color = Color("4a90e2")
@export var night_color: Color = Color("411c6bff")

@export_category("Clouds")
@export var cloud_count: int = 1200
@export var cloud_speed: float = 1.5
@export var sky_height: float = 50.0
@export var spawn_range: Vector2 = Vector2(-500.0, 500.0)
@export var cloud_material: Material

func _ready() -> void:
	_spawn_clouds()
	
func _process(delta: float) -> void:
	var time_progress: float = TimeGlobal.get_time()
	
	_update_sun(time_progress)
	_update_moon(time_progress)
	_update_sky_color(time_progress)
	_move_clouds(delta)
	
func _spawn_clouds() -> void:
	if not clouds:
		return
	
	for i in range(cloud_count):
		var cloud: MeshInstance3D = MeshInstance3D.new()
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(randf_range(12.0, 20.0), randf_range(6.0, 10.0))
		cloud.mesh = quad
		
		if cloud_material:
			cloud.material_override = cloud_material
		
		cloud.rotation_degrees.x = 90.0
		var rx: float = randf_range(spawn_range.x, spawn_range.y)
		var rz: float = randf_range(spawn_range.x, spawn_range.y)
		var ry: float = sky_height + randf_range(-5.0, 5.0)
		
		cloud.position = Vector3(rx, ry, rz)
		clouds.add_child(cloud)
		
func _update_sun(time_progress: float) -> void:
	if not sun:
		return
	
	var sun_angle: float = (time_progress - 0.25) * TAU
	var dir := Vector3(0.0, sin(sun_angle), -cos(sun_angle)).normalized()
	
	sun.global_position = global_position
	sun.look_at(global_position - dir, Vector3.UP)
	
	var sun_intensity: float = clamp(cos((time_progress - 0.5) * TAU), 0.0, 1.0)
	sun.light_energy = sun_intensity * 3.0
	sun.shadow_enabled = sun_intensity > 0.05
	
	if sun_sprite:
		sun_sprite.global_position = global_position + (dir * orbit_distance)
		sun_sprite.visible = true
		sun_sprite.look_at(global_position, Vector3.UP)
	
func _update_moon(time_progress: float) -> void:
	if not moon:
		return
		
	var moon_angle: float = (time_progress - 0.25) * TAU + PI
	var moon_dir := Vector3(0.0, sin(moon_angle), -cos(moon_angle)).normalized()
	
	moon.global_position = global_position
	moon.look_at(global_position - moon_dir, Vector3.UP)
	
	var moon_intensity: float = clamp(-cos((time_progress - 0.5) * TAU), 0.0, 1.0)
	moon.light_energy = moon_intensity * 0.05
	moon.shadow_enabled = moon_intensity > 0.05
	
	if moon_sprite:
		moon_sprite.global_position = global_position + (moon_dir * orbit_distance)
		moon_sprite.visible = true
		moon_sprite.look_at(global_position, Vector3.UP)

func _update_sky_color(time_progress: float) -> void:
	if not world_env or not world_env.environment:
		return
		
	var env: Environment = world_env.environment
	env.background_mode = Environment.BG_COLOR
	
	var day_factor: float = clamp(cos((time_progress - 0.5) * TAU), 0.0, 1.0)
	var current_sky_color: Color = night_color.lerp(day_color, day_factor)
	
	env.sdfgi_enabled = day_factor > 0.05
	extra.visible = day_factor > 0.05
	env.background_color = current_sky_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = current_sky_color
	env.ambient_light_energy = lerp(0.1, 0.9, day_factor)

	var night_factor: float = clamp(-cos((time_progress - 0.5) * TAU), 0.0, 1.0)
	if env.fog_enabled:
		env.fog_density = lerp(0.005, 0.03, night_factor)
		env.fog_light_color = Color("120421").lerp(Color("a457e6ff"), night_factor * 0.5)

	if env.glow_enabled:
		env.glow_intensity = lerp(1.0, 2.0, night_factor)

func _move_clouds(delta: float) -> void:
	if not clouds:
		return
	
	for cloud in clouds.get_children():
		cloud.position.x += cloud_speed * delta
		if cloud.position.x > spawn_range.y:
			cloud.position.x = spawn_range.x
