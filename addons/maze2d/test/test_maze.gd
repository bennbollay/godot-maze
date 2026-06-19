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
	cm = MazeCircle.Shape.new(circle_resource)
	cm.generate()

	MazeAlgoRecursiveBacktracker.generate(cm, cm.room(0, 0), maze_seed)


## Create an example square maze.
func recreate_sm():
	sm = MazeSquare.Shape.new(square_width, square_height)
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
