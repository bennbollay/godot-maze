extends Node
class_name MazeAlgoRecursiveBacktracker

static func generate(maze: MazeShape, starting_room: MazeRoom, maze_seed: int = 0):
	var rand := RandomNumberGenerator.new()
	if maze_seed > 0:
		rand.seed = maze_seed

	var walker: MazeRoom = starting_room
	var room_stack: Array[MazeRoom] = []
	
	var cnt := maze.size()
	while cnt > 0:
		if not walker.visited:
			walker.visited = true
			cnt -= 1
		
		var neighbors := walker.get_unvisited_neighbors()
		
		if neighbors.size() == 0:
			assert(room_stack.size() > 1)
			walker = room_stack.pop_back()
			continue
		
		var next_room := neighbors[rand.randi_range(0, neighbors.size() - 1)] as MazeRoom
		walker.open_wall_between(next_room)
		room_stack.push_back(walker)
		walker = next_room
