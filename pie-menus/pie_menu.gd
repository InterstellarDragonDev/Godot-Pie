extends Node2D

const UDP_IP = "127.0.0.1"
const UDP_PORT = 42069
var server := UDPServer.new()

var ITEM = preload("res://Items/item_modern.tscn")
#var ITEM = preload("res://Items/item_circle.tscn")
var SUBMENU = preload("res://Items/sub_menu.tscn")
@onready var ROOT = $centre
@onready var ROOT_ICON = $"centre/clipping mask/icon"
@onready var CENTRE_ANIM = $"centre/clipping mask/icon/anim"

var submenu_data = []
var root_item_data = []
var items = []
var total_items : int = 4
var current_section : int = 0
var speed_mode : bool = true
var within_submenu : bool = false

var lines = []
var LINE2D = preload("res://line_2d.tscn")
var line_settings = {
	"connecting_lines" : true,
	"thickness" : 3.0,
	"colour" : Color(1, 1, 1, 0.5)
}

var config = ConfigFile.new()
var config_path = OS.get_environment("HOME") + "/.config/godot-pie"

var settings = {
	"animate_speed" : 0.2,
	"radius" : 250,
	"global_rotation" : 0,
	"fading" : false,
	"dynamic_movement" : false,
	"clip_circle" : false,
	"centre_pointer" : false,
	"centre_icon" : "res://icon.svg",
	"run_method" : "godot"
	}

# for fancy movement
var min_dist : int = 50
var max_dist : int
var min_converted : int = 0
var max_converted : int = 70

var root_rotation : float

class SUBMENU_DATA:
	var title : String
	var icon_path : String
	var rotation : float
	var items : Array
	
	func _init(t, i, r):
		title = t
		icon_path = i
		rotation = r


func store_items(title, parent, icon_path, command):
	var item = ITEM_DATA.new(title, icon_path, command)
	
	if parent == "root":
		root_item_data.append(item)
		print("storing item: " + title + " in root")
		return
	else:
		for i in submenu_data:
			if i.title == parent:
				i.items.append(item)
				print("storing item: " + title + " in " + parent)
				return
	
	printerr("the root for item: " + title + " does not exist")

func create_item(item : ITEM_DATA):
	var e = ITEM.instantiate()
	e.title = item.title
	e.icon_path = item.icon_path
	e.launch_command = item.command
	e.animate_speed = settings["animate_speed"]
	e.change_speed_mode.connect(_change_speed_mode)
	e.execute.connect(send_execute_data)
	e.ERROR_LABEL = $ErrorLabel
	
	ROOT.add_child(e)
	items.append(e)
	e.position = Vector2.ZERO
	total_items = items.size()
	update_item_position()
	print("created item: " + item.title)

func store_submenu(title, icon_path, rotation):
	var s = SUBMENU_DATA.new(title, icon_path, rotation)
	submenu_data.append(s)
	root_item_data.append(s)

func create_submenu(submenu : SUBMENU_DATA):
	var s = SUBMENU.instantiate()
	s.title = submenu.title
	s.icon_path = submenu.icon_path
	s.item_rotation = submenu.rotation
	s.items.append_array(submenu.items)
	s.animate_speed = settings["animate_speed"]
	s.change_speed_mode.connect(_change_speed_mode)
	s.load_submenu.connect( _load_submenu)
	ROOT.add_child(s)
	
	items.append(s)
	s.position = Vector2.ZERO
	total_items = items.size()
	update_item_position()

func remove_item():
	items[-1].queue_free()
	items.pop_back()
	total_items = items.size()
	update_item_position()

func clear_items():
	if items.size() > 0:
		for i in items.size():
			items[i].queue_free()
		items.clear()


func spawn_line():
	var l : Line2D = LINE2D.instantiate()
	l.gradient.set_color(1, line_settings["colour"])
	l.width = line_settings["thickness"]
	
	for i in range(6):
		l.add_point(Vector2.ZERO)
	
	$centre/Lines.add_child(l)
	
	lines.append(l)

func create_lines():
	for i in items:
		spawn_line()

func remove_line():
	lines[-1].queue_free()
	lines.pop_back()

func update_lines():
	for i in range(abs(items.size() - lines.size())):
		if items.size() > lines.size():
			spawn_line()
		else:
			remove_line()

func remap_lines():
	if line_settings["connecting_lines"] == false:
		return
	if items.size() != lines.size():
		return
	
	for i : int in lines.size():
		
		# that little float(j) nonsense drove me insane.............fuck you j 
		for j in lines[i].get_point_count():
			var new_point = lerp(Vector2.ZERO, items[i].position, snappedf(float(j) / (lines[i].get_point_count() - 1), 0.00))
			lines[i].set_point_position(j, new_point)

func update_item_position():
	if items.size() == 0:
		return
	var theta = (2 * PI) / total_items
	for i in total_items:
		items[i].target_position = Vector2(settings["radius"] * cos(theta * i + PI/total_items + settings["global_rotation"]), settings["radius"] * sin(theta * i + PI/total_items + settings["global_rotation"]))
		if settings["fading"] or settings["dynamic_movement"]:
			var vector_to_cursor = $centre.position - get_global_mouse_position()
			vector_to_cursor = vector_to_cursor.normalized()
			var dist_to_cursor = Vector2(items[i].target_position + $centre.position).distance_to(get_global_mouse_position())
			var dist_cursor_to_centre = Vector2(400, 400).distance_to(get_global_mouse_position())
			var cursor_to_centre_weight = dist_cursor_to_centre / (settings["radius"] * 2)

			dist_to_cursor = clamp(dist_to_cursor, min_dist, max_dist)

			
			var distance_range = max_dist - min_dist
			var converted_range = max_converted - min_converted
			var converted_distance = (((dist_to_cursor - min_dist) * converted_range) / distance_range) + min_converted
			if settings["dynamic_movement"]:
				items[i].target_position += vector_to_cursor * converted_distance  * cursor_to_centre_weight
			if settings["fading"]:
				items[i].modulate.a = 1 - converted_distance / max_converted
				
	remap_lines()

# draws lines
#func _draw():
	#var arr : PackedVector2Array
	#for i in items:
		#arr.append(i.global_position)
		#arr.append($centre.global_position)
	#draw_multiline(arr, Color(0.8, 0.8, 0.8, 0.05), 2, true)

# draws all the points of the connector lines
#func _draw():
	#for i : Line2D in lines:
		#for j in i.get_point_count():
			#var temp = i.get_point_position(j) + $centre.global_position
			#draw_circle(temp, 5, Color.RED)

func create_config():
	print("creating config....")
	
	#Global Settings
	for keys in settings.keys():
		config.set_value("Settings", keys, settings[keys])
	
	for keys in line_settings.keys():
		config.set_value("Line_Settings", keys, line_settings[keys])
	
	# Example Item
	config.set_value("Button 1", "Name", "ExampleButton")
	config.set_value("Button 1", "Type", "item")
	config.set_value("Button 1", "IconPath", "")
	config.set_value("Button 1", "parent", "root")
	config.set_value("Button 1", "Command", "xterm -e curl parrot.live")
	
	# Example Submenu
	config.set_value("Submenu 1", "Name", "ExampleSubmenu")
	config.set_value("Submenu 1", "Type", "sub-menu")
	config.set_value("Submenu 1", "IconPath", "")
	config.set_value("Submenu 1", "rotation", 0.0)
	
	var err = config.save(config_path + "/config.cfg")
	print("Save File Returned: " + str(err))
	$ErrorLabel.set("theme_override_colors/font_color", Color.GREEN)
	$ErrorLabel.text = "A New config file has been successfully made! It can be found at '" + config_path + "'. This app can be closed and reopened for the new config file to be loaded"

func load_config():
	print("loading config")
	for i in config.get_section_keys("Settings"):
		settings[i] = config.get_value("Settings", i)
		
	for i in config.get_section_keys("Line_Settings"):
		line_settings[i] = config.get_value("Line_Settings", i)
	
	if settings["clip_circle"]:
		$"centre/clipping mask".self_modulate = Color.WHITE
		$"centre/clipping mask".clip_children = CLIP_CHILDREN_ONLY
	
	if settings["centre_pointer"] == false:
		$centre/pointer.hide()
	
	root_rotation = settings["global_rotation"]
	for i in config.get_sections():
		_spawn_item_from_section(i)
	
	create_root_layout()
	
	if line_settings["connecting_lines"]:
		create_lines()

func create_root_layout():
	for i in root_item_data:
		if i is ITEM_DATA:
			create_item(i)
		elif i is SUBMENU_DATA:
			create_submenu(i)
		
	update_root_icon(settings["centre_icon"])

func update_root_icon(image):
	var img = Image.new()
	var img_err = img.load(image)
	var texture = ImageTexture.new()
	texture.set_image(img)
	ROOT_ICON.texture = texture

func _spawn_item_from_section(item):
	if item == "Settings":
		return
	if item == "Line_Settings":
		return
	
	if config.get_value(item, "Type")== "sub-menu":
		store_submenu(config.get_value(item, "Name"), config.get_value(item, "IconPath"), config.get_value(item, "rotation"))
	elif config.get_value(item, "Type") == "item":
		store_items(config.get_value(item, "Name"), config.get_value(item, "parent"), config.get_value(item, "IconPath"), config.get_value(item, "Command"))
	else:
		
		$ErrorLabel.text += "\n" + "The 'Type' attribute for '" + config.get_value(item, "Name") + "' was specified incorrectly.'Type' can only be either 'sub-menu' or 'item'."

func _ready():
	get_viewport().warp_mouse(Vector2(399, 399))
	CENTRE_ANIM.play("hover")
	if OS.get_name() == "Windows":
		config_path = OS.get_environment("APPDATA") + "/godot-pie"
			
	var err = config.load(config_path + "/config.cfg")
	if err != OK:
		if not DirAccess.dir_exists_absolute(config_path):
			DirAccess.make_dir_recursive_absolute(config_path)
		create_config()
	else:
		load_config()
	max_dist = settings["radius"] * 2
	
	if settings["run_method"] not in ["godot", "daemon"]:
		$ErrorLabel.text += "\n" +  "'" + settings["run_method"] + "' is not a valid run method. Must be either 'default', 'legacy', 'daemon'."

func _physics_process(delta):
	if Input.is_action_pressed("ui_left"):
		settings["global_rotation"] -= 0.05
		print("rotated " + str(root_rotation - settings["global_rotation"]) + "radians from initial rotation")
		update_item_position()
	if Input.is_action_pressed("ui_right"):
		settings["global_rotation"] += 0.05
		print("rotated " + str(root_rotation - settings["global_rotation"]) + "radians from initial rotation")
		update_item_position()
	
	update_item_position()
	var angle = $centre/pointer.get_angle_to(get_global_mouse_position())
	$centre/pointer.rotation =  lerp($centre/pointer.rotation, $centre/pointer.rotation + angle + PI/2, 0.2)

func _input(event):

	if event.is_action_pressed("ui_cancel"):
		_on_centre_button_pressed()

	if event is InputEventMouseButton and event.is_released()  and event.button_index == MOUSE_BUTTON_LEFT:
		var closest
		var dist = 100000
		for i in items:
			var temp = i.global_position.distance_to(get_global_mouse_position())
			if temp < dist:
				dist = temp
				closest = i
		
		if dist < settings["radius"] / 2:
			closest.released()

func send_execute_data(data : String):

	match settings["run_method"].to_lower():
		
		"godot":
			print("used godot")
			var arguements : PackedStringArray = []
		
			if " " in data:
				arguements = data.split(" ")
				data = arguements[0]
				arguements.remove_at(0)
				print("arguements: ")
				print(arguements)
			OS.execute_with_pipe(data, arguements, false)
		
		"daemon":
			var formated_data = "exe: " + data + "%"
			var peer : PacketPeerUDP = PacketPeerUDP.new()
			peer.set_dest_address(UDP_IP, UDP_PORT)
			peer.put_packet(formated_data.to_ascii_buffer())
			peer.close()


func _load_submenu(submenu):
	
	clear_items()
	
	total_items = 0
	print(submenu.items)
	for i in submenu.items:
		create_item(i)
	
	if line_settings["connecting_lines"]:
		update_lines()
	
	within_submenu = true
	update_root_icon(submenu.icon_path)
	settings["global_rotation"] = submenu.item_rotation
	get_viewport().warp_mouse(Vector2(399, 399))
	CENTRE_ANIM.play("hover")

func _change_speed_mode():
	speed_mode = not speed_mode


func _on_centre_button_pressed():
	if within_submenu:
		clear_items()
		settings["global_rotation"] = root_rotation
		create_root_layout()
		within_submenu = false
		update_lines()
		
		get_viewport().warp_mouse(Vector2(399, 399))
		CENTRE_ANIM.play("hover")
	else:
		get_tree().quit(0)


func _on_centre_button_mouse_entered():
	CENTRE_ANIM.play("hover")
	speed_mode = false

func _on_centre_button_mouse_exited():
	CENTRE_ANIM.play("unhover")
	speed_mode = true
