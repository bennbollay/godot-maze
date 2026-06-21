@tool
extends Node2D

var sm: MazeSquare.Shape
var cm: MazeCircle.Shape

signal on_new_maze_seed()

@export var monitor: bool = false:
	set(v):
		if v == monitor or not is_node_ready():
			return

		monitor = v
		if not monitor and monitor_timer:
			monitor_timer.queue_free()
			monitor_timer = null
			return

		if monitor and not monitor_timer:
			monitor_timer = Timer.new()
			add_child(monitor_timer)
			monitor_timer.timeout.connect(
				func():
					recreate_sm()
					recreate_cm()

					$Maze.queue_redraw()
					$Maze2.queue_redraw()
					queue_redraw()
			)
			monitor_timer.start(0.1)

var monitor_timer: Timer

## Set to control the maze generation algorithm random seed
@export var maze_seed: int = 0:
	set(i):
		maze_seed = i
		on_new_maze_seed.emit()

## Randomly lock some rooms in each maze for demonstration purposes
@export var lock_rooms: int = 0:
	set(i):
		lock_rooms = i
		on_new_maze_seed.emit()

@export_group("Square")
## Number of "rooms" wide
@export var square_width: int = 10:
	set(i):
		square_width = i
		on_new_maze_seed.emit()
## Number of "rooms" high
@export var square_height: int = 10:
	set(i):
		square_height = i
		on_new_maze_seed.emit()

@export_group("Circle")
## Show some text labels for each room for diagnostic purposes
@export var show_room_labels: bool = true
## Highlight the boundary around the maze
@export var show_boundary: bool = true

## Instructions on the shape of the maze, and the size and position
## of rooms within the maze.
@export var circle_resource: MazeCircleResource


func shape_to_rect(shape: RectangleShape2D, pos: Vector2) -> Rect2:
	var rect := shape.get_rect()
	rect.position += pos
	return rect


## Create an example circular maze.
func recreate_cm():
	var rand := RandomNumberGenerator.new()
	rand.seed = maze_seed

	cm = MazeCircle.Shape.new(circle_resource)
	cm.generate()
	
	# Demonstrate excluding some random rooms from the maze
	for i in range(lock_rooms):
		var l: int = rand.randi_range(cm.min_level + 1, cm.max_level - 1)
		var rooms_on_level: Array = cm.rooms_by_l(l)
		var room: MazeCircle.Room = rooms_on_level[rand.randi_range(0, rooms_on_level.size() - 1)]
		for door: MazeCircle.Door in room.doors():
			door.locked = true
		

	MazeAlgoRecursiveBacktracker.generate(cm, cm.room(0, 0), maze_seed)


## Create an example square maze.
func recreate_sm():
	var rand := RandomNumberGenerator.new()
	rand.seed = maze_seed

	sm = MazeSquare.Shape.new(square_width, square_height)

	# Demonstrate excluding some random rooms from the maze
	for i in range(lock_rooms):
		var x: int = rand.randi_range(0, sm.width - 1)
		var y: int = rand.randi_range(0, sm.height - 1)
		
		# Lock all of the doors to this room.
		for door in sm.room(x, y).doors():
			sm.room(x, y).lock_door(door)


	MazeAlgoRecursiveBacktracker.generate(sm, sm.room(0, 0), maze_seed)


func _ready() -> void:
	on_new_maze_seed.connect(
		func():
			recreate_sm()
			recreate_cm()
			$Maze.queue_redraw()
			$Maze2.queue_redraw()
	)

	recreate_sm()
	recreate_cm()

	$Maze.draw.connect(
		func():
			var rect := shape_to_rect($Maze.shape as RectangleShape2D, $Maze.global_position)
			MazeSquarePrint.canvas($Maze, sm, rect)
	)
	$Maze2.draw.connect(
		func():
			var rect := shape_to_rect($Maze2.shape as RectangleShape2D, $Maze2.global_position)
			MazeCirclePrint.canvas($Maze2, cm, rect, show_room_labels, show_boundary)
	)


func _process(delta: float) -> void:
	$Maze.queue_redraw()
	$Maze2.queue_redraw()
