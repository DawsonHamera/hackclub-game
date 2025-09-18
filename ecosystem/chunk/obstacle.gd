class_name Obstacle

static var next_id: int = 0


var position: Vector3
var size: Vector3
var model_path: String
var id: int


func _init(pos: Vector3 = Vector3.ZERO, size: Vector3 = Vector3.ONE, path: String = "") -> void:
    id = next_id
    next_id += 1
    position = pos
    size = size
    model_path = path