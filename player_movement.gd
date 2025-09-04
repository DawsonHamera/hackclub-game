extends Node3D

@export var thrust: float = 10.0
@export var max_speed: float = 20.0
@export var damping: float = 0.5
@export var pitch_speed: float = 1.5
@export var yaw_speed: float = 1.0
@export var roll_speed: float = 2.0
@export var mouse_sensitivity: float = 0.003

var velocity: Vector3 = Vector3.ZERO
var pitch: float = 0.0
var yaw: float = 0.0

func _input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity

		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))

		rotation.y = yaw
		rotation.x = pitch

func _physics_process(delta):
	pass
