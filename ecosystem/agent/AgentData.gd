class_name AgentData

static var next_id: int = 0
static var agents: Dictionary = {}

var id: int
var species: String

# Current state
var position: Vector3
var velocity: Vector3 = Vector3.ZERO
var age: float = 0.0
var health: float = 100.0
var energy: float = 100.0

# Behavior biases
var waypoints: Array = []

func _init(pos: Vector3 = Vector3.ZERO) -> void:
    id = next_id
    next_id += 1
    agents[id] = self
    position = pos
