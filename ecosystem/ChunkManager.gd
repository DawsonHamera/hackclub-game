extends Node

var loaded_chunks: Dictionary = {}
var current_player_chunk: Vector3i = Vector3i.ZERO
var new_player_chunk: Vector3i = Vector3i.ZERO

func load_chunk(position: Vector3i, terrain: bool) -> void:
	var chunk = ChunkData.new(position)
	chunk.terrain = terrain
	var chunk_scene = preload("res://ecosystem/chunk/chunk.tscn").instantiate()
	chunk_scene.chunk_data = chunk
	loaded_chunks[position] = chunk_scene
	add_child(chunk_scene)

	for agent in chunk.agents:
		var agent_scene = preload("res://ecosystem/agent/agent.tscn").instantiate()
		agent_scene.agent_data = agent
		add_child(agent_scene)

func load_surrounding_chunks(center: Vector3i, radius: int) -> void:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				if loaded_chunks.has(center + Vector3i(x, y, z)):
					continue
				var chunk_pos = center + Vector3i(x, y, z)
				var terrain = false
				if chunk_pos.y == 0:
					terrain = true
				# elif chunk_pos.y < 0:
				# 	continue
				load_chunk(chunk_pos, terrain)

func clear_unloaded_chunks(center: Vector3i, radius: int) -> void:
	for i in loaded_chunks.keys():
		if i.distance_to(center) > radius:
			# print("Removing chunk at: ", i)
			var chunk_scene = loaded_chunks[i]
			remove_child(chunk_scene)
			chunk_scene.queue_free()
			loaded_chunks.erase(i)
			
		

func get_player_chunk() -> Vector3i:
	var player = get_node("/root/Main/Player")
	if player == null:
		return Vector3i.ZERO
	var player_pos = player.global_transform.origin

	var chunk_x: int
	var chunk_y: int
	var chunk_z: int

	if player_pos.x < 0:
		chunk_x = ceil(abs(player_pos.x) / ChunkData.CHUNK_SIZE) * -1
	else:
		chunk_x = int(player_pos.x) / ChunkData.CHUNK_SIZE

	if player_pos.y < 0:
		chunk_y = ceil(abs(player_pos.y) / ChunkData.CHUNK_SIZE) * -1
	else:
		chunk_y = int(player_pos.y) / ChunkData.CHUNK_SIZE

	if player_pos.z < 0:
		chunk_z = ceil(abs(player_pos.z) / ChunkData.CHUNK_SIZE) * -1
	else:
		chunk_z = int(player_pos.z) / ChunkData.CHUNK_SIZE

	# print("Player chunk: ", Vector3i(chunk_x, chunk_y, chunk_z), " Player pos: ", player_pos, " Chunk size: ", ChunkData.CHUNK_SIZE)
	return Vector3i(chunk_x, chunk_y, chunk_z)

func debug_chunks(new_player_chunk) -> void:
	for chunk_pos in loaded_chunks.keys():
		var chunk_scene = loaded_chunks[chunk_pos]
		var debug_label = chunk_scene.get_node("DebugLabel")

		if new_player_chunk == chunk_pos:
			chunk_scene.show_debug_bounds = true
		else:
			chunk_scene.show_debug_bounds = false
			
		debug_label.text = "Pos: " + str(chunk_pos) + " Dis: " + str(chunk_pos.distance_to(new_player_chunk))


func _ready() -> void:
	print("ChunkManager ready")
	load_surrounding_chunks(get_player_chunk(), 2)


func _process(delta: float) -> void:
	var new_player_chunk = get_player_chunk()
	if new_player_chunk != current_player_chunk:
		clear_unloaded_chunks(new_player_chunk, 1)
		load_surrounding_chunks(new_player_chunk, 2)

		debug_chunks(new_player_chunk)
	current_player_chunk = new_player_chunk
