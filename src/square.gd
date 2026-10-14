class_name Square extends Area2D

var color: String # The Black or the white "B" or "W"
var board_position: Vector2i # position in grid
var occupied: bool = false # Whether there is a piece on the square
var hovered: bool = false # Whether square is hovered over by mouse
var selectable: bool = false # Whether square is currently selectable
var selected: bool = false # Whether square was selected by player
var highlighted: bool = false # Whether square is highlighted for possible move
var transparent: bool = false # Whether outline is transparent
var piece: Piece # Piece object that occupies the square

const red: Color = Color(1, 0, 0)
const blue: Color = Color(0, 0, 1)

signal square_hovered
signal square_unhovered
signal square_clicked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Line2D.set_default_color(red)
	$Polygon2D.color = Color(1, 1, 0, 0.5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_timer_timeout() -> void:
	if hovered and selectable:
		if $Line2D.visible == true and !selected:
			$Line2D.visible = false
		else:
			$Line2D.visible = true

func _mouse_enter() -> void:
	hovered = true
	square_hovered.emit(self)
	$Timer.start()

func _mouse_exit() -> void:
	hovered = false
	square_unhovered.emit(self)
	if !selected:
		$Line2D.visible = false
	$Timer.stop()

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	#print("event type : ", event.get_class())
	if event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_LEFT and event.is_pressed() == true :
		get_viewport().set_input_as_handled()
		#print("piece:", piece)
		square_clicked.emit(self)
		#var p = get_piece_in_grid(pos)
		#if p != null:
			#if event.pressed:
				#emit_signal("clicked", p)
			#else:
				#print("unclick event : ", p)
				#emit_signal("unclicked", p)
	# Mouse position is relative to the square
	#if event is InputEventMouseMotion:
		#emit_signal("moved", event.position)

func get_color():
	return color

func set_color(c: String):
	color = c

func get_board_position():
	return board_position
	
func set_board_position(p: Vector2i):
	board_position = p
	# Adjacent squares can have overlapping collision polygons,
	# so unique z_index is assigned to prevent two squares being hovered over at the same time
	$CollisionPolygon2D.z_index = p.x + 8 * p.y

func get_shape():
	return $CollisionPolygon2D.polygon
	
func set_shape(shape: PackedVector2Array):
	$CollisionPolygon2D.polygon = shape
	$Polygon2D.polygon = shape
	# Square outlines
	$Line2D.clear_points()
	for point in shape:
		$Line2D.add_point(point)

func is_occupied():
	return occupied

func get_piece():
	if piece:
		return piece
	else:
		return null

func set_piece(p: Piece):
	piece = p
	occupied = true

func remove_piece():
	piece = null
	occupied = false
	unselect()

func select():
	selected = true
	outline()

func unselect():
	selected = false
	remove_outline()

func outline(solid = true):
	if $Line2D.visible == false:
		$Line2D.visible = true
	if solid:
		$Line2D.set_modulate(Color(1, 1, 1, 1))
		transparent = false
	else:
		$Line2D.set_modulate(Color(1, 1, 1, 0.3))
		transparent = true

func remove_outline():
	$Line2D.visible = false

func highlight():
	highlighted = true
	selectable = true
	#outline(false)
	$Polygon2D.visible = true

func unhighlight():
	highlighted = false
	selectable = false
	#remove_outline()
	$Polygon2D.visible = false
	if !selected:
		$Line2D.visible = false
