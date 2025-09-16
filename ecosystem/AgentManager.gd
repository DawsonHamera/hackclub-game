extends Node

var spawn_queue: Dictionary = {}
var loaded_agents: Array = []

func request_spawn_agents_in_chunk(chunk_id: int, agents_array: Array) -> void:
	spawn_queue[chunk_id] = agents_array


func _ready() -> void:
	
	var num_agents = 100
	var area_size = 200.0
	for i in range(num_agents):
		var pos = Vector3(
			randf_range(-area_size, area_size),
			randf_range(-area_size, area_size),
			randf_range(-area_size, area_size),
		) - Vector3(0, 80, -40)  # Start above ground
		var agent = AgentData.new(pos)


func _process(delta: float) -> void:
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
				scene_instance.add_child(agent_instance)
				loaded_agents.append(agent.id)
		else:
			push_error("Chunk with ID %d not found for spawning agents." % chunk_id)       
		
		spawn_queue.erase(chunk_id)
