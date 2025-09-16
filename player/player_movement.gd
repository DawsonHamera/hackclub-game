extends Node3D

@export var move_speed: float = 10.0
@export var thrust_speed: float = 30.0
@export var max_speed: float = 20.0
@export var damping: float = 0.5
@export var pitch_speed: float = 1.5
@export var yaw_speed: float = 1.0
@export var roll_speed: float = 2.0
@export var mouse_sensitivity: float = 0.003
@export var turn_snap: float = 4.0

var velocity: Vector3 = Vector3.ZERO
var pitch: float = 0.0
var yaw: float = 180.0

var mouse_captured = true

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouseMotion and mouse_captured:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity

		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))

		rotation.y = yaw
		rotation.x = pitch

	if event is InputEventKey:
		if Input.is_action_just_pressed('cancel'):
			mouse_captured = !mouse_captured
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	var forward = -global_transform.basis.z.normalized()
	
	if Input.is_action_just_pressed("thrust"):
		velocity += forward* thrust_speed
	else:
		var input = Input.get_action_strength("swim_forward") - Input.get_action_strength("swim_backward")
		velocity += forward * input * move_speed * delta

	var speed = velocity.length()
	var new_dir = velocity.normalized().slerp(forward, turn_snap * delta)
	velocity = new_dir * speed
	
	velocity = velocity.lerp(Vector3.ZERO, damping * delta)
	global_transform.origin += velocity * delta
