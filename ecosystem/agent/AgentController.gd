extends Node3D

var agent_data: AgentData

var velocity : Vector3 = Vector3.ZERO

var sound_timer: Timer
@export var audio_player: AudioStreamPlayer3D
var max_sound_interval: float = 5.0
var min_sound_interval: float = 10.0

var sound_clips: Array[AudioStream] = [
	preload("res://audio/agent/song1.mp3"),
	preload("res://audio/agent/song2.mp3"),
]


func _ready() -> void:
	if agent_data == null:
		push_error("AgentController has no AgentData assigned.")
		return
	global_position = Vector3(agent_data.position)
	rotation = agent_data.rotation
	sound_timer = Timer.new()
	sound_timer.wait_time = randf_range(min_sound_interval, max_sound_interval)
	sound_timer.one_shot = true
	sound_timer.timeout.connect(_on_sound_timer_timeout)
	add_child(sound_timer)
	sound_timer.start()


func _process(delta: float) -> void:
	if agent_data == null:
		return
	
	global_position = agent_data.position
	
	var current_basis = global_transform.basis
	var target_basis = Transform3D().looking_at(agent_data.target_position - global_position, Vector3.UP).basis
	global_transform.basis = current_basis.slerp(target_basis, 0.01).orthonormalized()
	agent_data.rotation = rotation

	
func _on_sound_timer_timeout() -> void:
	# Play a random sound
	if audio_player and not audio_player.playing and sound_clips.size() > 0:
		var random_sound = sound_clips[randi() % sound_clips.size()]
		audio_player.stream = random_sound
		audio_player.play()
		print("Agent %d played random sound" % agent_data.id if agent_data else "Unknown agent played sound")
	
	# Set up next random timer
	sound_timer.wait_time = randf_range(min_sound_interval, max_sound_interval)
	sound_timer.start()
