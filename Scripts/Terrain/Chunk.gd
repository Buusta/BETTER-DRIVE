class_name Chunk

# relative position 
var position: Vector2 = Vector2.ZERO

# size of the chunnk
var size: int = 0

# Reference to the mesh for this chunk
var mesh = null

# Neighbor sizes or references
var neighbor_sizes = {
	"north": 0,
	"south": 0,
	"west": 0,
	"east": 0
}
