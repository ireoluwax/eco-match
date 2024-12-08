extends Node2D

var card_scene = ResourceLoader.load("res://card.tscn")  # Reference to the card scene

# Reference the AudioStreamPlayer node
var audio_player : AudioStreamPlayer

var first_flipped_card = null
var cards = []

# Game variables
var points = 0
@export var time_left = 120  # Initial time
@onready var TimerLabel = $TimerLabel  # Label to display timer
@onready var PointsLabel = $PointsLabel  # Points label to display the points
@onready var lucky_guy_font = load("res://assets/fonts/LuckiestGuy-Regular.ttf")

var game_active: bool = true # I'm tracking when game is active to disable interactions.

func _ready():
	# Start the timer and connect the timeout signal
	$GameTimer.start(1)  # Start the timer with 1 second interval
	TimerLabel.text = "Remaining Time: " + str(time_left)
	TimerLabel.add_theme_font_override("font", lucky_guy_font)
	TimerLabel.add_theme_font_size_override("font_size", 14)  # Set font size
	TimerLabel.add_theme_color_override("font_color", Color(1, 0.5, 0))  # Green color
	
	PointsLabel.text = "Points: " + str(points)
	PointsLabel.add_theme_font_override("font", lucky_guy_font)
	PointsLabel.add_theme_font_size_override("font_size", 14)  # Set font size
	PointsLabel.add_theme_color_override("font_color", Color(0.5, 1, 0))  # Green color
	
	# Play background music
	_play_background_music()
	
	TimerLabel.set_position(Vector2(20, 623))
	PointsLabel.set_position(Vector2(280, 623))
	
	# Connect the timeout signal to the update function
	$GameTimer.connect("timeout", Callable(self, "_update_timer_label"))
	
	# Load and shuffle textures
	var textures = preload_card_textures()
	textures.shuffle()

	# Set up GridContainer layout
	$GridContainer.columns = 4  # Number of cards per row

	# Set spacing using theme overrides
	$GridContainer.add_theme_constant_override("hseparation", 10)  # Horizontal spacing
	$GridContainer.add_theme_constant_override("vseparation", 10)  # Vertical spacing

	# Create cards and add them to the grid
	for i in range(16):  # 8 pairs of cards (16 cards total)
		var front_texture = textures.pop_front()
		var back_texture = preload("res://assets/textures/back_flip.jpg")  # Path to the back texture

		# Instantiate a card instance
		var card_instance = card_scene.instantiate()
		
		# Connect the card's clicked signal
		card_instance.connect("card_clicked", Callable(self, "_on_card_clicked"))
		
		# Set the card's textures
		card_instance.front_texture = front_texture
		card_instance.back_texture = back_texture
		
		# Set a consistent card size
		card_instance.card_size = Vector2(100, 150)  # Example size; adjust as needed

		# Add the card to the GridContainer and store in the cards array
		$GridContainer.add_child(card_instance)
		cards.append(card_instance)
	
	# Connect timer signals
	#$GameTimer.connect("timeout", Callable(self, "_on_time_up"))
	#$GameTimer.connect("time_left", Callable(self, "_update_timer_label"))
	
func _play_background_music():
	# Create and add the AudioStreamPlayer node to the scene
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Load the audio file (make sure the path is correct)
	var sound = load("res://assets/audio/piano.ogg") as AudioStream

	# Enable looping on the AudioStream
	sound.loop = true
	
	# Set the audio stream for the player
	audio_player.stream = sound
	
	# Play the audio
	audio_player.play()

func _on_card_clicked(card):
	#print("Card clicked: ", card)
	
	if not game_active or card.is_flipped or card.is_matched:
		#print("Card is already flipped or matched, ignoring...")
		return

	#print("Flipping the card!")
	card.flip_card()

	if first_flipped_card == null:
		#print("First card flipped!")
		first_flipped_card = card
	else:
		#print("Second card flipped, comparing...")
		if first_flipped_card.front_texture == card.front_texture:
			#print("Cards match!")
			first_flipped_card.match_card()
			card.match_card()
			_on_card_matched()
		else:
			#print("Cards do not match, flipping back...")
			await get_tree().create_timer(1.0).timeout
			first_flipped_card.flip_card()
			card.flip_card()
			_on_incorrect_match()

		first_flipped_card = null


# Function to update points
func _update_points(points_to_add: int):
	points += points_to_add  # Add or subtract points
	PointsLabel.text = "Points: " + str(points)  # Update the points label
	
func _check_all_cards_matched() -> bool:
	for card in cards:
		if not card.is_matched:  # If any card is not matched, return false
			return false
	return true  # All cards are matched

# Call this function whenever the player makes a correct match
func _on_card_matched():
	_update_points(10)  # Adds 10 points when a match is made
	
	# Check if all cards are matched
	if _check_all_cards_matched():
		_on_game_won()

# Call this function whenever the player makes an incorrect match
func _on_incorrect_match():
	_update_points(-2)  # Deducts 5 points for an incorrect match


func _on_time_up():
	$TimerLabel.text = "Time Over!!!"
	#print("Game over! Final points: ", points)
	
	# Stop the background music
	if audio_player:
		audio_player.stop()
	
	# Disable interactivity
	game_active = false
	
	# Stop the timer
	$GameTimer.stop()
	
	# Create a Game Over screen dynamically
	var game_over_popup = create_game_over_popup()
	add_child(game_over_popup)

	
func _update_timer_label():
	if game_active:
		time_left -= 1
		$TimerLabel.text = "Remaining Time: " + str(time_left)
		if time_left <= 0:
			_on_time_up()
		
func create_game_over_popup() -> Control:
	# Create a container for the popup
	var popup = Control.new()
	popup.name = "GameOverPopup"
	popup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup.custom_minimum_size = Vector2(300, 200)
	popup.anchor_right = 1
	popup.anchor_bottom = 1

	# Add a background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)  # Semi-transparent black
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup.add_child(bg)
	
	# Create a VBoxContainer for layout
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.anchor_left = 0.2
	container.anchor_right = 0.8
	container.anchor_top = 0.2
	container.anchor_bottom = 0.8
	#container.alignment = BoxContainer.ALIGN_CENTER
	popup.add_child(container)

	# Add a title (Game Over)
	var title_label = Label.new()
	title_label.text = "Game Over"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_FILL
	
	# Create a DynamicFont and assign it to the label
	title_label.add_theme_font_override("font", lucky_guy_font)
	title_label.add_theme_font_size_override("font_size", 64)
	
	# Styling the title label (color)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.02, 0.03))  # Red color
	title_label.set_position(Vector2(40, 100))
	popup.add_child(title_label)

	# Add the final score
	var score_label = Label.new()
	score_label.text = "Final Score: %d" % points
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.size_flags_vertical = Control.SIZE_FILL
	score_label.set_position(Vector2(100, 180))
	score_label.add_theme_font_override("font", lucky_guy_font)
	score_label.add_theme_font_size_override("font_size", 32)
	popup.add_child(score_label)

	# Add restart button
	var restart_button = Button.new()
	restart_button.text = "Play Again"
	restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_button.set_position(Vector2(158, 260))
	restart_button.custom_minimum_size = Vector2(100, 40)
	restart_button.add_theme_color_override("font_color", Color(1, 0.5, 0))
	restart_button.add_theme_font_override("font", lucky_guy_font)
	restart_button.add_theme_font_size_override("font_size", 14)
	restart_button.connect("pressed", Callable(self, "_on_restart_pressed"))
	popup.add_child(restart_button)
	
	# Add Go to Main Menu Button
	var main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_menu_button.set_position(Vector2(158, 340))
	main_menu_button.custom_minimum_size = Vector2(100, 40)
	main_menu_button.add_theme_color_override("font_color",Color(0.5, 1, 0))
	main_menu_button.add_theme_font_override("font", lucky_guy_font)
	main_menu_button.add_theme_font_size_override("font_size", 14)
	main_menu_button.connect("pressed", Callable(self, "_on_main_menu_pressed"))
	popup.add_child(main_menu_button)

	# Add exit button
	var exit_button = Button.new()
	exit_button.text = "Exit"
	exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_button.set_position(Vector2(158, 420))
	exit_button.custom_minimum_size = Vector2(100, 40)
	exit_button.add_theme_color_override("font_color", Color(0.9, 0.02, 0.03))
	exit_button.add_theme_font_override("font", lucky_guy_font)
	exit_button.add_theme_font_size_override("font_size", 14)
	exit_button.connect("pressed", Callable(self, "_on_exit_pressed"))
	popup.add_child(exit_button)

	return popup



func _on_restart_pressed():
	# Restart the game (reload the scene)
	get_tree().reload_current_scene()
	
func _on_main_menu_pressed():
	# Go to Main Menu
	#var game_scene = preload("res://start_screen.tscn") as PackedScene
	get_tree().change_scene_to_file("res://start_screen.tscn")

func _on_exit_pressed():
	# Exit the game
	get_tree().quit()

# Method to get the game state
func get_game_active() -> bool:
	return game_active
	
func _on_game_won():
	# Stop the background music
	if audio_player:
		audio_player.stop()
	
	# Disable interactivity
	game_active = false
	
	# Create a "You Win" screen
	var win_popup = create_win_popup()
	add_child(win_popup)

	
func create_win_popup() -> Control:
	# Create a container for the popup
	var popup = Control.new()
	popup.name = "YouWinPopup"
	popup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup.custom_minimum_size = Vector2(300, 200)
	popup.anchor_right = 1
	popup.anchor_bottom = 1

	# Add a background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)  # Semi-transparent black background
	bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup.add_child(bg)
	
	# Create a VBoxContainer for layout
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.anchor_left = 0.2
	container.anchor_right = 0.8
	container.anchor_top = 0.2
	container.anchor_bottom = 0.8
	popup.add_child(container)

	# Add a title (You Win)
	var title_label = Label.new()
	title_label.text = "You Win!"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_FILL
	
	# Create a DynamicFont and assign it to the label
	title_label.add_theme_font_override("font", lucky_guy_font)
	title_label.add_theme_font_size_override("font_size", 64)
	
	# Styling the title label (color)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.02, 0.03))  # Red color
	title_label.set_position(Vector2(75, 100))
	popup.add_child(title_label)

	# Add the final score
	var score_label = Label.new()
	score_label.text = "Final Score: %d" % points
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.size_flags_vertical = Control.SIZE_FILL
	score_label.set_position(Vector2(100, 180))
	score_label.add_theme_font_override("font", lucky_guy_font)
	score_label.add_theme_font_size_override("font_size", 32)
	popup.add_child(score_label)

	# Add Next Level button
	var next_level_button = Button.new()
	next_level_button.text = "Next Level"
	next_level_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_level_button.set_position(Vector2(158, 260))
	next_level_button.custom_minimum_size = Vector2(100, 40)
	next_level_button.add_theme_color_override("font_color", Color(1, 0.5, 0))
	next_level_button.add_theme_font_override("font", lucky_guy_font)
	next_level_button.add_theme_font_size_override("font_size", 14)
	next_level_button.connect("pressed", Callable(self, "_on_restart_pressed"))
	popup.add_child(next_level_button)
	
	# Add Go to Main Menu Button
	var main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_menu_button.set_position(Vector2(158, 340))
	main_menu_button.custom_minimum_size = Vector2(100, 40)
	main_menu_button.add_theme_color_override("font_color",Color(0.5, 1, 0))
	main_menu_button.add_theme_font_override("font", lucky_guy_font)
	main_menu_button.add_theme_font_size_override("font_size", 14)
	main_menu_button.connect("pressed", Callable(self, "_on_main_menu_pressed"))
	popup.add_child(main_menu_button)

	# Add exit button
	var exit_button = Button.new()
	exit_button.text = "Exit"
	exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_button.set_position(Vector2(158, 420))
	exit_button.custom_minimum_size = Vector2(100, 40)
	exit_button.add_theme_color_override("font_color", Color(0.9, 0.02, 0.03))
	exit_button.add_theme_font_override("font", lucky_guy_font)
	exit_button.add_theme_font_size_override("font_size", 14)
	exit_button.connect("pressed", Callable(self, "_on_exit_pressed"))
	popup.add_child(exit_button)

	return popup

	
func preload_card_textures():
	# Load all textures and return as a list
	return [
		preload("res://assets/textures/card-01.jpg"),
		preload("res://assets/textures/card-01.jpg"),
		preload("res://assets/textures/card-02.jpg"),
		preload("res://assets/textures/card-02.jpg"),
		preload("res://assets/textures/card-03.jpg"),
		preload("res://assets/textures/card-03.jpg"),
		preload("res://assets/textures/card-04.jpg"),
		preload("res://assets/textures/card-04.jpg"),
		preload("res://assets/textures/card-05.jpg"),
		preload("res://assets/textures/card-05.jpg"),
		preload("res://assets/textures/card-06.jpg"),
		preload("res://assets/textures/card-06.jpg"),
		preload("res://assets/textures/card-07.jpg"),
		preload("res://assets/textures/card-07.jpg"),
		preload("res://assets/textures/card-08.jpg"),
		preload("res://assets/textures/card-08.jpg"),
	]
