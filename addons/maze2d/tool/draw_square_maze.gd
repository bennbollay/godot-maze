extends RefCounted

class_name MazeSquarePrint

static var system_font := SystemFont.new()
static var LEGACY_COMPUTING_FONT: Font
static func console(shape: MazeSquare.Shape):
	print("\n".join(shape.to_str()))


static func get_line_width(font: Font, ln: String) -> Vector2:
	return font.get_string_size(ln)


static func canvas(canvas: CanvasItem, shape: MazeSquare.Shape, rect: Rect2):
	if not system_font:
		system_font = SystemFont.new()
		system_font.font_names = ["monospace"]
	if not LEGACY_COMPUTING_FONT:
		LEGACY_COMPUTING_FONT = load("uid://b2itbw3sn4cnx")
	
	if rect.size.x == 0 or rect.size.y == 0:
		return

	var top_left := Vector2.ZERO - rect.size / 2

	var font := LEGACY_COMPUTING_FONT

	# Roughly scale the font to fit within the rect
	var lns := shape.to_str()
	var w := get_line_width(font, lns[0]).x
	var h := get_line_width(font, lns[0]).y * lns.size()
	var new_size = round(min(rect.size.x / w, rect.size.y / h) * 16)

	canvas.draw_multiline_string(font, top_left, "\n" + "\n".join(lns), HORIZONTAL_ALIGNMENT_LEFT, -1, new_size)
