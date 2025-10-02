extends Node2D

@export var ground_type_ru: String = "земля"
@export var ground_type_fr: String = "terre"

var ground_colors = [Color.GREEN, Color.DARK_GREEN, Color.SADDLE_BROWN, Color.DARK_GRAY]
var sprite: Sprite2D

func _ready():
	# Créer le Sprite2D s'il n'existe pas
	create_sprite_if_needed()
	
	
	print("Ground créé à: ", position)

func create_sprite_if_needed():
	# Chercher un Sprite2D existant
	sprite = find_child("Sprite2D", true, false) as Sprite2D
	
	# Si pas trouvé, en créer un nouveau
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
		print("Sprite2D créé automatiquement")
	
	# Appliquer une texture/ couleur
	var texture = create_color_texture(ground_colors[randi() % ground_colors.size()], 64, 64)
	sprite.texture = texture

func create_color_texture(color: Color, width: int, height: int) -> Texture2D:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func get_ground_name(language: String = "ru") -> String:
	return ground_type_ru if language == "ru" else ground_type_fr
