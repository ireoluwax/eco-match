extends Control

@onready var title_label = Label.new()
@onready var objective_label = Label.new()

# Load Font
@onready var lucky_guy_font = load("res://assets/fonts/LuckiestGuy-Regular.ttf")

func _ready():
	# Add and style the title label
	title_label.text = "Eco-Match"
	title_label.set_position(Vector2(100, 70))  # Adjust position as needed
	title_label.add_theme_font_override("font", lucky_guy_font)
	title_label.add_theme_font_size_override("font_size", 64)  # Set font size
	title_label.add_theme_color_override("font_color", Color(0.5, 1, 0))  # Orange color
	add_child(title_label)
	
	# Add and style the objective label
	objective_label.text = "Challenge 1: You're in a beautiful world, but Climate Change is threatening Us!   Your Duty is to match the Cards on the     screen to prevent further environmental crisis."
	objective_label.set_position(Vector2(100, 220))  # Adjust position as needed
	objective_label.add_theme_font_override("font", lucky_guy_font)
	objective_label.add_theme_font_size_override("font_size", 24)  # Set font size
	objective_label.add_theme_color_override("font_color", Color(1, 7, 2))  # Green color
	
	objective_label.autowrap_mode = true
	objective_label.custom_minimum_size = Vector2(478, 0)
	add_child(objective_label)

	# Add a start button
	var start_button = Button.new()
	start_button.text = "Start Game"
	start_button.set_position(Vector2(100, 470))  # Adjust position as needed
	start_button.add_theme_font_override("font", lucky_guy_font)
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.add_theme_color_override("font_color", Color(0.5, 1, 0))
	start_button.custom_minimum_size = Vector2(180, 60)
	start_button.connect("pressed", Callable(self, "_on_start_button_pressed"))
	add_child(start_button)

func _on_start_button_pressed():
	# Change to the main game scene
	var game_scene = preload("res://main.tscn")
	get_tree().change_scene_to_packed(game_scene)
