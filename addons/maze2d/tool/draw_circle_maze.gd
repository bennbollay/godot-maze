extends RefCounted

class_name MazeCirclePrint

static func console(shape: MazeCircle.Shape):
	print(
		"Circle: %.0f to %.0f x [%d -> %d] with %d rooms %.2f°/%f long" % [
			rad_to_deg(shape.min_theta),
			rad_to_deg(shape.max_theta),
			shape.min_level,
			shape.max_level,
			shape.size(),
			rad_to_deg(shape.lowest_level_room_theta),
			shape.room_length,
		],
	)

	for level in range(shape.rooms_by_level.size()):
		var l = level + shape.min_level
		var ln := "    Level %02d (%d) %.2f°/%.2f x %d rooms: " % [
			level + shape.min_level,
			(level + shape.min_level) * shape.level_width,
			rad_to_deg(shape.theta_by_level[level]),
			shape.roomlength_by_l(l),
			shape.rooms_by_level[level].size(),
		]
		for room: MazeCircle.Room in shape.rooms_by_level[level]:
			ln += " %s " % [room.to_str()]
		print(ln)


static func canvas(canvas: CanvasItem, shape: MazeCircle.Shape, rect: Rect2, show_labels: bool = true, show_boundry: bool = true):
	var center := Vector2.ZERO
	var LEGACY_COMPUTING_FONT := load("uid://b2itbw3sn4cnx")
	var font := LEGACY_COMPUTING_FONT

	var scaling := min(rect.size.x, rect.size.y) as float / (2 * shape.max_level * shape.level_width)

	# Draw the rooms
	for l in shape.rooms_by_level:
		for r: MazeCircle.Room in l:
			if show_labels:
				draw_room_label(canvas, center, shape, r, scaling, font)
			for d in r._doors:
				draw_door(canvas, center, shape, d, scaling)

	if not show_boundry:
		return

	var border_color = Color.ALICE_BLUE
	var min_t = shape.min_theta
	var max_t = shape.max_theta
	var min_l = shape.min_level
	var max_l = shape.max_level

	# Draw the inner circle
	if min_l > 0:
		canvas.draw_arc(center, shape.radius(min_l) * scaling, min_t, max_t, 100, border_color)

	# Draw the outer circle
	canvas.draw_arc(center, shape.radius(max_l) * scaling, min_t, max_t, 100, border_color)

	# Draw the min_theta and max_theta radials, if not a full circle
	if min_t != 0 or max_t != 2 * PI:
		var pt1: Vector2
		var pt2: Vector2

		for theta in [min_t, max_t]:
			pt1 = center + Vector2(shape.radius(min_l) * scaling, 0).rotated(theta)
			pt2 = center + Vector2(shape.radius(max_l) * scaling, 0).rotated(theta)
			canvas.draw_line(pt1, pt2, border_color)


static func draw_room_label(canvas: CanvasItem, center: Vector2, shape: MazeCircle.Shape, r: MazeCircle.Room, scaling: float, font: Font):
	var pt1 = center + Vector2((r.l * shape.level_width + shape.level_width / 2) * scaling, 0).rotated(r.t)
	var color := Color.GREEN if r.visited else Color.RED
	canvas.draw_string(font, pt1, r.to_str(), HORIZONTAL_ALIGNMENT_CENTER, -1, 6, color)


static func draw_door(canvas: CanvasItem, center: Vector2, shape: MazeCircle.Shape, d: MazeCircle.Door, scaling: float):
	var closed: bool = not d.open
	var line_width = 3 if closed else -1
	if d._type == MazeCircle.Door.DoorType.DOOR_ARC:
		var color := Color.BLACK if closed else Color.RED + Color(0, 0, (d.t0 / (PI)))

		canvas.draw_arc(center, d.radius * scaling, d.t0, d.t1, 100, color, line_width)
	if d._type == MazeCircle.Door.DoorType.DOOR_RADIAL:
		var color := Color.BLACK if closed else Color.BLUE + Color((d.l as float / shape.max_level), 0, 0)
		var pt1 := center + Vector2(d.radius * scaling, 0).rotated(d.t)
		var pt2 := center + Vector2(shape.radius(d.l + 1) * scaling, 0).rotated(d.t)

		canvas.draw_line(pt1, pt2, color, line_width)
