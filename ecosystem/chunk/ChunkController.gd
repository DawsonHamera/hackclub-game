extends Node3D

var chunk_data: ChunkData
var chunk_debug_color: Color = Color(0,0,1,0.5)
var show_debug_bounds: bool = false


func agent_is_in_chunk(agent: AgentData) -> bool:
	var chunk_min = chunk_data.position * ChunkData.CHUNK_SIZE
	var chunk_max = chunk_min + Vector3i.ONE * ChunkData.CHUNK_SIZE

	return (agent.position.x >= chunk_min.x and agent.position.x < chunk_max.x and
			agent.position.y >= chunk_min.y and agent.position.y < chunk_max.y and
			agent.position.z >= chunk_min.z and agent.position.z < chunk_max.z)

func update_chunk_agents() ->  void:
		if chunk_data == null:
			return
		var agents_in_chunk = []
		for agent in chunk_data.agents:
			if agent_is_in_chunk(agent):
				agents_in_chunk.append(agent)
		chunk_data.agents = agents_in_chunk

func draw_debug_bounds() -> void:
	if chunk_data == null or not show_debug_bounds:
		return
	DebugDraw3D.draw_box(chunk_data.position * ChunkData.CHUNK_SIZE, Quaternion.IDENTITY, ChunkData.CHUNK_SIZE * Vector3i.ONE, Color.GREEN)

func chunk_file_from_pos(idx: Vector3i) -> String:
	return "%schunk_%d_%d_%d.fbx" % ["res://chunks/", idx.x, idx.y, idx.z]

func chunk_exists(idx: Vector3i) -> bool:
	var path = chunk_file_from_pos(idx)
	return ResourceLoader.exists(path)

func _ready() -> void:
	if chunk_data == null:
		push_error("ChunkController has no ChunkData assigned.")
		return
	global_position = Vector3(chunk_data.position) * ChunkData.CHUNK_SIZE + (Vector3.ONE * ChunkData.CHUNK_SIZE / 2)

	var path = chunk_file_from_pos(chunk_data.position)
	if chunk_exists(chunk_data.position):
		var scene = ResourceLoader.load(path)
		add_child(scene.instantiate())

func _process(delta: float) -> void:
	update_chunk_agents()
	# draw_debug_bounds()
