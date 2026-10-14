class_name MoveChecker
extends RefCounted

var board: Board

const KING_MOVE_OFFSETS: PackedVector2Array = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1)
]

# x: first row for castling logic
# y: second row for pawn long move logic
# z: fifth row for en passant logic
const BOARD_ROWS: Dictionary[String, Vector3i] = {
	"W": Vector3i(7, 6, 3),
	"B": Vector3i(0, 1, 4)
}

const KING_CASTLING_MOVE_OFFSETS: PackedVector2Array = [
	Vector2i(0, -2),
	Vector2i(0, 2)
]

const KNIGHT_MOVE_OFFSETS: PackedVector2Array = [
	Vector2i(-2, -1),
	Vector2i(-1, -2),
	Vector2i(1, -2),
	Vector2i(2, -1),
	Vector2i(2, 1),
	Vector2i(1, 2),
	Vector2i(-1, 2),
	Vector2i(-2, 1)
]

const ROOK_MOVE_DIRECTIONS: PackedVector2Array = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0)
]

const BISHOP_MOVE_DIRECTIONS: PackedVector2Array = [
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(1, 1),
	Vector2i(-1, 1)
]

const QUEEN_MOVE_DIRECTIONS: PackedVector2Array = ROOK_MOVE_DIRECTIONS + BISHOP_MOVE_DIRECTIONS

const PAWN_MOVE_OFFSET: Dictionary[String, Vector2i] = {
	"W": Vector2i(0, -1),
	"B": Vector2i(0, 1)
}

# x: Y initial position of pawn
# y: long move Y offset
# z: Y position for en passant
const PAWN_LONG_MOVE_OFFSET: Dictionary[String, int] = {
	"W": -2,
	"B": 2
}

const PAWN_ATTACK_OFFSETS: Dictionary[String, Array] = {
	"W": [
		Vector2i(-1, -1),
		Vector2i(1, -1)
	],
	"B": [
		Vector2i(-1, 1),
		Vector2i(1, 1)
	]
}

func _init(board_reference: Board) -> void:
	board = board_reference

func is_king_checked(p: Piece, flip: bool = true):
	# Flip is disabled when checking for possible moves, except when checking for king moves
	var side = p.side
	var cur_pos = board.get_grid_index(p.board_position.x, p.board_position.y)
	var new_pos = board.get_grid_index(p.new_board_position.x, p.new_board_position.y)
	var pos_backup = board.grid[new_pos]
	var checked: bool
	if p.key == "K":
		if !flip:
			return { "checked": is_checked(p.new_board_position.x, p.new_board_position.y, side) }
		else:
			board.grid[cur_pos] = null
			board.grid[new_pos] = p
			checked = is_checked(p.new_board_position.x, p.new_board_position.y, side)
			board.grid[cur_pos] = p
			board.grid[new_pos] = pos_backup
			return { "checked": checked }
	else:
		if flip:
			if p.side == "B":
				side = "W"
			else:
				side = "B"
		# Temporary grid change for check status
		else:
			board.grid[cur_pos] = null
			board.grid[new_pos] = p
		var pos = Vector2i(board.kings[side].board_position.x, board.kings[side].board_position.y)
		var mated = false
		checked = is_checked(pos.x, pos.y, side)
		if checked:
			# Scan for check mate
			mated = true
			for o in KING_MOVE_OFFSETS:
				if king_can_move_to(pos.x + o[0], pos.y + o[1], side):
					mated = is_checked(pos.x + o[0], pos.y + o[1], side)
				if !mated:
					break
		# Revert grid changes
		if !flip:
			board.grid[cur_pos] = p
			board.grid[new_pos] = pos_backup
		return { "checked": checked, "mated": mated, "side": side }

func king_can_move_to(x, y, side):
	if x < 0 or x > 7 or y < 0 or y > 7:
		return false
	var p = board.get_piece_in_grid(x, y)
	return p == null or p.side != side

# Check if position is under attack
func is_checked(x, y, side):
	# pawns
	var key1 = "P"
	var key2 = ""
	
	for offset in PAWN_ATTACK_OFFSETS[side]:
		var check_x: int = x + offset.x
		var check_y: int = y + offset.y
		if can_attack(check_x, check_y, side, key1):
			return true
	
	# king
	key1 = "K"
	for offset in KING_MOVE_OFFSETS:
		var check_x: int = x + offset.x
		var check_y: int = y + offset.y
		if can_attack(check_x, check_y, side, key1):
			return true
	
	# rooks and queen
	key1 = "R"
	key2 = "Q"
	for direction in ROOK_MOVE_DIRECTIONS:
		if scan_for_attacking_piece(x, y, direction.x, direction.y, side, key1, key2):
			return true
	
	# bishops and queen
	key1 = "B"
	for direction in BISHOP_MOVE_DIRECTIONS:
		if scan_for_attacking_piece(x, y, direction.x, direction.y, side, key1, key2):
			return true
	
	# Knight
	key1 = "N"
	for offset in KNIGHT_MOVE_OFFSETS:
		var check_x: int = x + offset.x
		var check_y: int = y + offset.y
		if can_attack(check_x, check_y, side, key1):
			return true
	return false

func scan_for_attacking_piece(ox, oy, incx, incy, side, key1, key2 = ""):
	var can = false
	var j = ox
	var k = oy
	var p = null
	while(p == null):
		j += incx
		k += incy
		if j < 0 or j > 7 or k < 0 or k > 7:
			break
		p = board.get_piece_in_grid(j, k)
		can = p != null and p.side != side and (p.key == key1 or p.key == key2)
	return can

func can_attack(x, y, side, key):
	if x < 0 or x > 7 or y < 0 or y > 7:
		return false
	var p = board.get_piece_in_grid(x, y)
	return p != null and p.side != side and p.key == key

# Check if it is valid to move to the new position of a piece
# Return true/false and null/piece that occupies the position plus
# castling and passant flags to indicate to check for these situations
func check_move(p: Piece):
	var castling = false
	var passant = false
	var tag_passant_pawn = false
	# Move offsets
	var x = int(p.new_board_position.x - p.board_position.x)
	var y = int(p.new_board_position.y - p.board_position.y)
	if p.new_board_position.x < 0 or p.new_board_position.y < 0 or p.new_board_position.x > 7 or p.new_board_position.y > 7:
		# piece dropped outside of grid
		return { "ok": false }
	var ax = int(abs(x))
	var ay = int(abs(y))
	var p2 = board.get_piece_in_grid(p.new_board_position.x, p.new_board_position.y)
	# Check for valid move
	# Don't care about bounds of the board since the piece will be released if outside
	var ok = false
	var check_path = true
	match p.key:
		"P": # Check for valid move of pawn
			# Allow moving one square forward
			ok = y == PAWN_MOVE_OFFSET[p.side].y
			# Allow moving two squares forward on the first move
			if p.board_position.y == BOARD_ROWS[p.side].y and y == PAWN_LONG_MOVE_OFFSET[p.side]:
				ok = true
				# Tag pawn as a target for en passant
				tag_passant_pawn = true
			# Check for possible en passant move
			passant = y == PAWN_MOVE_OFFSET[p.side].y and ax == 1 and p.board_position.y == BOARD_ROWS[p.side].z
			# Check for valid horizontal move
			if ok:
				# If the move is vertical to an empty square
				ok = (ax == 0 and p2 == null
				# If the move is diagonal to an occupied square
				or ay == 1 and ax == 1 and p2 != null
				# If the move is diagonal behind passant pawn
				or board.passant_pawn and board.passant_pawn.board_position.x == p.new_board_position.x and board.passant_pawn.board_position.y == p.board_position.y)
		"R": # Check for valid horizontal or vertical move of rook
			ok = ax > 0 and ay == 0 or ax == 0 and ay > 0
		"B": # Check for valid diagonal move of bishop
			ok = ax == ay
		"K": # Check for valid move of king
			ok = ax < 2 and ay < 2
			if ax == 2 and ay == 0 and p2 == null and p.tagged: # Moved 2 steps in x and tagged
				if p.board_position.x == 4 and p.board_position.y == BOARD_ROWS[p.side].x:
					castling = true # Potential castling situation
					ok = true
		"N": # Check for valid move of knight
			check_path = false # knight may jump over pieces
			ok = ax == 2 and ay == 1 or ax == 1 and ay == 2
		"Q": # Add the queen to the checking process of hopping over pieces
			ok = ax > 0 and ay == 0 or ax == 0 and ay > 0 or ax == ay
	# Check for landing on own piece
	if ok and p2 != null:
		ok = p.side == "B" and p2.side == "W" or p.side == "W" and p2.side == "B"
	# Check for passing over a piece
	if check_path and ok and (ax > 1 or ay > 1):
		var checking = true
		while checking:
			if ax > 0:
				x -= int(sign(x)) # Move back horizontally
			if ay > 0:
				y -= int(sign(y)) # Move back vertically
			var p3 = board.get_piece_in_grid(p.board_position.x + x, p.board_position.y + y)
			ok = p3 == null
			ax -= 1
			ay -= 1
			checking = (ax > 1 or ay > 1) and ok
	#if !ok and p == passant_pawn:
		#passant_pawn = null
	# King check status
	if ok:
		ok = !is_king_checked(p, p.key == "K").checked
	return { "ok": ok, "attacked_piece": p2, "castling": castling, "passant": passant, "tag_passant": tag_passant_pawn }
