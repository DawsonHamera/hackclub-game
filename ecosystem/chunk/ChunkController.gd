extends Node3D

var chunk_data: ChunkData

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

func _ready() -> void:
	if chunk_data == null:
		push_error("ChunkController has no ChunkData assigned.")
		return
	global_position = chunk_data.position * ChunkData.CHUNK_SIZE

	if chunk_data.terrain == true:
		var terrain_mesh = MeshInstance3D.new()
		var mesh = preload("res://terrain.glb").duplicate()
		terrain_mesh.mesh = mesh
		terrain_mesh.rotation_degrees = Vector3(-90, 0, 0)
		add_child(terrain_mesh)

func _process(delta: float) -> void:
	update_chunk_agents()
