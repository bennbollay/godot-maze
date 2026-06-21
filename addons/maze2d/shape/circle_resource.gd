@tool
extends Resource

class_name MazeCircleResource

## Theta that the maze arc starts at
@export_range(0, 360, 0.001, "radians_as_degrees") var min_theta: float = 0
## Theta that the maze arc stops at
@export_range(0, 360, 0.001, "radians_as_degrees") var max_theta: float = 2 * PI
## First level of the maze, if 0 then a circlular room is used as the core
@export_range(0, 100, 1, "suffix:levels") var min_level: int = 0
## Number of levels in the maze
@export_range(0, 100, 1, "suffix:levels") var max_level: int = 10
## The actual length of `r` for each level, used to calculate the radius
@export_range(1, 1000, 0.1, "suffix:units") var level_width: float = 5
## Describes the size of the rooms, in radians, at min_level.  All rooms
## will share the same arclength on all levels.
@export_range(1, 360, 0.001, "radians_as_degrees") var lowest_level_room_theta: float = PI / 8

## Minimum arclength to qualify as an available door, avoiding tiny doors
## when two rooms overlap only by a sliver.[br]
## [br]
## Expressed as a percentage of the arclength of a normal room.
@export_range(0, 100, 0.1, "suffix:%") var minimum_door_size: float = 20
var min_door_sz: float:
	get():
		return minimum_door_size / 100

enum CircleJustify {
	## Expand the rooms on a level to use any left over space
	EXPAND_TO_FIT,
	## Keep rooms the same size and center justify (equal blank space
	## on the boundaries) the rooms.
	CENTER,
}

@export var room_justify: CircleJustify = CircleJustify.EXPAND_TO_FIT
