extends CharacterBody3D

@export var camera_mount: Node3D
@export var camera: Camera3D
@export var pos_label: Label

const SPEED = 200.0
const JUMP_VELOCITY = 40.0
const GRAVITY = Vector3.DOWN * 80.0

var numOfChunks := 4
var curNumOfChunks := 0
var currentChunk = -Vector2i.ONE
var altCChunk: Vector2i
var side := 0
var side_width := 2
var distDSide := 0
var sideInc := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
var curChunk := Vector2i.ZERO
var cRad := 1
var spDone := false

var coll_sides := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]

var spTime := 0
var maxSpTime := 3

var renderDistance := 30
var deleteMargin := 3

@onready var parent = get_parent()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.far = renderDistance * parent.chunk_size
	parent.environment.environment.fog_depth_end = renderDistance * parent.chunk_size
	parent.environment.environment.fog_depth_begin = (renderDistance - 2) * parent.chunk_size
	parent.sun.directional_shadow_max_distance = renderDistance * parent.chunk_size

func _process(delta: float) -> void:
	if spTime >= maxSpTime:
		pos_label.text = "Position: " + str(round(global_position.x)) + ", " + str(roundf(global_position.y * 10.0) / 10.0) + ", " + str(round(global_position.z))
		spTime = 0
		altCChunk = Vector2i(floor(global_position.x / parent.chunk_size), floor(global_position.z / parent.chunk_size))
		if altCChunk != currentChunk:
			currentChunk = altCChunk
			cRad = 1
			side = 0
			side_width = 2
			distDSide = 0
			curChunk = currentChunk - Vector2i.ONE
			spDone = false
			update_collision()
			delete_external_chunks()
	spTime += 1
	if not spDone:
		find_chunk_spiral()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += GRAVITY * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and true:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		camera_mount.rotation.x = clampf(camera_mount.rotation.x - event.relative.y * 0.005, deg_to_rad(-89), deg_to_rad(89))

func find_chunk_spiral() -> void:
	if currentChunk not in parent.allChunks:
		var _nullVal := build_chunk(currentChunk)
	while cRad <= renderDistance:
		while side < 4:
			#curChunk += sideInc[side]
			while distDSide < side_width:
				curChunk += sideInc[side]
				distDSide += 1

				if curChunk not in parent.allChunks:
					if not build_chunk(curChunk):
						return

			distDSide = 0
			side += 1
		
		side = 0
		side_width += 2
		distDSide = 0
		curChunk -= Vector2i.ONE
		cRad += 1

	spDone = true

func build_chunk(pos: Vector2i) -> bool:
	parent.start_chunk(pos)
	curNumOfChunks += 1
	if curNumOfChunks >= numOfChunks:
		curNumOfChunks = 0
		return false
	return true

func update_collision() -> void:
	var testVal: Vector2i
	var curChunk: Node3D
	for side in coll_sides:
		testVal = currentChunk + side
		if testVal in parent.allChunks and not testVal in parent.collV2s:
			curChunk = parent.allChunks[testVal]
			parent.collV2s.append(testVal)
			parent.collChunks.append(curChunk)
			curChunk.build_collision()
	var current_spot := 0
	while len(parent.collChunks) > 9:
		curChunk = parent.collChunks[current_spot]
		if curChunk.pos.x / parent.chunk_size - currentChunk.x > 1 or curChunk.pos.x / parent.chunk_size - currentChunk.x < -1 or curChunk.pos.z / parent.chunk_size - currentChunk.y > 1 or curChunk.pos.z / parent.chunk_size - currentChunk.y < -1:
			curChunk.clear_collision()
			parent.collChunks.pop_at(current_spot)
			parent.collV2s.pop_at(current_spot)
		else:
			current_spot += 1

func delete_external_chunks() -> void:
	for chunk in parent.allChunks:
		if absf(global_position.x - chunk.x * parent.chunk_size) > (renderDistance + deleteMargin) * parent.chunk_size or absf(global_position.z - chunk.y * parent.chunk_size) > (renderDistance + deleteMargin) * parent.chunk_size:
			if chunk not in parent.chunksToDelete:
				parent.chunksToDelete.append(chunk)
