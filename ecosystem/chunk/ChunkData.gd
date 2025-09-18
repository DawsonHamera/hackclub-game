class_name ChunkData
extends RefCounted

static var chunks: Dictionary = {}

static var next_id: int = 0
const CHUNK_SIZE: int = 64

var id: int
var position: Vector3i
var agents: Array = []
var obstacles: Array = []
var terrain: PackedScene = null
var last_accessed: float = 0.0
var scene_instance: Node3D = preload("res://ecosystem/chunk/chunk.tscn").instantiate()

var resources: Dictionary = {}

func _init(pos: Vector3i = Vector3i.ZERO) -> void:
	id = next_id
	next_id += 1
	position = pos 
	scene_instance.chunk_data = self
	chunks[id] = self
	# obstacles.append(Obstacle.new(Vector3( randf(), randf(),  randf()), Vector3(1, 1, 1), "res://models/grass.glb"))
