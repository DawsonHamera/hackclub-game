extends Node

var spawn_queue: Dictionary = {}
var loaded_agents: Array = []

func request_spawn_agents_in_chunk(chunk_id: int, agents_array: Array) -> void:
	spawn_queue[chunk_id] = agents_array
	# print("Requested spawn of %d agents in chunk %d" % [agents_array.size(), chunk_id])


func request_despawn_agent(agent_id: int) -> void:
	if agent_id in loaded_agents and AgentData.agents[agent_id].scene_instance != null:
		remove_child(AgentData.agents[agent_id].scene_instance)
		AgentData.agents[agent_id].scene_instance.queue_free()
		AgentData.agents[agent_id].scene_instance = null
		AgentData.agents[agent_id].is_loaded = false
		loaded_agents.erase(agent_id)
		print("Despawned agent %d" % agent_id)
	else:
		push_warning("Agent ID %d not found in loaded agents for despawn." % agent_id)	

func update_agents(delta: float) -> void:
	for agent_id in loaded_agents:
		var agent = AgentData.agents.get(agent_id, null)
		agent.update_agent(delta)

func _ready() -> void:
	print("AgentManager ready")

	# Temporarily spawn some agents
	var num_agents = 50
	var area_size = 200.0
	for i in range(num_agents):
		var pos = Vector3(
			randf_range(-area_size, area_size),
			randf_range(-area_size, area_size),
			randf_range(-area_size, area_size),
		) - Vector3(0, 80, -40)
		var agent = AgentData.new(pos)
	print("Created %d agents" % num_agents)

func load_new_agents() -> void:
	for chunk_id in spawn_queue.keys():
		var agents = spawn_queue[chunk_id]
		var chunk = ChunkData.chunks.get(chunk_id, null)
		var scene_instance = chunk.scene_instance if chunk else null
		if scene_instance:
			for agent in agents:
				if agent.id in loaded_agents:
					continue
				var agent_instance = load("res://ecosystem/agent/agent.tscn").instantiate()
				agent_instance.agent_data = agent
				agent_instance.agent_data.scene_instance = agent_instance
				scene_instance.add_child(agent_instance)
				loaded_agents.append(agent.id)
				agent.is_loaded = true
				print("Spawned agent %d in chunk %d" % [agent.id, chunk_id])
		else:
			push_error("Chunk with ID %d not found for spawning agents." % chunk_id)       
		
		spawn_queue.erase(chunk_id)

func _process(delta: float) -> void:
	load_new_agents()
	update_agents(delta)
