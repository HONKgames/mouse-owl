extends StaticBody3D

@export var size: int = 200
@export var height: float = 10.0
@export var noise: FastNoiseLite
@export var flat_spots: Array[Node3D]
@export var flat_radius: float = 10.0
@export var blend_radius: float = 10.0
@export var edge_width: float = 20.0
@export var edge_height: float = 40.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var heights: PackedFloat32Array = PackedFloat32Array()
var offset: float

func _ready() -> void:
	offset = size / 2.0
	for z in range(size + 1):
		for x in range(size + 1):
			heights.append(raise_edges(x, z, flatten(x, z, noise.get_noise_2d(x, z) * height)))
	build_mesh()
	build_collision()
	build_walls()

func build_mesh() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(size):
		for x in range(size):
			var a: Vector3 = Vector3(x - offset, get_height(x, z), z - offset)
			var b: Vector3 = Vector3(x + 1 - offset, get_height(x + 1, z), z - offset)
			var c: Vector3 = Vector3(x - offset, get_height(x, z + 1), z + 1 - offset)
			var d: Vector3 = Vector3(x + 1 - offset, get_height(x + 1, z + 1), z + 1 - offset)
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(b)
			st.add_vertex(d)
			st.add_vertex(c)
	st.generate_normals()
	mesh_instance.mesh = st.commit()

func build_collision() -> void:
	var hms: HeightMapShape3D = collision_shape.shape as HeightMapShape3D
	hms.map_width = size + 1
	hms.map_depth = size + 1
	hms.map_data = heights

func get_height(x: int, z: int) -> float:
	return heights[z * (size + 1) + x]

func get_height_at(world_x: float, world_z: float) -> float:
	var gx: int = clampi(roundi(world_x + offset), 0, size)
	var gz: int = clampi(roundi(world_z + offset), 0, size)
	return get_height(gx, gz)

## Returns the generated terrain normal at a world-space X/Z position.
## Keeping this in the terrain script means placed props use the same surface
## data as the mesh and HeightMapShape3D instead of doing a second raycast.
func get_normal_at(world_x: float, world_z: float, sample_distance: float = 1.0) -> Vector3:
	var left: float = get_height_at(world_x - sample_distance, world_z)
	var right: float = get_height_at(world_x + sample_distance, world_z)
	var forward: float = get_height_at(world_x, world_z - sample_distance)
	var back: float = get_height_at(world_x, world_z + sample_distance)
	return Vector3(left - right, sample_distance * 2.0, forward - back).normalized()

func flatten(x: float, z: float, h: float) -> float:
	var pos: Vector2 = Vector2(x - offset, z - offset)
	for spot in flat_spots:
		var spot_pos: Vector2 = Vector2(spot.global_position.x, spot.global_position.z)
		var dist: float = pos.distance_to(spot_pos)
		if dist < flat_radius:
			return spot.global_position.y
		elif dist < flat_radius + blend_radius:
			var t: float = (dist - flat_radius) / blend_radius
			var s: float = smoothstep(0.0, 1.0, t)
			return lerpf(spot.global_position.y, h, s)
	return h

func raise_edges(x: float, z: float, h: float) -> float:
	var edge_dist: float = minf(minf(x, z), minf(size - x, size - z))
	if edge_dist > edge_width:
		return h
	var t: float = 1.0 - edge_dist / edge_width
	return h + smoothstep(0.0, 1.0, t) * edge_height

func build_walls() -> void:
	for dir: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var coll: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		if dir.x != 0:
			box.size = Vector3(1, 100, size)
		else:
			box.size = Vector3(size, 100, 1)
		coll.shape = box
		coll.position = dir * offset + Vector3.UP * 50
		add_child(coll)
