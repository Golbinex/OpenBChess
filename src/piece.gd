class_name Piece extends Node

var side: String # The Black or the white "B" or "W"
# The key code used in notation (PRNBQK)
# Pawn Rook kNight Bishop Queen King
var key: String
#var obj : Sprite2D # The sprite object in the running game
var board_position = Vector2i(0, 0) # position in grid
var new_board_position = Vector2i(0, 0) # position to move to in grid coors
var tagged: bool = false # Used to indicate if castling is enabled for Rook or King
var possible_moves: PackedVector2Array
var promoted: bool = false
var value: int = 0

const PIECE_VALUES: Dictionary[String, int] = {
	"K": 0,
	"P": 1,
	"N": 3,
	"B": 3,
	"R": 5,
	"Q": 9
}

func _ready() -> void:
	$AnimatedSprite2D.centered = true
	possible_moves.resize(64)

func _process(delta: float) -> void:
	pass

func get_side():
	return side

func get_key():
	return key

func set_type(s: String, k: String):
	side = s
	key = k
	value = PIECE_VALUES[k]
	$AnimatedSprite2D.set_sprite_frames(Pieces.get_piece(k, s).get_sprite_frames())

func get_board_position():
	return board_position

func set_board_position(p: Vector2i):
	board_position = p

func set_sprite_position(p: Vector2i):
	self.position = p

func get_new_board_position():
	return new_board_position

func set_new_board_position(p: Vector2i):
	new_board_position = p

func get_tagged():
	return tagged

func set_tagged(t: bool):
	tagged = t

func get_sprite():
	return $AnimatedSprite2D

func play_animation(animation: String):
	$AnimatedSprite2D.animation = animation
	$AnimatedSprite2D.play()

func move():
	board_position = new_board_position
	set_sprite_position(BoardGeometry.center(board_position.x, board_position.y))

func promote(promote_key = "q"):
	set_type(side, promote_key.to_upper())
	promoted = true
