extends Node3D

@export_category("Lights")
@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var world_env: WorldEnvironment

@export_category("Sprites")
@export var sun_sprite: Sprite3D
@export var moon_sprite: Sprite3D
@export var clouds: Node3D

@export_category("Settings")
@export var orbit_distance: float = 100.0
@export var day_color: Color = Color("4a90e2")
@export var night_color: Color = Color("411c6bff")

@export_category("Clouds")
@export var cloud_count: int = 12
@export var cloud_speed: float = 1.5
@export var sky_height: float = 50.0
@export var spawn_range: Vector2 = Vector2(-120.0, 120.0)
@export var cloud_material: Material

func _ready() -> void:
	_spawn_clouds()
	
func _process(delta: float) -> void:
	var time_progress: float = TimeGlobal.get_time()
	var angle_rad: float = (time_progress * TAU) + (PI / 2.0)
	
	_update_sun(time_progress, angle_rad)
	_update_moon(time_progress, angle_rad)
	_update_sky_color(time_progress)
	_move_clouds(delta)
	
func _spawn_clouds() -> void:
	if not clouds:
		return
	
	for i in range(cloud_count):
		var cloud: MeshInstance3D = MeshInstance3D.new()
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(randf_range(10.0, 22.0), randf_range(3.0, 6.0))
		cloud.mesh = quad
		
		if cloud_material:
			cloud.material_override = cloud_material
			
		var rx: float = randf_range(spawn_range.x, spawn_range.y)
		var rz: float = randf_range(spawn_range.x, spawn_range.y)
		var ry: float = sky_height + randf_range(-5.0, 5.0)
		
		cloud.position = Vector3(rx, ry, rz)
		clouds.add_child(cloud)
		
		
	
func _update_sun(time_progress: float, angle_rad: float) -> void:
	if not sun:
		return
	sun.rotation_degrees.x = (time_progress * 360.0) + 90.0
	var sun_intensity: float = clamp(sin(time_progress * TAU), 0.0, 1.0)
	sun.light_energy = sun_intensity * 1.5
	sun.shadow_enabled = sun_intensity > 0.05
	
	if sun_sprite:
		var dir := Vector3(0.0, sin(angle_rad), cos(angle_rad)).normalized()
		sun_sprite.global_position = global_position + (dir * orbit_distance)
		sun_sprite.visible = sun_intensity > 0.0
	
func _update_moon(time_progress: float, angle_rad: float) -> void:
	if not moon:
		return
	moon.rotation_degrees.x = (time_progress * 360.0) + 270.0
	var moon_intensity: float = clamp(-sin(time_progress * TAU), 0.0, 1.0)
	moon.light_energy = moon_intensity * 0.3
	moon.shadow_enabled = moon_intensity > 0.05
	
	if moon_sprite:
		var dir := Vector3(0.0, -sin(angle_rad), -cos(angle_rad)).normalized()
		moon_sprite.global_position = global_position + (dir * orbit_distance)
		moon_sprite.visible = moon_intensity > 0.0

func _update_sky_color(time_progress: float) -> void:
	if not world_env or not world_env.environment:
		return
		
	var env = world_env.environment
	var night_factor: float = clamp(-sin(time_progress * TAU), 0.0, 1.0)

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
