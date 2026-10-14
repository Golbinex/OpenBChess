extends Control

@onready var engine = $Engine
@onready var fd = $c/FileDialog
@onready var promote = $c/Promote
@onready var board = $VBox/Board
@onready var settings = $c/Settings

var move_checker: MoveChecker

var fen_move: String
var long_moves : PackedStringArray = []
var selected_piece : Piece
var fen: String
var show_suggested_move = true
var white_next = true
var pgn_moves = []
var move_index = 0
var promote_to = ""
var state = IDLE

# states
enum { IDLE, CONNECTING, STARTING, PLAYER_TURN, ENGINE_TURN, PLAYER_WIN, ENGINE_WIN }
# events
enum { CONNECT, NEW_GAME, DONE, ERROR, MOVE }

func _ready():
	board.connect("piece_moved", try_to_make_a_move)
	promote.connect("promotion_picked", Callable(self, "promote_pawn"))
	show_transport_buttons(false)
	show_last_move()
	ponder() # Hide it
	move_checker = board.move_checker
	state = IDLE
	# TEST
	handle_state(NEW_GAME)

func handle_state(event, msg = ""):
	match state:
		IDLE:
			match event:
				CONNECT:
					var status = engine.start_engine()
					if status.started:
						engine.send_command("uci")
						state = CONNECTING
					else:
						alert(status.error)
				NEW_GAME:
					# Keep piece arrangement and move counts.
					if engine.engine_pid > 0:
						engine.send_command("ucinewgame")
						engine.send_command("isready")
						state = STARTING
					else:
						handle_state(CONNECT)
		CONNECTING:
			match event:
				DONE:
					if msg == "uciok":
						print("state idle")
						state = IDLE
						handle_state(NEW_GAME)
				ERROR:
					alert("Unable to connect to Chess Engine!")
					state = IDLE
		STARTING:
			match event:
				DONE:
					if msg == "readyok":
						board.game_started()
						if white_next:
							alert("White to begin")
							state = PLAYER_TURN
						else:
							alert("Engine to begin")
							prompt_engine()
				ERROR:
					alert("Lost connection to Chess Engine!")
					state = IDLE
		PLAYER_TURN:
			match event:
				DONE:
					print(msg)
					print("hello")
				MOVE:
					ponder()
					# msg should contain the player move
					show_last_move(msg)
					prompt_engine(msg)
		ENGINE_TURN:
			match event:
				DONE:
					# Client allowed illegal move
					if msg.begins_with("info string CRITICAL ERROR"):
						alert("Please report this to developer:\n" + msg, 0, Vector2i(600, 200))
						state = IDLE
					var move = get_best_move(msg)
					# Engine can't make any move, player wins
					if move == "(none)":
						state = PLAYER_WIN
						handle_state(DONE)
					elif move != "":
						await move_engine_piece(move)
						show_last_move(move)
						state = PLAYER_TURN
						board.update_selectable_squares()
						# Player can't do any moves even though king is not in check
						if board.possible_moves == 0:
							state = ENGINE_WIN
							handle_state(DONE)
		PLAYER_WIN:
			match event:
				DONE:
					alert("Check Mate! Player won")
					state = IDLE
					set_next_color()
		ENGINE_WIN:
			match event:
				DONE:
					alert("Check Mate! Engine won")
					state = IDLE
					set_next_color()

func prompt_engine(move = ""):
	engine.send_command("position fen %s moves %s" % [fen, move])
	engine.send_command("go movetime 1000")
	state = ENGINE_TURN

func show_last_move(move = ""):
	$VBox/HBox/Grid/LastMove.text = move

func get_best_move(s: String):
	var move = ""
	# Make sure that whitespace contains spaces
	# since it may only have tabs for example
	var raw_tokens = s.replace("\t", " ").split(" ")
	var tokens = []
	for t in raw_tokens:
		var tt = t.strip_edges()
		if tt != "":
			tokens.append(tt)
	if tokens.size() > 1:
		if tokens[0] == "bestmove": # This is the engine's move
			move = tokens[1]
	if tokens.size() > 3:
		if tokens[2] == "ponder":
			# This is the move suggested to the player by the engine following
			# it's best move (so like the engine playing against itself)
			ponder(tokens[3])
	return move

# The engine sends a suggested next move for the player tagged with "ponder"
# So we display this move to the player in the UI or hide the UI elements
func ponder(move = ""):
	if move == "":
		$VBox/HBox/VBox/Ponder.modulate.a = 0
	elif show_suggested_move:
		$VBox/HBox/VBox/Ponder.modulate.a = 1.0
		$VBox/HBox/VBox/Ponder/Move.text = move

func move_engine_piece(move: String):
	# Engine can't move, player wins
	var pos1 = board.move_to_position(move.substr(0, 2))
	var p: Piece = board.get_piece_in_grid(pos1.x, pos1.y)
	p.new_board_position = board.move_to_position(move.substr(2, 2))
	if move[move.length() - 1] in "rnbq":
		promote_to = move[move.length() - 1]
	try_to_make_a_move(p)

func alert(txt, duration = 1.0, window_size = Vector2i(200, 50)):
	$c/Alert.open(txt, duration, window_size)

func try_to_make_a_move(piece: Piece, non_player_move = true):
	fen = board.get_fen("b" if non_player_move else "w")
	var info = move_checker.check_move(piece)
	# When Idle, we are not playing a game so the user may move the black pieces
	# Try to drop the piece
	# Also check for castling and passant
	var ok_to_move = false
	var rook = null
	if info.ok:
		if info.attacked_piece != null:
			ok_to_move = true
		else:
			if info.passant:
				print("passant: ", board.passant_pawn.board_position.x, " attacking pawn: ", piece.new_board_position.x)
			if info.passant and board.passant_pawn.board_position.x == piece.new_board_position.x:
				board.take_piece(board.passant_pawn)
				board.passant_pawn = null
				ok_to_move = true
			else:
				ok_to_move = piece.key != "P" or piece.board_position.x == piece.new_board_position.x
			if info.castling:
				# Get rook
				var rx
				if piece.new_board_position.x == 2:
					rx = 3
					rook = board.get_piece_in_grid(0, piece.new_board_position.y)
				else:
					rook = board.get_piece_in_grid(7, piece.new_board_position.y)
					rx = 5
				if rook != null and rook.key == "R" and rook.tagged and rook.side == piece.side:
					ok_to_move = !move_checker.is_checked(rx, rook.board_position.y, rook.side)
					if ok_to_move:
						# Move rook
						rook.new_board_position = Vector2i(rx, rook.board_position.y)
					else:
						alert("Check")
				else:
					ok_to_move = false
	if info.attacked_piece != null:
		ok_to_move = ok_to_move and info.attacked_piece.key != "K"
	if ok_to_move:
		if piece.key == "K":
			if move_checker.is_king_checked(piece).checked:
				alert("Cannot move into check position!")
			else:
				if rook != null:
					move_piece(rook, false)
				board.take_piece(info.attacked_piece)
				move_piece(piece)
		elif move_checker.is_king_checked(piece, false).checked :
			alert("Your king is in check!")
		else:
			if piece.key == "P":
				await check_promotion(piece)
			board.take_piece(info.attacked_piece)
			move_piece(piece)
			if info.tag_passant:
				board.tag_piece(board.get_grid_index(piece.board_position.x, piece.board_position.y))
			var status = move_checker.is_king_checked(piece)
			if status.mated:
				alert("Check Mate!")
				if status.side == "B":
					state = PLAYER_WIN
				else:
					state = ENGINE_WIN
				handle_state(DONE)
			else:
				if status.checked:
					alert("Check")
	# Settle the piece precisely into position and reset it's z_order
	#return_piece(piece)

func move_piece(piece: Piece, not_castling = true):
	set_next_color(piece.side == "B")
	var pos = [piece.board_position, piece.new_board_position]
	board.move_piece(piece)
	if state == PLAYER_TURN:
		fen_move = (board.position_to_move(pos[0]) + board.position_to_move(pos[1]))
		if piece.promoted:
			fen_move += piece.key.to_lower()
			piece.promoted = false
		if not_castling:
			# When castling there may be 2 moves to convey rook <> king
			handle_state(MOVE, " " + fen_move)

# Check for promotion possibility
func check_promotion(piece: Piece):
	if piece.side == "B" and piece.new_board_position.y == 7 or piece.side == "W" and piece.new_board_position.y == 0:
		if promote_to == "":
			# Prompt player
			promote.open(piece)
			await promote.promotion_picked
		else:
			piece.promote(promote_to)
	promote_to = ""

func promote_pawn(p: Piece, pick: String):
	p.promote(pick)
	board.army_value[p.side] += p.value - 1

func _on_Start_button_down():
	state = IDLE
	handle_state(NEW_GAME)

func _on_Engine_done(ok, packet):
	if ok:
		handle_state(DONE, packet)
	else:
		handle_state(ERROR)

func _on_CheckBox_toggled(button_pressed):
	show_suggested_move = button_pressed

func _on_Board_fullmove(n):
	$VBox/HBox/Grid/Moves.text = str(n)

func _on_Board_halfmove(n):
	$VBox/HBox/Grid/HalfMoves.text = str(n)
	if n == 50:
		alert("It's a draw!")
		state = IDLE

func reset_board():
	if !board.cleared:
		state = IDLE
		board.clear_board()
		board.setup_pieces()
		board.halfmoves = 0
		board.fullmoves = 0
		show_last_move()
		ponder()
		set_next_color()
		state = IDLE
		board.clear_board()
		board.setup_pieces()
	move_index = 0
	update_count(move_index)
	set_next_color()

func _on_Reset_button_down():
	reset_board()

func _on_Flip_button_down():
	set_next_color(!white_next)

func set_next_color(is_white = true):
	white_next = is_white
	$VBox/HBox/Menu/Next/Color.color = Color.WHITE if white_next else Color.BLACK

func _on_Load_button_down():
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.popup_centered()

func _on_Save_button_down():
	fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fd.popup_centered()

func _on_FileDialog_file_selected(path: String):
	if fd.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		var file = FileAccess.open(path, FileAccess.READ)
		#file.open(path, File.READ)
		var content = file.get_as_text()
		file.close()
		if path.get_extension().to_lower() == "pgn":
			set_pgn_moves(pgn_from_file(content))
		else:
			fen_from_file(content)
	else:
		save_file(board.get_fen("w" if white_next else "b"), path)

# Extract the moves from the first game in a Portable Game Notation (PGN) text
func pgn_from_file(content: String) -> String:
	var pgn: PackedStringArray = []
	var lines = content.split("\n")
	var started = false
	for line in lines:
		if !started:
			if line.begins_with("1."):
				started = true
			else:
				continue
		if line.length() == 0:
			break
		else:
			pgn.append(line.strip_edges())
	return " ".join(pgn)

func fen_from_file(content: String):
	var parts = content.split(",")
	# Find the FEN string
	fen = ""
	for s in parts:
		if "/" in s:
			fen = s.replace('"', '')
			break
	# Validate it
	if is_valid_fen(fen):
		board.clear_board()
		set_next_color(board.setup_pieces(fen))
	else:
		alert("Invalid FEN string")

func is_valid_fen(_fen: String):
	var n = 0
	var rows = 1
	for ch in _fen:
		if ch == " ":
			break
		if ch == "/":
			rows += 1
		elif ch.is_valid_int():
			n += int(ch)
		elif ch in "pPrRnNbBqQkK":
			n += 1
	return n == 64 and rows == 8

func save_file(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	#file.open(path, File.WRITE)
	file.store_string(content)
	file.close()

func set_pgn_moves(_moves):
	_moves = _moves.split(" ")
	_moves.resize(_moves.size() - 1) # Remove the score
	pgn_moves = []
	long_moves = []
	for i in _moves.size():
		if i % 3 > 0:
			pgn_moves.append(_moves[i])
	show_transport_buttons()
	reset_board()

func update_count(n: int):
	$VBox/HBox/Options/TB/Count.text = "%d/%d" % [n, pgn_moves.size()]

func show_transport_buttons(show_buttons = true):
	$VBox/HBox/Options/TB.modulate.a = 1.0 if show_buttons else 0.0

func _on_Begin_button_down():
	reset_board()

func _on_Forward_button_down():
	step_forward()

func step_forward():
	if move_index >= pgn_moves.size():
		set_next_color()
		return
	if long_moves.size() <= move_index:
		long_moves.append(board.pgn_to_long(pgn_moves[move_index], "W" if move_index % 2 == 0 else "B"))
	move_engine_piece(long_moves[move_index])
	show_last_move(long_moves[move_index])
	move_index += 1
	update_count(move_index)

var stepping = false

func _on_End_button_down():
	stepping = true
	while stepping and pgn_moves.size() > move_index:
		step_forward()

func _on_End_button_up():
	stepping = false

func _on_engine_done(ok, packet):
	if ok:
		handle_state(DONE, packet)
	else:
		handle_state(ERROR)

# Popup options
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			settings.popup_centered()
