extends RefCounted
class_name MazeSquare

class Room extends MazeRoom:
	var x: int
	var y: int
	
	#    0
	#  1   2
	#    3
	const recip_wall: Array[int] = [3, 2, 1, 0]
	var _walls: Array = [null, null, null, null]

	func _init(maze_: MazeShape, x_: int, y_: int) -> void:
		super(maze_)
		x = x_
		y = y_
	
	
	func walls() -> Array:
		return _walls
	
	
	func is_wall(i: int) -> int:
		return 1 if _walls[i] == null else 0
		
	# Match the example
	func walls_id() -> int:
		# WSEN
		return is_wall(1) << 3 | is_wall(3) << 2 | is_wall(2) << 1 | is_wall(0)

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
			sqm.room(x, y - 1),
			sqm.room(x - 1, y),
			sqm.room(x + 1, y),
			sqm.room(x, y + 1)
		].filter(func (s) -> bool: return is_instance_valid(s) and not s.visited)

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
		'╬', '╦', '╣', '╗',
		'╩', '═', '╝', '╛',
		'╠', '╔', '║', '╓',
		'╚', '╘', '╜', '╳',
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
	
	func print_console():
		print("\n".join(to_str()))

	func get_line_width(font: Font, ln: String) -> Vector2:
		return font.get_string_size(ln)
		
	func print_editor(scene: Node2D, where: Rect2):
		if where.size.x == 0 or where.size.y == 0:
			return
			
		var LEGACY_COMPUTING_FONT := load("uid://b2itbw3sn4cnx")
		var font := LEGACY_COMPUTING_FONT
		
		# Scale the font to fit within the rect
		var lns := to_str()
		var w := get_line_width(font, lns[0]).x
		var h := get_line_width(font, lns[0]).y * lns.size()
		var new_size = round(min(where.size.x / w, where.size.y / h) * 16)
		
		scene.draw_multiline_string(font, where.position, "\n" + "\n".join(lns), HORIZONTAL_ALIGNMENT_LEFT, -1, new_size)
