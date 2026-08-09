extends Node3D

var being_threaded := false

@export var material: StandardMaterial3D

# blockHeight
var blocks := PackedInt32Array()
var verts := PackedVector3Array()
var cols := PackedColorArray()
var cur_spot := 0
var size_xz := 0
var parent: Node3D
var up := Vector3.UP
var collShape3D: CollisionShape3D
var meshInstance3D: MeshInstance3D
var staticBody: StaticBody3D
var pos: Vector3

# quick lists
# parralel:       Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	parent = get_parent().get_parent()
	size_xz = parent.chunk_size + 1
	blocks.resize(size_xz * size_xz)
	verts.resize((size_xz - 1) * (size_xz - 1) * 6)
	cols.resize((size_xz - 1) * (size_xz - 1) * 6)
	build_chunk()
	# build_collision()
	build_mesh()

func build_collision() -> void:
	staticBody = StaticBody3D.new()
	add_child(staticBody)
	collShape3D = CollisionShape3D.new()
	staticBody.add_child(collShape3D)
	var shape := ConcavePolygonShape3D.new()

	shape.set_faces(verts)
	collShape3D.shape = shape
	

func clear_collision() -> void:
	if collShape3D is not CollisionShape3D:
		return
	collShape3D.shape = null
	collShape3D.queue_free()
	collShape3D = null
	staticBody.queue_free()
	staticBody = null

func build_mesh() -> void:
	meshInstance3D = MeshInstance3D.new()
	add_child(meshInstance3D)
	meshInstance3D.material_override = material
	var mesh := ArrayMesh.new()
	var all_arrays = []
	all_arrays.resize(Mesh.ARRAY_MAX)
	all_arrays[Mesh.ARRAY_VERTEX] = verts
	all_arrays[Mesh.ARRAY_COLOR] = cols
	#all_arrays[Mesh.ARRAY_NORMAL] = norms
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, all_arrays)
	meshInstance3D.mesh = mesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func build_chunk() -> void:
	var cV2 = Vector2i(0, 0)
	var index := 0
	var x := 0
	var z := 0
	while x < size_xz:
		cV2.x = x
		z = 0
		while z < size_xz:
			cV2.y = z
			index = x * size_xz + z
			blocks[index] = parent.get_height(pos.x + x, pos.z + z)
			if x > 0 and z > 0:
				# build faces
				add_neg_face(cV2, index)
			z += 1
		x += 1

func add_neg_face(cV2: Vector2i, index: int):
	var colOpt: float = (parent.get_color(pos.x + cV2.x, pos.z + cV2.y) + 1.0) / 5.0
	var col := Color(colOpt + 0.2, colOpt / 5.0 + 0.05, colOpt / 8.0)

	verts[cur_spot] = Vector3(cV2.x, blocks[index], cV2.y)
	cols[cur_spot] = col
	cur_spot += 1
	
	verts[cur_spot] = Vector3(cV2.x - 1, blocks[index - size_xz], cV2.y)
	cols[cur_spot] = col
	cur_spot += 1
	
	verts[cur_spot] = Vector3(cV2.x, blocks[index - 1], cV2.y -1)
	cols[cur_spot] = col
	cur_spot += 1
	
	verts[cur_spot] = Vector3(cV2.x -1, blocks[index - size_xz - 1], cV2.y -1)
	cols[cur_spot] = col
	cur_spot += 1
	
	verts[cur_spot] = Vector3(cV2.x, blocks[index - 1], cV2.y -1)
	cols[cur_spot] = col
	cur_spot += 1
	
	verts[cur_spot] = Vector3(cV2.x -1, blocks[index - size_xz], cV2.y)
	cols[cur_spot] = col
	cur_spot += 1
