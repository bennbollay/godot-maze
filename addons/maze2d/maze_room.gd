@abstract
extends Node
class_name MazeRoom

var maze: MazeShape
var visited: bool = false

func _init(maze_: MazeShape) -> void:
	maze = maze_

@abstract func walls() -> Array[int]
@abstract func open_wall_between(room: MazeRoom)
@abstract func get_unvisited_neighbors() -> Array
