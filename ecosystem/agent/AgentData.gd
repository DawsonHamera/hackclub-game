class_name AgentData

static var next_id: int = 0
static var agents: Dictionary = {}

var id: int
var species: String

# Current state
var position: Vector3
var velocity: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO
var age: float = 0.0
var health: float = 100.0
var energy: float = 100.0

# Behavior biases
var waypoints: Array = []

var scene_instance: Node3D = null
var is_loaded: bool = false

var target_position: Vector3 = Vector3.ZERO
var wander_radius: float = 80.0

func _init(pos: Vector3 = Vector3.ZERO) -> void:
	id = next_id
	next_id += 1
	agents[id] = self
	position = pos

	target_position = position + Vector3(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)


func update_agent(delta: float) -> void:
	var to_target = target_position - position
	var distance_to_target = to_target.length()

	if distance_to_target < 1.0:
		target_position = position + Vector3(
			randf_range(-wander_radius, wander_radius),
			randf_range(-wander_radius, wander_radius),
			randf_range(-wander_radius, wander_radius)
		)

	var direction = to_target.normalized()
	velocity = direction * 10
	position += velocity * delta

	