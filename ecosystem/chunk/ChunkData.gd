class_name ChunkData
extends RefCounted

static var next_id: int = 0
const CHUNK_SIZE: int = 20

var id: int
var position: Vector3i
var agents: Array = []
var terrain: bool = false
var last_accessed: float = 0.0

func _init(pos: Vector3i = Vector3i.ZERO):
    id = next_id
    next_id += 1
    position = pos

