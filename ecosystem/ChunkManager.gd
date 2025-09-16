extends Node

var loaded_chunks: Dictionary = {}
var chunk_load_queue: Array = []
var chunk_render_queue: Array = []

var player_chunk_prev: Vector3i = Vector3i.ZERO
var player_chunk: Vector3i = Vector3i.ZERO

var mutex: Mutex
var semaphore: Semaphore
var thread: Thread
var exit_render_thread: bool = false

var first_frame: bool = true

func chunk_terrain_exists(idx: Vector3i) -> bool:
	var path = chunk_file_from_pos(idx)
	if ResourceLoader.exists(path):
		print("Chunk terrain exists at: ", idx)
	return ResourceLoader.exists(path)

func chunk_file_from_pos(idx: Vector3i) -> String:
	# var offset = Vector3i(5, 3, -3)  # For debugging, moves chunk around so I don't have to move player
	# var offset = Vector3i(5,-13, -3)
	var offset = Vector3i(5,4,-20)
	return "%schunk_%d_%d_%d.fbx" % ["res://chunks/", idx.x + offset.x, idx.y + offset.y, idx.z + offset.z]


func load_chunk(chunkData: ChunkData) -> PackedScene:
	if chunkData == null:
		return null
	if chunk_terrain_exists(chunkData.position):
		var path = chunk_file_from_pos(chunkData.position)
		var terrain = ResourceLoader.load(path)
		return terrain
	else:
		return null


func load_chunks_thread() -> void:
	while true:
		semaphore.wait()
		mutex.lock()
		var should_exit = exit_render_thread
		var chunk_load_queue_local = chunk_load_queue.duplicate()
		mutex.unlock()

		if should_exit:
			break

		for chunkData in chunk_load_queue_local:
			mutex.lock()
			var terrain = load_chunk(chunkData)
			if terrain:
				chunkData.terrain = terrain		
			
			chunk_render_queue.append(chunkData)
			chunk_load_queue.erase(chunkData)
		mutex.unlock()


func scan_chunk_for_agents(chunk_pos: Vector3i) -> Array:
	var agents_in_chunk = []
	for agent in AgentData.agents.values():
		var chunk_min = chunk_pos * ChunkData.CHUNK_SIZE
		var chunk_max = chunk_min + Vector3i.ONE * ChunkData.CHUNK_SIZE

		if (agent.position.x >= chunk_min.x and agent.position.x < chunk_max.x and
			agent.position.y >= chunk_min.y and agent.position.y < chunk_max.y and
			agent.position.z >= chunk_min.z and agent.position.z < chunk_max.z):
			agents_in_chunk.append(agent)
	return agents_in_chunk

func update_agents_in_chunks() -> void:
	for chunk_pos in loaded_chunks.keys():
		var chunk = loaded_chunks[chunk_pos]
		if chunk and is_instance_valid(chunk):
			var chunk_data = chunk.chunk_data
			if chunk_data:
				chunk_data.agents = scan_chunk_for_agents(chunk_pos)
				AgentManager.request_spawn_agents_in_chunk(chunk_data.id, chunk_data.agents)



func create_chunk(position: Vector3i, terrain: bool) -> void:
	var chunkData = ChunkData.new(position)
	add_child(chunkData.scene_instance)
	chunk_load_queue.append(chunkData)
	semaphore.post()

func create_surrounding_chunks(center: Vector3i, radius: int) -> void:
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
				create_chunk(chunk_pos, terrain)

func clear_unloaded_chunks(center: Vector3i, radius: int) -> void:
	for i in loaded_chunks.keys():
		if i.distance_to(center) > radius:
			# print("Removing chunk at: ", i)
			var chunk = loaded_chunks[i]
			if chunk and chunk.get_parent() == self:
				remove_child(chunk)
				chunk.queue_free()
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

func debug_chunks() -> void:
	for chunk_pos in loaded_chunks.keys():
		var chunk = loaded_chunks[chunk_pos]
		if chunk and is_instance_valid(chunk):
			var debug_label = chunk.get_node("DebugLabel")

			if player_chunk == chunk_pos:
				chunk.show_debug_bounds = true
			else:
				chunk.show_debug_bounds = false
				
			debug_label.text = "Pos: " + str(chunk_pos) + " Dis: " + str(chunk_pos.distance_to(player_chunk))

func _ready() -> void:
	print("ChunkManager ready")

	mutex = Mutex.new()
	semaphore = Semaphore.new()
	thread = Thread.new()
	exit_render_thread = false
	thread.start(load_chunks_thread)

	print("ChunkManager rendering thread started")

	create_surrounding_chunks(get_player_chunk(), 2)
	

func render_chunks() -> void:
	for chunkData in chunk_render_queue:
		var terrain = chunkData.terrain
		if terrain:
			chunkData.scene_instance.add_child(terrain.instantiate())
			chunk_render_queue.erase(chunkData)

		loaded_chunks[chunkData.position] = chunkData.scene_instance

func _process(delta: float) -> void:
	player_chunk = get_player_chunk()

	if player_chunk != player_chunk_prev or first_frame:
		first_frame = false
		mutex.lock()
		create_surrounding_chunks(player_chunk, 2)
		# clear_unloaded_chunks(player_chunk, 1)
		render_chunks()
		# debug_chunks()
		mutex.unlock()

	update_agents_in_chunks()

	player_chunk_prev = player_chunk

	

func _exit_tree() -> void:
	mutex.lock()
	exit_render_thread = true
	mutex.unlock()

	semaphore.post()

	if thread.is_active():
		thread.wait_to_finish()
		print("ChunkManager rendering thread stopped")
