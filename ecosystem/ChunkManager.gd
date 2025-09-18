extends Node

var loaded_chunks: Dictionary = {}
var chunk_load_queue: Array = []
var chunk_render_queue: Array = []

var resources: Dictionary = {}

var player_chunk_prev: Vector3i = Vector3i.ZERO
var player_chunk: Vector3i = Vector3i.ZERO

var mutex: Mutex
var semaphore: Semaphore
var thread: Thread
var exit_render_thread: bool = false

var first_frame: bool = true

func load_chunk_resources(chunkData: ChunkData) -> Dictionary:
	if chunkData == null:
		return {}

	var resources_to_load = []
	for obstacle in chunkData.obstacles:
		if obstacle.model_path != "" and ResourceLoader.exists(obstacle.model_path) and not obstacle.model_path in resources_to_load and not obstacle.model_path in resources:
			resources_to_load.append(obstacle.model_path)

	# print("Loading resources for chunk ID %d: %s" % [chunkData.id, str(resources_to_load)])
	if resources_to_load.size() > 0:
		for resource_path in resources_to_load:
			resources[resource_path] = ResourceLoader.load(resource_path)

			print("Loaded new resource for chunk ID %d: %s - %s" % [chunkData.id, resource_path, str(resources[resource_path])])
	return resources


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
			load_chunk_resources(chunkData)
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
	

func transform_relative_to_chunk(pos: Vector3i, local_pos: Vector3) -> Vector3:
	return Vector3(
		local_pos.x + pos.x * ChunkData.CHUNK_SIZE,
		local_pos.y + pos.y * ChunkData.CHUNK_SIZE,
		local_pos.z + pos.z * ChunkData.CHUNK_SIZE,
	)

func render_chunks() -> void:
	var processed_chunks = []
	for chunkData in chunk_render_queue:
		for obstacle in chunkData.obstacles:
			var m = resources[obstacle.model_path].instantiate() if obstacle.model_path in resources else null
			m.position = obstacle.position
			# m.scale = obstacle.size
			chunkData.scene_instance.add_child(m)
			print("Added obstacle ID %d to chunk ID %d at position %s" % [obstacle.id, chunkData.id, str(obstacle.position)])
		loaded_chunks[chunkData.position] = chunkData.scene_instance
		processed_chunks.append(chunkData)

	for chunk in processed_chunks:
		chunk_render_queue.erase(chunk)

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
