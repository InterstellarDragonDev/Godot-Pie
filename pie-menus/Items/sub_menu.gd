extends Node2D

var title : String 
var icon_path : String
var target_position : Vector2 = Vector2.ZERO

var item = preload("res://Items/item_modern.tscn")
var items = []
var total_items : int = 4

var animate_speed : float = 0.1
var item_rotation : float = 0.0


enum STATES {ACTIVE, IDLE}
var state = STATES.IDLE

var is_mouse_within : bool = false
var is_button_pressed : bool = false

signal load_submenu
signal change_speed_mode

@export var TEXT_BOX : Label
@export var ICON : TextureRect
@export var BUTTON : TextureButton
@export var ANIM : AnimationPlayer

@export var LEFTPANE : GridContainer
@export var RIGHTPANE : GridContainer
var TEXTURE_RECT = preload("res://texture_rect.tscn")

func _ready():
	TEXT_BOX.text = title
	if TEXT_BOX.text.length() > 14:
		TEXT_BOX.set("theme_override_font_sizes/font_size", 30)
	
	if icon_path == "":
		icon_path = "res://icon.svg"
	
	var img = Image.new()
	var err = img.load(icon_path)
	var texture = ImageTexture.new()
	texture.set_image(img)
	ICON.texture = texture
	
	BUTTON.mouse_entered.connect(_mouse_entered)
	BUTTON.mouse_exited.connect(_mouse_exited)
	BUTTON.button_down.connect(button_down)
	BUTTON.button_up.connect(_button_up)
	
	spawn_side_pane_icons()

func spawn_side_pane_icons():
	for i in items.size():
		if i > 8:
			return
			
		var t = TEXTURE_RECT.instantiate()
		var img = Image.new()
		var err = img.load(items[i].icon_path)
		var texture = ImageTexture.new()
		texture.set_image(img)
		t.texture = texture
		
		if i % 2 == 0:
			LEFTPANE.add_child(t)
		else:
			RIGHTPANE.add_child(t)

func _physics_process(delta):
	position = lerp(position, target_position, animate_speed)

func _mouse_entered() -> void:
	is_mouse_within = true
	ANIM.queue("focus")
	change_speed_mode.emit()

func _mouse_exited() -> void:
	is_mouse_within = false
	ANIM.queue("unfocus")
	change_speed_mode.emit()


func button_down():
	ANIM.queue("click")
func _button_up():
	released()

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and is_mouse_within:
			#ANIM.queue("click")
			#is_button_pressed = true
		#if not event.pressed and is_button_pressed:
			#released()

func released():
	ANIM.queue("release")
	is_button_pressed = false
	load_submenu.emit(self)
