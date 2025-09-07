extends Node

func load_chunk(position: Vector3, terrain: bool) -> void:
	var chunk = ChunkData.new(position)
	chunk.terrain = terrain
	var chunk_scene = preload("res://ecosystem/chunk/chunk.tscn").instantiate()
	chunk_scene.chunk_data = chunk
	add_child(chunk_scene)

	for agent in chunk.agents:
		var agent_scene = preload("res://ecosystem/agent/agent.tscn").instantiate()
		agent_scene.agent_data = agent
		add_child(agent_scene)

func load_surrounding_chunks(center: Vector3i) -> void:
	for x in range(-1, 2):
		for y in range(0, 3):
			for z in range(-1, 2):
				var chunk_pos = center + Vector3i(x, y, z)
				var terrain = false
				if y == 0:
					terrain = true
				load_chunk(chunk_pos, terrain)
				print("Loaded chunk at: ", chunk_pos, " with terrain: ", terrain)

func _ready() -> void:
	print("ChunkManager ready")
	load_surrounding_chunks(Vector3i.ZERO)
