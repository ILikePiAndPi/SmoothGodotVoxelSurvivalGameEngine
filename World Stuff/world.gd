extends Node3D

@export var noiseMap: FastNoiseLite
@export var groundMap: FastNoiseLite
@export var WorldChunksNode: Node3D
@export var environment: WorldEnvironment
@export var sun: DirectionalLight3D

var chunk_scene := preload("res://World Stuff/chunk.tscn")

var allChunks := {}
var collChunks := []
var collV2s := []
var chunksToDelete := []

# global variables
var chunk_size := 25
var width_scale := 1.0 / 350.0
var height_scale := 200.0
var curAdd := Vector2i(0, 0)
var seed := 0

var chunksToDeletePerFrame := 7

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	seed = randi()
	var string_seed := str(seed)
	var x_offset = string_seed.substr(0, 5)
	var z_offset = string_seed.substr(6, 5)
	noiseMap.seed = seed
	groundMap.seed = seed
	noiseMap.offset.x = int(x_offset)
	noiseMap.offset.z = int(z_offset)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var it := 0
	while it < chunksToDeletePerFrame and len(chunksToDelete) > 0:
		delete_chunk()
		it += 1
	#if curAdd.x < initChunkGen:
		#for i in numPerFrameRange:
			#start_chunk(curAdd)
			#curAdd.y += 1
		#if curAdd.y >= initChunkGen:
			#curAdd.x += 1
			#curAdd.y = 0

func start_chunk(pos: Vector2i) -> void:
	var new_chunk := chunk_scene.instantiate()
	var npos = Vector3(pos.x * chunk_size, 0, pos.y * chunk_size)
	new_chunk.pos = npos
	WorldChunksNode.add_child(new_chunk)
	new_chunk.global_position = npos
	allChunks[pos] = new_chunk

func get_height(x: int, y: int) -> int:
	var baseNoise := noiseMap.get_noise_2d(x * width_scale, y * width_scale)
	return floor(baseNoise * 20.0 * height_scale)

func get_color(x: int, y:int) -> float:
	return groundMap.get_noise_2d(x, y)
	

func delete_chunk() -> void:
	var chunk = allChunks[chunksToDelete[-1]]
	chunk.queue_free()
	allChunks.erase(chunksToDelete[-1])
	chunksToDelete.pop_back()
