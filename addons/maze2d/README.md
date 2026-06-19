# Godot 4 2D Maze Implementation

This project creates a variety of ways of creating differently-shaped 2D mazes.

# Video Example

# Usage

Open the [addons/maze2d/test/test_maze.tscn](https://github.com/bennbollay/godot-maze/tree/main/addons/maze2d/test) scene for examples.

## Create a square maze

```gdscript
var square_maze: MazeSquare.Shape = MazeSquare.Shape.new(square_width, square_height)
MazeAlgoRecursiveBacktracker.generate(square_maze, square_maze.room(0, 0), maze_random_seed)
```

## Create a circular maze

```gdscript
var circle_maze: MazeCircle.Shape = MazeCircle.Shape.new(circle_resource)
circle_maze.generate()

MazeAlgoRecursiveBacktracker.generate(circle_maze, circle_maze.room(0, 0), maze_random_seed)
```

## Drawing the maze a canvas

Both square and circular mazes support being drawn to a canvas on the screen. While this is not the most commonly
expected way of using them, it's extremely useful for debugging.

```gdscript
# Print a square maze to the $Maze canvas.
var rect := shape_to_rect($Maze.shape as RectangleShape2D, $Maze.global_position)
MazeSquarePrint.canvas($Maze, sm, rect)

# Or for a circular maze:
var rect := shape_to_rect($Maze2.shape as RectangleShape2D, $Maze2.global_position)
MazeCirclePrint.canvas($Maze2, cm, rect, show_room_labels, show_boundary)
```

In addition to a `canvas` endpoint, those objects also offer a `console` option for logging details about the maze to
the console itself.

_NOTE:_ There isn't any good font for drawing a square maze, so the characters used might be confusing - the maze is the
inside part of the small close-together lines, not the space between the double-lines.

## Supported Algorithms

Currently only the [Recursive Backtracker](https://en.wikipedia.org/wiki/Maze_generation_algorithm#Randomized_depth-first_search) algorithm is supported, but the general design is easy enough that additional algorithms can be added. If there's algorithm you'd like, file a ticket!
