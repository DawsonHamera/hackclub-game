extends Camera3D

@export var target: Node3D
@export var predicted_time_ahead: float = 0.5
@export var offset: Vector3 = Vector3(0, 0, 5)
@export var springiness: float = 2

var predicted_target_position: Vector3 = Vector3.ZERO

func _process(delta):
    pass


func _physics_process(delta):
    if target:
        predicted_target_position = target.global_transform.origin + target.velocity * predicted_time_ahead

        var goal = predicted_target_position + target.transform.basis * offset

        global_transform.origin = global_transform.origin.lerp(goal, delta * springiness)

        look_at(predicted_target_position, Vector3.UP)