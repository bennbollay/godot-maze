extends Node

class_name MazeAlgoRecursiveBacktracker

## Generate a maze using the Recursive Backtracker algorithm.[br]
## [br]
## Returns [code]true[/true] if all rooms were used, but if there's
## locked doors and thus inaccessible rooms, will return false.
static func generate(maze: MazeShape, starting_room: MazeRoom, maze_seed: int = 0) -> bool:
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
			if room_stack.size() == 0:
				# Some rooms and configurations do not have full accessibility when
				# locked doors are used. Return false to indicate that not all rooms
				# were used.
				return false
				
			walker = room_stack.pop_back()
			continue

		var next_room := neighbors[rand.randi_range(0, neighbors.size() - 1)] as MazeRoom
		walker.open_wall_between(next_room)
		room_stack.push_back(walker)
		walker = next_room

	return true
