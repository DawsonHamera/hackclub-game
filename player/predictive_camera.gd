extends Camera3D

@export var target: Node3D
@export var predicted_time_ahead: float = 0.5
@export var offset: Vector3 = Vector3(0, 1, 3)
@export var springiness: float = 2

var predicted_target_position: Vector3 = Vector3.ZERO

func _input(event):
	if event.is_action_pressed("zoom_in"):
		offset.z -= 0.5
	elif event.is_action_pressed("zoom_out"):
		offset.z += 0.5

func _physics_process(delta):
	if target:
		predicted_target_position = target.global_transform.origin + target.velocity * predicted_time_ahead

		var goal = predicted_target_position + target.transform.basis * offset

		global_transform.origin = global_transform.origin.lerp(goal, delta * springiness)

		look_at(predicted_target_position, Vector3.UP)
