extends RefCounted

class_name MazeSquare

class Room extends MazeRoom:
	var x: int
	var y: int

	enum {
		N = 0,
		W = 1,
		E = 2,
		S = 3
	}
	#    0
	#  1   2
	#    3
	const recip_wall: Array[int] = [S, E, W, N]
	var _walls: Array = [null, null, null, null]
	var _locked_walls: Array = [false, false, false, false]


	func _init(maze_: MazeShape, x_: int, y_: int) -> void:
		super(maze_)
		x = x_
		y = y_


	func walls() -> Array:
		return _walls

	func doors() -> Array:
		return [N, S, E, W]
		
	func dir_to_vec(dir: int) -> Vector2i:
		match dir:
			N:
				return Vector2i(x, y - 1)
			W:
				return Vector2i(x - 1, y)
			E:
				return Vector2i(x + 1, y)
			S:
				return Vector2i(x, y + 1)
		assert(false)
		return Vector2i.ZERO

	## Lock N, S, E, or W to be untraversable.
	func lock_door(dir: int):
		_locked_walls[dir] = true
		var v := dir_to_vec(dir)
		var sqm: Shape = maze
		var other_room := sqm.room(v.x, v.y)
		if not other_room:
			return
		other_room._locked_walls[recip_wall[dir]] = true

	func is_wall(i: int) -> int:
		return 1 if _walls[i] == null or _locked_walls[i] else 0


	# Match the example
	func walls_id() -> int:
		# WSEN
		return is_wall(W) << 3 | is_wall(S) << 2 | is_wall(E) << 1 | is_wall(N)


	## Joins two rooms, even if they're on separate Mazes
	func join_rooms(room, wall: int):
		_walls[wall] = room
		room._walls[recip_wall[wall]] = self


	func open_wall_between(room: MazeRoom):
		var sqr: Room = room

		if sqr.x < x:
			assert(y == sqr.y)
			assert(_walls[1] == null)
			_walls[1] = room
			room._walls[2] = self
		elif sqr.x > x:
			assert(y == sqr.y)
			assert(_walls[2] == null)
			_walls[2] = room
			room._walls[1] = self
		else:
			assert(x == sqr.x)
			if sqr.y < y:
				assert(_walls[0] == null)
				_walls[0] = room
				room._walls[3] = self
			else:
				assert(_walls[3] == null)
				_walls[3] = room
				room._walls[0] = self


	func get_unvisited_neighbors() -> Array:
		var sqm: Shape = maze
		return [
			sqm.room(x, y - 1) if not _locked_walls[N] else null,
			sqm.room(x - 1, y) if not _locked_walls[W] else null,
			sqm.room(x + 1, y) if not _locked_walls[E] else null,
			sqm.room(x, y + 1) if not _locked_walls[S] else null,
		].filter(func(r: Room) -> bool:
			return is_instance_valid(r) and not r.visited
		)


class Shape extends MazeShape:
	var rooms: Array[Room]
	var width: int
	var height: int


	func _init(width_: int, height_: int):
		width = width_
		height = height_
		rooms = []
		rooms.resize(width * height)
		for i in range(width * height):
			rooms[i] = Room.new(self, idx(i).x, idx(i).y)


	func id(x: int, y: int) -> int:
		return x + y * width


	func idx(i: int) -> Vector2i:
		return Vector2(i % width, floor(i as float / width))


	func room(x: int, y: int) -> Room:
		if x < 0 or x > width - 1:
			return null
		if y < 0 or y > height - 1:
			return null
		return rooms[id(x, y)] as Room


	func size() -> int:
		return width * height


	const CHARSET_CONSOLE: Array = [
		'╬',
		'╦',
		'╣',
		'╗',
		'╩',
		'═',
		'╝',
		'╛',
		'╠',
		'╔',
		'║',
		'╓',
		'╚',
		'╘',
		'╜',
		'╳',
	]


	func to_str(chs: Array = CHARSET_CONSOLE) -> Array[String]:
		var lns: Array[String] = []
		for y in range(0, height):
			var ln: String = ''
			for x in range(0, width):
				var r = room(x, y)
				var wid := r.walls_id()
				ln += chs[wid]
			lns.push_back(ln)

		return lns


	func get_line_width(font: Font, ln: String) -> Vector2:
		return font.get_string_size(ln)
