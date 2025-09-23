extends Node3D

var chunk_data: ChunkData
var chunk_debug_color: Color = Color(0,0,1,0.5)
var show_debug_bounds: bool = false

@onready var label: Label3D = $DebugLabel

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
		for agent in AgentData.agents.values():
			if agent_is_in_chunk(agent):
				agents_in_chunk.append(agent)
		chunk_data.agents = agents_in_chunk

func draw_debug_bounds() -> void:
	# if chunk_data == null or not show_debug_bounds:
	# 	return
	DebugDraw3D.draw_box(chunk_data.position * ChunkData.CHUNK_SIZE, Quaternion.IDENTITY, ChunkData.CHUNK_SIZE * Vector3i.ONE, Color.GREEN)

func _ready() -> void:
	randomize()
	if chunk_data == null:
		push_error("ChunkController has no ChunkData assigned.")
		return
	label.text = "Chunk: %s" % str(chunk_data.position)
	global_position = Vector3(chunk_data.position) * ChunkData.CHUNK_SIZE + (Vector3.ONE * ChunkData.CHUNK_SIZE / 2)

func _process(delta: float) -> void:
	if chunk_data:
		update_chunk_agents()
		draw_debug_bounds()
