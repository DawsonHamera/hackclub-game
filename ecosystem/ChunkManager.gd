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

var prev_chunk_agents: Dictionary = {}

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
	print("Chunk loading thread running...")
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

func update_agents_in_chunks() -> void:
	for chunk_pos in loaded_chunks.keys():
		var chunk = loaded_chunks[chunk_pos]
		if chunk and is_instance_valid(chunk):
			var chunk_data = chunk.chunk_data
			if chunk_data:
				var prev_agents = prev_chunk_agents.get(chunk_pos, [])
				
				if chunk_data.agents > prev_agents:
					AgentManager.request_spawn_agents_in_chunk(chunk_data.id, chunk_data.agents)

				elif chunk_data.agents < prev_agents:
					for agent in prev_agents:
						if not agent in chunk_data.agents:
							AgentManager.request_despawn_agent(agent.id)

				prev_chunk_agents[chunk_pos] = chunk.chunk_data.agents
		else:
			print("Invalid chunk at pos: ", chunk_pos)



func create_chunk(position: Vector3i, terrain: bool) -> void:
	var chunkData = ChunkData.new(position)
	add_child(chunkData.scene_instance)
	chunk_load_queue.append(chunkData)
	semaphore.post()

func create_surrounding_chunks(center: Vector3i, radius: int) -> void:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				var chunk_pos = center + Vector3i(x, y, z)

				if loaded_chunks.has(chunk_pos):
					continue
				
				# Check load queue
				var already_queued = false
				for queued_chunk in chunk_load_queue:
					if queued_chunk.position == chunk_pos:
						already_queued = true
						break
					
				# Check render queue
				if not already_queued:
					for rendered_chunk in chunk_render_queue:
						if rendered_chunk.position == chunk_pos:
							already_queued = true
							break
				
				if already_queued:
					continue 

				var terrain = false
				if chunk_pos.y == 0:
					terrain = true
				create_chunk(chunk_pos, terrain)

func clear_unloaded_chunks(center: Vector3i, radius: int) -> void:
	var chunks_to_remove = []

	for chunk_pos in loaded_chunks.keys():
		var distance = max(abs(chunk_pos.x - center.x), abs(chunk_pos.y - center.y), abs(chunk_pos.z - center.z))
		if distance > radius:
			chunks_to_remove.append(chunk_pos)

	for chunk_pos in chunks_to_remove:
		var chunk = loaded_chunks[chunk_pos]
		if chunk and chunk.get_parent() == self:
			remove_child(chunk)
			chunk.queue_free()
		for agent in chunk.chunk_data.agents:
			AgentManager.request_despawn_agent(agent.id)
		loaded_chunks.erase(chunk_pos)


func get_player_chunk() -> Vector3i:
	var player = get_node("/root/Main/Player")
	if player == null:
		return Vector3.ZERO
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
	create_surrounding_chunks(player_chunk, 1)
	print("Initial chunks created around player at: ", player_chunk)
	

func transform_relative_to_chunk(pos: Vector3i, local_pos: Vector3) -> Vector3:
	return Vector3(
		local_pos.x + pos.x * ChunkData.CHUNK_SIZE,
		local_pos.y + pos.y * ChunkData.CHUNK_SIZE,
		local_pos.z + pos.z * ChunkData.CHUNK_SIZE,
	)

func render_chunks() -> void:
	var processed_chunks = []
	var total_obstacles = 0
	for chunkData in chunk_render_queue:
		for obstacle in chunkData.obstacles:
			var m = resources[obstacle.model_path].instantiate() if obstacle.model_path in resources else null
			m.position = obstacle.position
			# m.scale = obstacle.size
			chunkData.scene_instance.add_child(m)
			total_obstacles += 1
		loaded_chunks[chunkData.position] = chunkData.scene_instance
		processed_chunks.append(chunkData)
	
	# print("Rendered %d chunks with a total of %d obstacles." % [processed_chunks.size(), total_obstacles])
	for chunk in processed_chunks:
		chunk_render_queue.erase(chunk)

func _process(delta: float) -> void:
	player_chunk = get_player_chunk()

	if player_chunk != player_chunk_prev or first_frame:
		print("first frame - calling render_chunks" if first_frame else "player moved - calling render_chunks")
		first_frame = false
		mutex.lock()
		# print("Clearing unloaded chunks...")
		clear_unloaded_chunks(player_chunk, 1)
		# print("Creating surrounding chunks...")
		create_surrounding_chunks(player_chunk, 1)
		# debug_chunks()
		mutex.unlock()
	render_chunks()

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
