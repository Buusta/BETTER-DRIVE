extends Node

# onready vars
@onready var world_handler : Node = get_parent()
@onready var world_seed : int = world_handler.world_seed 
@onready var player : Node = world_handler.player

# export vars
@export var max_chunk_size : int = 128
@export var chunk_levels : int = 1
@export var render_distance : int = 2
@export var split_distance_multiplier : float = 1.2

# vars
var min_chunk_size : int = max_chunk_size / 2**chunk_levels
var previous_chunk : Vector2i

var Quadtree = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_quadtree(player.position)

	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var chunk_pos = Vector2i(floor(player.position.x / max_chunk_size), floor(player.position.z / max_chunk_size))
	if not chunk_pos == previous_chunk:
		update_quadtree(player.position)
		previous_chunk = chunk_pos

# returns a list of root_chunks that surround the player
func generate_root_chunks(pos):
	var chunk_pos = Vector2i(floor(pos.x / max_chunk_size), floor(pos.z / max_chunk_size))

	var chunks = []

	for x in range(chunk_pos.x - render_distance, chunk_pos.x + render_distance + 1):
		for z in range(chunk_pos.y - render_distance, chunk_pos.y + render_distance  + 1):
			chunks.append(Vector2i(x, z))

	return chunks

# returns a full tree that surround the player
func generate_quadtree(pos: Vector3, tree_keys: Array):
	var new_Quadtree = {}
	var pos2d = Vector2(pos.x, pos.z)
	
	for root_chunk in tree_keys:
		if not chebyshev_distance_check(pos2d, Vector2(root_chunk) * max_chunk_size, max_chunk_size):
			var chunk = Chunk.new()
			chunk.position = root_chunk
			chunk.size = max_chunk_size
			new_Quadtree[root_chunk] = chunk
			continue

	print(new_Quadtree)
	print('\n')

# idk yet
func update_quadtree(pos):
	var root_chunks = generate_root_chunks(pos)

	if not Quadtree.keys() == root_chunks:
		#check if quadtree contains chunks that shouldnt be there
		for key in Quadtree:
			if not root_chunks.has(key):
				''' CODE TO REMOVE UNUSED ROOT CHUNKS HERE '''
				Quadtree.erase(key)

		# check if quadtree is missing chunks
		for root_chunk in root_chunks:
			if not Quadtree.has(root_chunk):
				Quadtree[root_chunk] = 'chunk here'
	
	generate_quadtree(pos, Quadtree.keys())

# returns if a chunk should be split
func chebyshev_distance_check(pos1: Vector2, pos2: Vector2, threshold: float) -> bool:
	var dx = abs(pos1.x - pos2.x)
	var dy = abs(pos1.y - pos2.y)

	var distance = max(dx, dy)

	return true if distance <= threshold * split_distance_multiplier else false
