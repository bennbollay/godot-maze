extends RefCounted

class_name MazeCircle

const EPSILON = 0.001


class Door:
	enum DoorType {
		DOOR_ARC,
		DOOR_RADIAL,
	}

	var _room1_ref: WeakRef
	var _room2_ref: WeakRef
	var room1: Room:
		get(): return _room1_ref.get_ref()
		set(r): _room1_ref = weakref(r)
			
	var room2: Room:
		get(): return null if not _room2_ref else _room2_ref.get_ref()
		set(r): _room2_ref = weakref(r)
			
	var open: bool = false
	
	## Can be used to exclude a room from the pathfinding
	var _locked: bool = false
	var locked: bool = false:
		set(v):
			_locked = v
			room2.door_to(room1)._locked = _locked

		get():
			return _locked

	var _type: DoorType
	var l: int = 0
	var radius: float:
		get():
			return l * room1.M().level_width

	# Radial parameters
	var t: float = 0

	# Arc parameters
	var t0: float = 0
	var t1: float = 0


	## From room1's perspective
	func _init(rm1: Room, rm2: Room) -> void:
		room1 = rm1
		room2 = rm2

		if rm1.l == rm2.l:
			_type = DoorType.DOOR_RADIAL
			if rm1.t < rm2.t:
				t = (rm2.t - rm1.t) / 2 + rm1.t
			else:
				t = (rm1.t - rm2.t) / 2 + rm2.t
			l = rm1.l
		else:
			_type = DoorType.DOOR_ARC
			l = max(rm1.l, rm2.l)
			t0 = max(rm1.t0(), rm2.t0())
			t1 = min(rm1.t1(), rm2.t1())

	func arclength() -> float:
		assert(t1 > t0)
		return radius * (t1 - t0)

	func to_str():
		var s = " {" if not open else " |"
		if _type == DoorType.DOOR_ARC:
			s += "%d %.2f°->%.2f°: %s::%s" % [
				l,
				rad_to_deg(t0),
				rad_to_deg(t1),
				room1.to_str(),
				room2.to_str(),
			]
		if _type == DoorType.DOOR_RADIAL:
			s += "%.2f° %d: %s::%s" % [
				rad_to_deg(t),
				l,
				room1.to_str(),
				room2.to_str(),
			]
		s += "} " if not open else "| "
		return s


class RadialWall extends Door:
	func _init(rm1: Room, level: int, theta: float) -> void:
		_type = DoorType.DOOR_RADIAL
		room1 = rm1
		l = level
		t = theta


	func to_str():
		return " {%.2f° %d: %s::} " % [
			rad_to_deg(t),
			l,
			room1.to_str(),
		]


class ArcWall extends Door:
	func _init(rm1: Room, level: int, theta0: float, theta1: float) -> void:
		_type = DoorType.DOOR_ARC
		room1 = rm1
		l = level
		t0 = theta0
		t1 = theta1


	func to_str():
		return " {}%d %.2f°->%.2f°: %s::} " % [
			l,
			rad_to_deg(t0),
			rad_to_deg(t1),
			room1.to_str(),
		]


class Room extends MazeRoom:
	## Angle to the center of this room
	var t: float
	## Distance to this room, in equi-distant levels
	var l: int

	# Array of WeakRef[Room]
	var _neighbor_refs: Array
	var _doors: Array


	func _init(maze_: MazeShape, theta: float, level: int) -> void:
		super(maze_)
		t = theta
		l = level


	func _setup():
		find_neighbors()

		# Add boundary walls
		if t0() - M().theta_by_l(l) < M().min_theta:
			_doors.push_back(RadialWall.new(self, l, t0()))
		if t1() + M().theta_by_l(l) > M().max_theta:
			_doors.push_back(RadialWall.new(self, l, t1()))
		if l == M().max_level - 1:
			_doors.push_back(ArcWall.new(self, l + 1, t0(), t1()))
		if l == M().min_level:
			_doors.push_back(ArcWall.new(self, l, t0(), t1()))

		# Lower and Upper min/max thetas
		var l_min_t: float = t1()
		var l_max_t: float = t0()
		var u_min_t: float = t1()
		var u_max_t: float = t0()
		for d: Door in _doors:
			if d._type != Door.DoorType.DOOR_ARC:
				continue

			if d.l >= M().max_level:
				continue

			if d.l == l:
				l_min_t = min(l_min_t, d.t0)
				l_max_t = max(l_max_t, d.t1)

			if d.l == l + 1:
				u_min_t = min(u_min_t, d.t0)
				u_max_t = max(u_max_t, d.t1)

		if l_min_t != t0():
			_doors.push_back(ArcWall.new(self, l, t0(), l_min_t))
		if l_max_t != t1():
			_doors.push_back(ArcWall.new(self, l, l_max_t, t1()))
		if u_min_t != t0():
			_doors.push_back(ArcWall.new(self, l + 1, t0(), u_min_t))
		if u_max_t != t1():
			_doors.push_back(ArcWall.new(self, l + 1, u_max_t, t1()))


	func to_str() -> String:
		return "%d/%.2f°" % [l, rad_to_deg(t)]


	func M() -> Shape:
		return maze_ref.get_ref() as Shape


	## Returns true if open, false if closed
	func walls() -> Array:
		return _doors.map(func(d: Door): return d.open)

	## Return all of the doors that are cononect to valid Rooms
	func doors() -> Array:
		return _doors.filter(func(d: Door) -> bool:
			return d.room2 != null
		)

	func t0() -> float:
		return t - M().theta_by_l(l) / 2


	func t1() -> float:
		return t + M().theta_by_l(l) / 2


	func find_neighbors():
		var m := M()

		# The two adjacent rooms on this level
		var neighbors: Array = m.get_rooms(t - m.theta_by_l(l), t + m.theta_by_l(l), l)
		neighbors = neighbors.filter(func(room): return room != self)

		# Rooms on the level higher.
		var next_level = m.get_rooms(t0(), t1(), l + 1)

		# Rooms on the level lower.
		var prev_level = m.get_rooms(t0(), t1(), l - 1)

		neighbors.append_array(next_level)
		neighbors.append_array(prev_level)
		
		# Save the refs for future utility
		_neighbor_refs = neighbors.map(func(r): return weakref(r))

		_doors = []
		for room: Room in neighbors:
			_doors.push_back(Door.new(self, room))

	func door_to(room: MazeRoom) -> Door:
		for idx in range(_neighbor_refs.size()):
			if _neighbor_refs[idx].get_ref() == room:
				return _doors[idx]
		return null


	func open_wall_between(room: MazeRoom):
		open_wall(room)
		room.open_wall(self)


	func open_wall(room: MazeRoom):
		var door: Door = door_to(room)
		assert(door)
		if door.locked:
			return
		assert(door.room1 == self)
		assert(door.room2 == room)
		door.open = true


	## Return the neighbors that are unvisited and have unlocked doors
	## between them.
	func get_unvisited_neighbors() -> Array:
		return _neighbor_refs.filter(func(ref: WeakRef) -> bool:
			var r: Room = ref.get_ref()
			return r and not r.visited and not door_to(r).locked
		).map(func(ref: WeakRef):
			return ref.get_ref()
		)


class CenterRoom extends Room:
	func find_neighbors():
		var m := M()

		# Rooms on the level higher for the entire arc
		_neighbor_refs = m.get_rooms(0, 2 * PI, 1).map(func(room): return weakref(room))

		_doors = []
		for ref: WeakRef in _neighbor_refs:
			_doors.push_back(Door.new(self, ref.get_ref()))


	func t0() -> float:
		return M().min_theta


	func t1() -> float:
		return M().max_theta


class Shape extends MazeShape:
	var resource: MazeCircleResource
	var min_theta: float:
		get():
			return resource.min_theta
	var max_theta: float:
		get():
			return resource.max_theta
	var min_level: int:
		get():
			return resource.min_level
	var max_level: int:
		get():
			return resource.max_level
	## The actual length of `r` for each level
	var level_width: float:
		get():
			return resource.level_width
	var lowest_level_room_theta: float:
		get():
			return resource.lowest_level_room_theta
	var room_justify: MazeCircleResource.CircleJustify:
		get():
			return resource.room_justify
	var minimum_door_size: float:
		get():
			return resource.min_door_sz * room_length

	# Collection objects for various room and level details
	var rooms_by_level: Array = []
	var theta_by_level: Array = []
	var room_length: float

	# Math!


	## Get the angle of rooms on a specified level
	func theta_by_l(l: int) -> float:
		return theta_by_level[l - min_level]


	## Get all of the rooms at the specified level
	func rooms_by_l(l: int) -> Array:
		return rooms_by_level[l - min_level]


	## Get the length of the entire inner arc describing the level
	func arclength_by_l(l: int) -> float:
		return (max_theta - min_theta) * radius(l)


	## Get the theta for a given inner arc length
	func theta_by_arclength(arc: float, l: int) -> float:
		return arc / radius(l)


	## Get the arclength for rooms at a particular level
	func roomlength_by_l(l: int) -> float:
		return theta_by_level[l - min_level] * radius(l)


	## Get the radius to the inner arc for a given level
	func radius(l: int) -> float:
		return l * level_width


	func _init(circle_resource: MazeCircleResource):
		resource = circle_resource


	## Generate the rooms using the supplied MazeCircleResource
	func generate():
		create_rooms()
		initialize_rooms()
	
	
	## Create all of the rooms in the specified region.  This can be called
	## manually before [code]initialize_rooms()[/code] is called to manually
	## remove rooms, creating voids within the maze.
	func create_rooms():
		# Either r=1 or r=min_radius to calculate the basic room arclength
		room_length = max(lowest_level_room_theta * radius(1), lowest_level_room_theta * radius(min_level))

		rooms_by_level.resize(max_level - min_level)
		theta_by_level.resize(rooms_by_level.size())

		for l in range(min_level, max_level):
			var level = l - min_level
			rooms_by_level[level] = []

			if l == 0:
				rooms_by_level[0] = [CenterRoom.new(self, (max_theta + min_theta) / 2, 0)]
				theta_by_level[level] = max_theta - min_theta
				continue

			var arc := arclength_by_l(l)
			var num_rooms: int = floor(arc / room_length)
			var arc_remainder: float = arc - (room_length * num_rooms)

			# The length of rooms on this floor, adjusted if there's some flux
			var start_theta := min_theta
			var end_theta := max_theta

			var per_room_theta := theta_by_arclength(room_length, l)

			if (min_theta == 0 and max_theta == 2 * PI) or room_justify == MazeCircleResource.CircleJustify.EXPAND_TO_FIT:
				per_room_theta += theta_by_arclength(arc_remainder / num_rooms, l)
			else:
				start_theta += theta_by_arclength(arc_remainder / 2, l)
				end_theta -= theta_by_arclength(arc_remainder / 2, l)
				per_room_theta = (end_theta - start_theta) / num_rooms

			rooms_by_level[level] = []
			theta_by_level[level] = per_room_theta

			for num in range(num_rooms):
				var room_center := start_theta + num * per_room_theta + per_room_theta / 2
				var new_room := Room.new(self, room_center, l)
				rooms_by_level[level].push_back(new_room)

	## Iterate through all of the rooms created on each level, identifying
	## neighbors and creating Doors between the different rooms.
	func initialize_rooms():
		# Now that all the rooms have been created, set up the doors
		for level in rooms_by_level:
			for room: Room in level:
				room._setup()

		# Lock doors that are too small now that all of the doors
		# are created (setting locked expects the reciprocal door
		# to exist).
		#
		# Technically only need to go to max_level-1 but whatever.
		for level in rooms_by_level:
			for room: Room in level:
				for door: Door in room.doors():
					if door._type != Door.DoorType.DOOR_ARC:
						continue
						
					if door.arclength() < minimum_door_size:
						door.locked = true


	## Get all of the rooms that intersect the region between theta_0 and
	## theta_1 on a particular level.
	func get_rooms(t0: float, t1: float, l: int):
		if l >= max_level or l < min_level or t1 < min_theta or t0 > max_theta:
			return []

		var room_theta_offset: float = theta_by_l(l) / 2
		return rooms_by_l(l).filter(
			func(room: Room):
				return (
					room.t - room_theta_offset < t1 and
					t0 < room.t + room_theta_offset
				)
		)


	## The total number of rooms in the maze.
	func size() -> int:
		var s: int = 0
		for rooms in rooms_by_level:
			s += rooms.size()
		return s


	## Get a specific room at that level.  Stable for a given map configuration.
	func room(l: int, offset: int) -> Room:
		return rooms_by_l(l)[offset]

	## Remove a specific room from the maze.
	func remove_room(room: Room):
		rooms_by_l(room.l).erase(room)
