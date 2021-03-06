extends Spatial

var is_pressed = false
var last_position = Vector2(0,0)

var multiplayer_room = null


func _ready():
	if len(OS.get_cmdline_args()) > 0:
		var arg = OS.get_cmdline_args()[0]
		if arg.find("room:") >= 0:
			get_node("Viewport/CanvasLayer/Code").text = arg.split(":")[1]
	multiplayer_room = get_tree().current_scene.get_node("MultiplayerRoom")

var frame_count = 0
func _process(delta):
	if frame_count == 0:
		if multiplayer_room.room and multiplayer_room.room != get_node("Viewport/CanvasLayer/Code").text :
			 get_node("Viewport/CanvasLayer/Code").text = multiplayer_room.room
	frame_count = (frame_count + 1)%20


#func release_event():
#	if is_pressed:
#		is_pressed = false
#		print ("Release event")
#		var ev = InputEventMouseButton.new()
#		ev.button_index=BUTTON_LEFT
#		ev.pressed = false
#		ev.position = last_position
#		get_node("Viewport").input(ev)
#	else:
#		print ("Release without click not possible")
#
#func click_event(position):
#	var viewport = get_node("Viewport")
#	var ev = InputEventMouseButton.new()
#
#	if is_pressed:
#		#We don't want a release/click event so it's either release
#		#or click not both
#		print ("Is clicked. Release first")
#		release_event()
#	else:
#		ev.button_index=BUTTON_LEFT
#		ev.pressed = true
#		ev.position = Vector2(viewport.size[0]*position[0], viewport.size[1]*position[1])
#		last_position = ev.position
#		is_pressed = true
#
#		print ("P: %s"%str(ev.position))
#		viewport.input(ev)



func _on_Button_button_down(character):
	get_node("Viewport/CanvasLayer/Code").text += character


func _on_Clear_button_down():
	get_node("Viewport/CanvasLayer/Code").text = ""


func _on_CreateRoom_button_down():
	if multiplayer_room:
		multiplayer_room.connect_to_server(GameVariables.multiplayer_server, "")
	
func _on_ExitRoom_button_down():
	if multiplayer_room:
		multiplayer_room.disconnect_from_server()


func _on_Enter_Room_pressed():
	#TODO: check if it's already connected and handle accordingly
	if multiplayer_room:
		multiplayer_room.connect_to_server(GameVariables.multiplayer_server, get_node("Viewport/CanvasLayer/Code").text)
	 
