extends Node2D

const MARGIN = 5
const BOARD_SIZE = 40
const N_TREES = 10
const APPLE = 3
const SNAKE = 2
const TREE = 1
const BLANK = 0
const INIT_CLOCK_SPEED = 0.1
const RAMP_FACTOR = 0.05
const DEAD = 4

var state = {}
var display = []

func _ready():
	randomize()
	init_board()
	add_snake()
	add_apple()
	add_trees()
	state["score"] = 0
	state["direction"] = Vector2(0, 0)
	state["clock"] = Timer.new()
	add_child(state["clock"])
	state["clock"].connect("timeout", self, "tick")
	state["clock"].wait_time = INIT_CLOCK_SPEED
	state["clock"].one_shot = false
	state["clock"].start()

func score(n):
	state["score"] += n
	print("score = %s" % n)

func init_board():
	state["board"] = []
	for x in range(BOARD_SIZE):
		state["board"].append([])
		display.append([])
		for y in range(BOARD_SIZE):
			state["board"][x].append({"value": 0})
			display[x].append(ColorRect.new())
			add_child(display[x][y])
			display[x][y].rect_size = Vector2(1, 1)
			display[x][y].rect_position = Vector2(MARGIN + x, MARGIN + y)

func rand_empty_pixel():
	var x = rand_range(0, 39)
	var y = rand_range(0, 39)
	while state["board"][x][y]["value"] != BLANK:
		x = rand_range(0, 39)
		y = rand_range(0, 39)
	return Vector2(x, y)

func add_snake():
	var vect = put_rand_pixel(SNAKE)
	state["snake"] = [vect]

func add_trees():
	for _i in range(N_TREES):
		put_rand_pixel(TREE)

func add_apple():
	put_rand_pixel(APPLE)

func put_rand_pixel(object):
	var vect = rand_empty_pixel()
	put_pixel(vect, object)
	return vect

func put_pixel(vect, object):
	state["board"][vect.x][vect.y]["value"] = object

func _process(_delta):
	if Input.is_action_just_pressed("ui_up"):
		if state["direction"].y == 0:
			state["direction"] = Vector2(0, -1)
	elif Input.is_action_just_pressed("ui_down"):
		if state["direction"].y == 0:
			state["direction"] = Vector2(0, 1)
	elif Input.is_action_just_pressed("ui_left"):
		if state["direction"].x == 0:
			state["direction"] = Vector2(-1, 0)
	elif Input.is_action_just_pressed("ui_right"):
		if state["direction"].x == 0:
			state["direction"] = Vector2(1, 0)
	render_graphics()

func out_of_bounds(vect):
	return vect.x < 0 || vect.y < 0 || vect.x >= BOARD_SIZE || vect.y >= BOARD_SIZE

func tick():
	if state["direction"].x == 0 && state["direction"].y == 0:
		return
	var next_pos = Vector2(
		state["direction"].x + state["snake"][-1].x,
		state["direction"].y + state["snake"][-1].y
	)
	
	if out_of_bounds(next_pos):
		game_over()
		return

	match state["board"][next_pos.x][next_pos.y]["value"]:
		APPLE:
			put_pixel(next_pos, SNAKE)
			state["snake"].push_back(next_pos)
			score(1)
			$Chomp.play(0.08)
			state["clock"].wait_time = state["clock"].wait_time * (1 - RAMP_FACTOR)
			add_apple()
		TREE, SNAKE:
			game_over()
			return
		BLANK:
			put_pixel(next_pos, SNAKE)
			state["snake"].push_back(next_pos)
			put_pixel(state["snake"].pop_front(), BLANK)

func game_over():
	print("game over!")
	state["clock"].disconnect("timeout", self, "tick")
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			put_pixel(Vector2(x, y), DEAD)
	state["clock"].connect("timeout", self, "quit")
	state["clock"].wait_time = 1
	state["clock"].start()
	
func quit():
	get_tree().quit()

func render_graphics():
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			display[x][y].color = color_for_value(state["board"][x][y]["value"])

func color_for_value(value):
	match value:
		BLANK: return Color.black
		TREE: return Color.yellow
		SNAKE: return Color.green
		APPLE: return Color.red
		DEAD: return Color.red
