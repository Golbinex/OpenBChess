extends Control

class_name Board

signal halfmove
signal fullmove
signal taken
signal piece_moved
signal highlights_cleared

@export var text_color: Color
@export var square_scene: PackedScene
@export var piece_scene: PackedScene
var move_checker: MoveChecker

const num_squares: int = 64
const default_fen: String = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0"
enum { SIDE, UNDER }

var grid: Array # Map of what pieces are placed on the board
var r_count: int = 0 # Rook counter
var R_count: int = 0 # Rook counter
var halfmoves: int = 0 # Used with fifty-move rule. Reset after pawn move or piece capture
var fullmoves: int = 0 # Incremented after Black's move
var passant_pawn: Piece
var kings = {}
var fen: String
var cleared: bool = true

var square_selected: bool
var selected_square: Square
var hovered_square: Square

var possible_moves: int

var army_value: Dictionary[String, int] = {
	"W": 0,
	"B": 0
}

func _ready():
	# grid will map the pieces in the game
	grid.resize(num_squares)
	draw_squares()
	move_checker = MoveChecker.new(self)
	#hide_labels()
	# Set board layout using Forsyth Edwards encoded string
	setup_pieces()

func game_started():
	update_selectable_squares()

# convert grid position to move code e.g. 0,0 -> a8
func position_to_move(pos: Vector2) -> String:
	assert(pos.x >= 0)
	assert(pos.y >= 0)
	assert(pos.x < 8)
	assert(pos.y < 8)
	return "%s%d" % [char(97 + int(pos.x)), 8 - int(pos.y)]

# convert move code to grid position e.g. h1 -> 7,7
func move_to_position(move: String) -> Vector2:
	assert(move.length() == 2)
	var pos = Vector2(move.unicode_at(0) - 97, 8 - int(move[1]))
	assert(pos.x >= 0)
	assert(pos.y >= 0)
	assert(pos.x < 8)
	assert(pos.y < 8)
	return pos

# The following code requires that the piece layout is in sync with the moves
# If the user moves a piece, then the pgn move list should be wiped
# The idea is to play back the moves of a game and take over at any point
func pgn_to_long(pgn: String, side: String):
	print(pgn, " ", side)
	var m = ""
	var ch = pgn[0]
	# Pawn moves ignoring =Q in dxc1=Q
	if ch.unicode_at(0) > 96: # a .. h
		var y
		if pgn[1] == "x":
			m = pgn.substr(0, 4) #exf6 e?f6
			y = int(pgn[3])
		else:
			m = pgn.substr(0, 2) #f4
			m += m # fff4 f?f4
			y = int(pgn[1])
		m[1] = String(8 - find_pawn_in_col(ch, y, side))
		return m
	# Castling
	if pgn.begins_with("O-O-O"):
		if side == "B":
			return "e8b8"
		else:
			return "e1b1"
	if pgn.begins_with("O-O"):
		if side == "B":
			return "e8g8"
		else:
			return "e1g1"
	pgn = pgn.replace("x", "").substr(1).rstrip("+")
	if pgn.length() > 2: #Nef6 e?f6
		if pgn[0].is_valid_int(): # B1d4 ?1d4
			m = char(97 + find_piece_in_row(pgn[0], ch, side)) + pgn
		else:
			m = pgn[0] + String(8 - find_piece_in_col(pgn[0], ch, side)) + pgn.substr(1)
	else:
		# Here we have the least amount of move information e.g. #Nf6
		m = find_piece_in_grid(ch, side, move_to_position(pgn)) + pgn
	return m

func find_piece_in_row(n, key, side):
	var y = 8 - int(n)
	for x in 8:
		var i = get_grid_index(x, y)
		if grid[i] != null and grid[i].key == key and grid[i].side == side:
			return x
	return -1

func find_piece_in_col(ch, key, side):
	var x = ch.unicode_at(0) - 97
	for y in 8:
		var i = get_grid_index(x, y)
		if grid[i] != null and grid[i].key == key and grid[i].side == side:
			return y
	return -1

func find_piece_in_grid(key, side, pos: Vector2):
	for i in 64:
		var p = grid[i]
		if p != null and p.key == key and p.side == side:
			# See if piece can move to destination
			p.new_board_position = pos
			if move_checker.check_move(p).ok:
				return position_to_move(p.pos)

# Return -1 on error
func find_pawn_in_col(ch, y, side):
	var x = ch.unicode_at(0) - 97
	var dy = 1 if side == "W" else -1
	y = 8 - y + dy
	var i = get_grid_index(x, y)
	if grid[i] != null:
		return y if grid[i].key == "P" else -1
	else: 
		y += dy
		i = get_grid_index(x, y)
		if grid[i] != null:
			return y if grid[i].key == "P" else -1
	return -1

func setup_pieces(_fen = default_fen):
	army_value["W"] = 0
	army_value["B"] = 0
	var parts = _fen.split(" ")
	var next_move_white = parts.size() < 2 or parts[1] == "w"
	var castling = "" if parts.size() < 3 else parts[2]
	r_count = 0
	R_count = 0
	var i = 0
	for ch in parts[0]:
		match ch:
			"/": # Next rank
				pass
			"1", "2", "3", "4", "5", "6", "7", "8":
				i += int(ch)
			_:
				set_piece(ch, i, castling)
				i += 1 
	# Tag pawn for en passant
	if parts.size() >= 4 and parts[3].length() == 2:
		i = parts[3][0].to_ascii_buffer()[0] - 96 # ASCII 'a' = 97
		if i >= 0 and i < 8:
			# Only valid rank is 3 or 6
			match parts[3][1]:
				"3":
					tag_piece(i + 31)
				"6":
					tag_piece(i + 23)
	# Set halfmoves value
	if parts.size() >= 5 and parts[4].is_valid_int():
		set_halfmoves(parts[4].to_int())
	# Set fullmoves value
	if parts.size() >= 6 and parts[5].is_valid_int():
		set_fullmoves(parts[5].to_int())
	return next_move_white

func get_fen(next_move):
	var gi = 0 # Grid index
	var ns = 0 # Number of blank horizontal tile places counter
	var castling = ""
	var _fen = ""
	for y in 8:
		for x in 8:
			var p = grid[gi]
			gi += 1
			if p == null:
				ns += 1
			else:
				if ns > 0:
					_fen += str(ns)
					ns = 0
				var key = p.key
				if p.side == "B":
					key = key.to_lower()
				_fen += key
		if ns > 0:
			_fen += str(ns)
			ns = 0
		if y < 7:
			_fen += "/"
	if is_tagged(0) and is_tagged(4):
		castling += "q"
	if is_tagged(4) and is_tagged(7):
		castling += "k"
	if is_tagged(56) and is_tagged(60):
		castling += "Q"
	if is_tagged(60) and is_tagged(63):
		castling += "K"
	if castling == "":
		castling = "-"
	var pas = "-"
	var pos
	if passant_pawn != null:
		pos = passant_pawn.board_position
		if passant_pawn.side == "B":
			pos.y -= 1
		else:
			pos.y += 1
		pas = position_to_move(pos)
	_fen += " %s %s %s %d %d" % [next_move, castling, pas, halfmoves, fullmoves]
	return _fen

func is_tagged(i):
	return grid[i] != null and grid[i].tagged

func tag_piece(i: int):
	if grid[i] != null:
		grid[i].tagged = true
		passant_pawn = grid[i]
		print("tagged: ", grid[i].board_position)

func set_piece(key: String, i: int, castling: String):
	var p = piece_scene.instantiate()
	var side = "W" if "a" > key else "B"
	var column: int = i % 8
	@warning_ignore("integer_division")
	var row: int = i / 8
	p.set_type(side, key.to_upper())
	army_value[side] += p.value
	p.set_sprite_position(BoardGeometry.center(column, row))
	p.set_board_position(Vector2i(column, row))
	grid[i] = p
	p.play_animation("default")
	$SquareLayer.get_child(i).set_piece(p)
	$PieceLayer.add_child(p)

	# Check castling rights
	match key:
		"r":
			r_count += 1
			if r_count == 1:
				p.tagged = "q" in castling
			else:
				p.tagged = "k" in castling
		"k":
			p.tagged = "k" in castling or "q" in castling
			kings[p.side] = p
		"R":
			R_count += 1
			if R_count == 1:
				p.tagged = "Q" in castling
			else:
				p.tagged = "K" in castling
		"K":
			p.tagged = "K" in castling or "Q" in castling
			kings[p.side] = p

func clear_board():
	passant_pawn = null
	for i in 64:
		take_piece(grid[i], false)
	cleared = true
	for p in $PieceLayer.get_children():
		p.queue_free()
	for s in $SquareLayer.get_children():
		s.remove_piece()
		s.unhighlight()

func take_piece(p: Piece, emit = true):
	if p == null:
		return
	army_value[p.side] -= p.value
	$PieceLayer.remove_child(p)
	grid[get_grid_index(p.board_position.x, p.board_position.y)] = null
	set_halfmoves(0)
	if emit:
		emit_signal("taken", p)

func set_halfmoves(n):
	halfmoves = n
	emit_signal("halfmove", n)

func set_fullmoves(n):
	fullmoves = n
	emit_signal("fullmove", n)

func draw_squares():
	# Add squares to grid
	var odd = true
	for y in 8:
		odd = !odd
		for x in 8:
			odd = !odd
			if odd:
				add_square(x, y, "W")
			else:
				add_square(x, y, "B")

func add_square(x: int, y: int, color: String):
	var square = square_scene.instantiate()
	square.set_board_position(Vector2i(x, y))
	square.set_shape(BoardGeometry.corners(x, y))
	square.set_color(color)
	$SquareLayer.add_child(square)
	square.square_hovered.connect(square_hovered)
	square.square_unhovered.connect(square_unhovered)
	square.square_clicked.connect(square_clicked)
	if x == 0:
		add_label(square, BoardGeometry.center(x, y), SIDE, str(8 - y))
	if y == 7:
		add_label(square, BoardGeometry.center(x, y), UNDER, char(97 + x))

func square_clicked(square: Square):
	# If the selected piece was clicked
	if selected_square != null and square.selected:
		square.unselect()
		selected_square = null
		square_selected = false
		highlight_selectable_squares(square)
	elif square.selectable:
		# If the square is highlighted for possible move, move the piece
		if square.highlighted:
			var p = selected_square.get_piece()
			p.new_board_position = square.board_position
			clear_selectable_squares()
			piece_moved.emit(p, false)
		# The square is selectable and no other square is selected
		else:
			square.select()
			selected_square = square
			square_selected = true
			highlight_selectable_squares(square)

func highlight_selectable_squares(square: Square):
	clear_selectable_squares()
	var p = square.get_piece()
	for s in p.possible_moves:
		get_square(s).highlight()
	if !square_selected:
		for s in $SquareLayer.get_children():
			p = s.get_piece()
			if s.occupied and s.piece.side == "W" and !p.possible_moves.is_empty():
				s.selectable = true

func update_selectable_squares():
	possible_moves = 0
	for s: Square in $SquareLayer.get_children():
		if s.highlighted:
			s.unhighlight()
		if s.occupied and s.piece.side == "W":
			var p = s.get_piece()
			p.possible_moves.clear()
			for s2: Square in $SquareLayer.get_children():
				p.new_board_position = s2.board_position
				if move_checker.check_move(p).ok:
					p.possible_moves.append(s2.board_position)
					possible_moves += 1
			if !p.possible_moves.is_empty():
				s.selectable = true
	if hovered_square and hovered_square.occupied == true:
		square_hovered(hovered_square, true)

func clear_selectable_squares():
	for s: Square in $SquareLayer.get_children():
		s.unhighlight()

func square_hovered(square: Square, skip: bool = false):
	# If there was previously hovered square, wait for it to clear highlighed squares
	if hovered_square and !skip:
		await highlights_cleared
	hovered_square = square
	if square_selected or !square.selectable:
		return
	for s: Square in $SquareLayer.get_children():
		if s.occupied == false or s.get_piece().side != "W":
			s.unhighlight()
	var p = square.get_piece()
	if p and p.side == "W":
		for s in p.possible_moves:
			get_square(s).highlight()

func square_unhovered(square: Square):
	if hovered_square == square:
		hovered_square = null
	var p = square.get_piece()
	if !square_selected and p and p.side == "W":
		for s in p.possible_moves:
			get_square(s).unhighlight()
	highlights_cleared.emit()

func add_label(node: Square, pos: Vector2, side, chr):
	var l = Label.new()
	l.add_to_group("labels")
	l.text = chr
	l.add_theme_color_override("font_color", text_color)
	if side == SIDE:
		pos.x -= 60
		pos.y -= 15
		l.position = pos
	else:
		pos.y += 30
		l.position = pos
	node.add_child(l)

func hide_labels(show_labels = false):
	for label in get_tree().get_nodes_in_group("labels"):
		label.visible = show_labels

func get_grid_index(x: int, y: int):
	return x + 8 * y

func get_piece_in_grid(x: int, y: int):
	var p = grid[get_grid_index(x, y)]
	return p

func move_piece(p: Piece):
	var pos = get_grid_index(p.board_position.x, p.board_position.y)
	grid[pos] = null
	pos = get_grid_index(p.new_board_position.x, p.new_board_position.y)
	grid[pos] = p
	get_square(p.board_position).remove_piece()
	p.move()
	get_square(p.board_position).set_piece(p)
	if p != passant_pawn:
		passant_pawn = null
	p.tagged = false # Prevent castling after move
	if p.key == "P":
		set_halfmoves(0)
	else:
		set_halfmoves(halfmoves + 1)
	if p.side == "B":
		set_fullmoves(fullmoves + 1)
	cleared = false
	square_selected = false

func get_square(pos: Vector2i):
	return $SquareLayer.get_child(pos.x + 8 * pos.y)
