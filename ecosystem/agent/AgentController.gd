extends Node3D

var agent_data: AgentData
var target_position: Vector3 = Vector3.ZERO

var velocity : Vector3 = Vector3.ZERO

var wander_radius: float = 40.0

func _ready() -> void:
	if agent_data == null:
		push_error("AgentController has no AgentData assigned.")
		return
	global_position = Vector3(agent_data.position)
	target_position = global_position + Vector3(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)


func _physics_process(delta: float) -> void:
	var to_target = target_position - global_position
	var distance_to_target = to_target.length()

	if distance_to_target < 1.0:
		target_position = global_position + Vector3(
			randf_range(-wander_radius, wander_radius),
			randf_range(-wander_radius, wander_radius),
			randf_range(-wander_radius, wander_radius)
		)

	var direction = to_target.normalized()
	velocity = direction * 5.0
	global_position += velocity * delta

	# Smoothly rotate toward the target
	var current_basis = global_transform.basis
	var target_basis = Transform3D().looking_at(target_position - global_position, Vector3.UP).basis
	global_transform.basis = current_basis.slerp(target_basis, 0.01).orthonormalized()

	agent_data.position = global_position
