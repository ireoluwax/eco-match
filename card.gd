extends Control

signal card_clicked(card)

@export var front_texture: Texture2D
@export var back_texture: Texture2D
@export var card_size: Vector2 = Vector2(120, 150)  # Card dimensions

var is_flipped = false
var is_matched = false
var game_active : bool = true  # Default to true, but will be updated from main.gd

func _ready():
	# Assign textures to TextureRects
	if $FrontTexture:
		$FrontTexture.texture = front_texture
		$FrontTexture.scale = card_size / front_texture.get_size()
	if $BackTexture:
		$BackTexture.texture = back_texture
		$BackTexture.scale = card_size / back_texture.get_size()

	# Ensure the size of the card matches the desired dimensions
	adjust_card_size()

	update_card_texture()

	# Get the parent node (Main Game Node) and update the game_active state
	var parent = get_parent()
	if parent.has_method("get_game_active"):
		game_active = parent.get_game_active()  # This ensures we're getting the value safely

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if is_flipped or is_matched or not game_active:  # Check game_active here
			return
		emit_signal("card_clicked", self)

func flip_card():
	is_flipped = !is_flipped
	update_card_texture()

func match_card():
	is_matched = true
	update_card_texture()

func update_card_texture():
	# Show the appropriate texture
	$FrontTexture.visible = is_flipped or is_matched
	$BackTexture.visible = not is_flipped and not is_matched

func adjust_card_size():
	custom_minimum_size = card_size  # Enforce the card's size
