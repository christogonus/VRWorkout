extends Spatial

signal recenter_scene()

var level_blueprint = null 
var levelselect_blueprint = null  
var splashscreen = preload("res://Splashscreen.tscn").instance()
var left_controller_blueprint = preload("res://Left_Controller_Tree.tscn")
var right_controller_blueprint = preload("res://Right_Controller_Tree.tscn")
var blue_environment = null 
var red_environment = null 



var gu = GameUtilities.new()

var demo_mode_player_height = 1.7

var levelselect
var level = null
var cam = null

var beast_mode = false
export var record_tracker_data = false

var arvr_interface = null
var screen_tint_node


var left_controller
var right_controller
var left_collision_root
var right_collision_root

var in_hand_mode = false #auto detect hand_mode, can't revert back automatically


var tracking_data = []


var total_points = 0
var last_points = 0
var total_played = 0
var last_played = 0
var vrw_score = 0


var ovr_init_config = null;
var _vrapi_bone_orientations = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];

var ovr_performance = null;
var ovr_display_refresh_rate = null;
var ovr_guardian_system = null;
var ovr_tracking_transform = null;
var ovr_utilities = null;
var ovr_vr_api_proxy = null;

var ovr_hand_tracking = null;


var arvr_ovr_mobile_interface = null;
var arvr_oculus_interface = null;
var arvr_open_vr_interface = null;
var arvr_webxr_interface = null;

func _initialize_OVR_API():
	# load the .gdns classes.
	ovr_display_refresh_rate = load("res://addons/godot_ovrmobile/OvrDisplayRefreshRate.gdns");
	ovr_guardian_system = load("res://addons/godot_ovrmobile/OvrGuardianSystem.gdns");
	ovr_performance = load("res://addons/godot_ovrmobile/OvrPerformance.gdns");
	ovr_tracking_transform = load("res://addons/godot_ovrmobile/OvrTrackingTransform.gdns");
	ovr_utilities = load("res://addons/godot_ovrmobile/OvrUtilities.gdns");
	ovr_hand_tracking = load("res://addons/godot_ovrmobile/OvrHandTracking.gdns");
	ovr_vr_api_proxy = load("res://addons/godot_ovrmobile/OvrVrApiProxy.gdns");

	# and now instance the .gdns classes for use if load was successfull
	if (ovr_display_refresh_rate): ovr_display_refresh_rate = ovr_display_refresh_rate.new()
	if (ovr_guardian_system): ovr_guardian_system = ovr_guardian_system.new()
	if (ovr_performance): ovr_performance = ovr_performance.new()
	if (ovr_tracking_transform): ovr_tracking_transform = ovr_tracking_transform.new()
	if (ovr_utilities): ovr_utilities = ovr_utilities.new()

func handle_mobile_permissions():
	print ("Checking permissions")
	var perm = OS.get_granted_permissions()
	var read_storage_perm = false
	var write_storage_perm = false
	
	for p in perm:
		print ("Permissions %s already granted"%p)
		if p == "android.permission.READ_EXTERNAL_STORAGE":
			read_storage_perm = true
		elif p == "android.permission.WRITE_EXTERNAL_STORAGE":
			write_storage_perm = true
	
	if not (read_storage_perm and write_storage_perm):
		print ("Requesting permissions")
		OS.request_permissions()


# webxr callback
func _webxr_cb_session_supported(a, b):
	print("WebXR session is supported: " + str(a) + ", " + str(b));
	pass

func _webxr_cb_session_started():
	get_viewport().arvr = true
	print("WebXR Session Started; reference space type: " + arvr_webxr_interface.reference_space_type);

signal signal_webxr_started;

func _webxr_initialize(enable_vr):
	if (!enable_vr):
		GameVariables.vr_mode = false;
		print("  Starting in nonVR mode");
		emit_signal("signal_webxr_started");
		return;
		
	if (arvr_webxr_interface.initialize()):
		get_viewport().arvr = true;
		OS.vsync_enabled = false;
		GameVariables.vr_mode = true;
		print("  Success initializing WebXR Interface.");
		emit_signal("signal_webxr_started")
	else:
		OS.alert("Failed to initialize WebXR Interface")
		GameVariables.vr_mode = false;
		emit_signal("signal_webxr_started");
		
# create two buttons and connect them to _webxr_initialize; this is required
# for WebXR because initializing it on webpage load might fail
func _webxr_create_entervr_buttons():
	var enter_vr_button = Button.new();
	var simulate_vr_button = Button.new();
	
	# the info label here is only for info during dev right now; it will be replaced
	# in the future by something more generic
	var info_label = Label.new();
	info_label.text = "VRWorkout WebXR Demo";
	
	enter_vr_button.text = "Enter VR";
	simulate_vr_button.text = "Simulator Only"

	var vbox = VBoxContainer.new();
	vbox.add_child(info_label);
	vbox.add_child(enter_vr_button);
	#vbox.add_child(simulate_vr_button);
	var centercontainer = CenterContainer.new();
	centercontainer.rect_size = OS.get_real_window_size();
	centercontainer.add_child(vbox);
	get_tree().get_current_scene().add_child(centercontainer);

	enter_vr_button.connect("pressed", self, "_webxr_initialize", [true]);
	#simulate_vr_button.connect("pressed", self, "_webxr_initialize", [false]);



func _on_Controller_Tracking_Lost(controller):
	if level != null:
		level.controller_tracking_lost(controller)
	
func _on_Controller_Tracking_Regained(controller):
	if level != null:
		level.controller_tracking_regained(controller)

func _on_Tracker_removed(tracker_name, type, id):
	print ("Tracker removed: %s / %d / %d"%[tracker_name, type, id])	

	for t in GameVariables.trackers:
		if t.controller_id == id:
			GameVariables.trackers.erase(t)
			t.queue_free()
			break

func is_hand(name):
	return (name.to_lower().find("tracked") >= 0 and name.to_lower().find("hand") >= 0)
			
func _on_Tracker_added(tracker_name, type, id):
	print ("Tracker added: %s / %d / %d"%[tracker_name, type, id])	
	
	if type == ARVRServer.TRACKER_CONTROLLER:
		print ("New controller added %s"%tracker_name.to_lower())
			
		var controller = ARVRController.new()
		controller.controller_id = id
		
		var is_left = false
		if controller.get_hand() == ARVRPositionalTracker.TRACKER_LEFT_HAND:
			is_left = true
		elif controller.get_hand() == ARVRPositionalTracker.TRACKER_HAND_UNKNOWN:	
			#If the tracker can't be identified by the API try to identify it by name
			is_left = (tracker_name.to_lower()).find("left") >= 0
			var is_right = (tracker_name.to_lower()).find("right") >= 0
			
			#If there are trackers that can't be identified make sure that at least
			#one of them is assigned to left
			if not is_left and not is_right:
				for t in GameVariables.trackers:
					if t.get_hand() == ARVRPositionalTracker.TRACKER_HAND_UNKNOWN:
						if t.is_left == false:
							is_left = true
							break
			
		controller.queue_free()
			
		#TODO: Make the controller universal without needing a left and right controller scene	
		var new_controller = null		
		if is_left:
			print ("Left controller")
			new_controller = left_controller_blueprint.instance()
			new_controller.is_left = true
			left_controller = new_controller
		else:			
			print ("Right controller")	
			new_controller = right_controller_blueprint.instance()
			new_controller.is_left = false
			right_controller = new_controller

		new_controller.controller_id = id
		new_controller.set_hand_mode(is_hand(tracker_name))
		get_node("ARVROrigin").add_child(new_controller)
		new_controller.set_detail_select(GameVariables.detail_selection_mode)
		new_controller.get_node("RemoteSpatial").multiplayer_room = get_node("MultiplayerRoom")
		GameVariables.trackers.append(new_controller)

func set_controller_visible(value):
	for t in GameVariables.trackers:
		if t:
			print ("Change controller visibility: %s"%str(value))
			t.set_visible(value)
			
func set_detail_selection_mode(value):
	GameVariables.detail_selection_mode = value
	for t in GameVariables.trackers:
		if t:
			print ("Set tracker detail (%s): %s"%[str(t),str(value)])
			t.set_detail_select(value)

func _enter_tree():		
	check_ar_mode()
	
	if GameVariables.demo_mode:
		ProjectSettings.set("application/config/backend_server", "http://127.0.0.1:5000")


func initialize():
	arvr_ovr_mobile_interface = ARVRServer.find_interface("OVRMobile");
	arvr_oculus_interface = ARVRServer.find_interface("Oculus");
	arvr_open_vr_interface = ARVRServer.find_interface("OpenVR");
	arvr_webxr_interface = ARVRServer.find_interface("WebXR");

	ARVRServer.connect("tracker_added",self,"_on_Tracker_added")
	ARVRServer.connect("tracker_removed",self, "_on_Tracker_removed")

	GameVariables.vr_mode = false
	cam = get_node("ARVROrigin/ARVRCamera")


	ProjectSettings.set("game/external_songs", ProjectSettings.get("application/config/pc_music_directory"))
	print (ProjectSettings.get("game/external_songs"))

	if arvr_ovr_mobile_interface:
		ProjectSettings.set("game/is_oculusquest", true)
		ProjectSettings.set("game/external_songs", ProjectSettings.get("application/config/music_directory"))
		

		handle_mobile_permissions()

		# the init config needs to be done before arvr_interface.initialize()
		ovr_init_config = load("res://addons/godot_ovrmobile/OvrInitConfig.gdns");
		if (ovr_init_config):
			ovr_init_config = ovr_init_config.new()
			ovr_init_config.set_render_target_size_multiplier(1) # setting to 1 here is the default
		
		if arvr_ovr_mobile_interface.initialize():
			arvr_interface = arvr_ovr_mobile_interface
			get_viewport().arvr = true
			get_viewport().hdr = false
			OS.vsync_enabled = false
			#Test: Video recording on the Quest is stuttering, I read somewhere
			#that this is because of th FPS not being a multiple of 30
			# deactivated for now # #Engine.target_fps = 72 
			_initialize_OVR_API()

			if ovr_performance:
				print ("Set foveation performance level")
				ovr_performance.set_foveation_level(4)
				ovr_performance.set_enable_dynamic_foveation(true)
			else:
				print ("Can't set dynamic foveation")

			GameVariables.vr_mode = true
		
	elif arvr_oculus_interface:
		if arvr_oculus_interface.initialize():
			arvr_interface = arvr_oculus_interface
			GameVariables.vr_mode = true
			get_viewport().arvr = true;
			Engine.target_fps = 80 # TODO: this is headset dependent (RiftS == 80)=> figure out how to get this info at runtime
			OS.vsync_enabled = false;
	elif arvr_open_vr_interface:
		if arvr_open_vr_interface.initialize():
			arvr_interface = arvr_open_vr_interface
			get_viewport().arvr = true;
			Engine.target_fps = 90 # TODO: this is headset dependent => figure out how to get this info at runtime
			OS.vsync_enabled = false;
			GameVariables.vr_mode = true;	
			get_viewport().keep_3d_linear = true
	elif arvr_webxr_interface:
			print("  Found WebXR Interface.");
			arvr_webxr_interface.connect("session_supported", self, "_webxr_cb_session_supported")
			arvr_webxr_interface.connect("session_started", self, "_webxr_cb_session_started")
			arvr_webxr_interface.session_mode = 'immersive-vr'
			arvr_webxr_interface.required_features = 'local-floor'
			arvr_webxr_interface.optional_features = 'bounded-floor'
			arvr_webxr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
			arvr_webxr_interface.is_session_supported("immersive-vr")
			_webxr_create_entervr_buttons();
	else:
		#Not running in VR / Demo mode
		cam.translation.y = demo_mode_player_height
		cam.rotation.x = -0.4
	

func check_ar_mode():
	var isar = false
	print ("Checking AR mdoe. System: %s"%OS.get_name())
	if OS.get_name() == "HTML5":
		isar = JavaScript.eval("location.href.indexOf('?ar=1') > 0")
		print ("IS AR?: %s"%str(isar))
	GameVariables.ar_mode = isar
	
# Called when the node enters the scene tree for the first time.
func _ready():
	
	GameVariables.device_id = str(gu.get_device_id())
	GameVariables.vr_camera = get_node("ARVROrigin/ARVRCamera")
	GameVariables.hit_player = get_node("HitPlayer")
	
	print ("Unique device id %s"%GameVariables.device_id)
	GameVariables.setup_globals()
	
	# !! Beware that any functions that rely on config parameters don't
	# !! work properly before those two lines
	var config = gu.load_persistent_config(GameVariables.config_file_location)
	gu.apply_config_parameters(config)
	# -- Now it's safe to access the config parameters
	

	get_node("RemoteInterface").request_profile(GameVariables.device_id)
	get_node("ARVROrigin/ARVRCamera/RemoteSpatial").multiplayer_room = get_node("MultiplayerRoom")
	connect("recenter_scene",self,"on_recenter_scene")

	initialize() #VR specific initialization
	get_node("ARVROrigin/SkyBox/AnimationPlayer").play("starfield_rotation",-1,0.05)

	screen_tint_node = get_node("ARVROrigin/ARVRCamera/ScreenTint")
	splashscreen.head_node = get_node("ARVROrigin/ARVRCamera")
	splashscreen.connect("splash_screen_finished", self,"_on_Splashscreen_finished")
	add_child(splashscreen)
	
	
	if ovr_hand_tracking: 
		ovr_hand_tracking = ovr_hand_tracking.new()
	
	level_blueprint = preload("res://scenes/Level.tscn")
	levelselect_blueprint = preload("res://scenes/Levelselect.tscn")

var xrot = 0.0
var yrot = 0.0
func _input(event):
	var update_controllers = false
	if not GameVariables.vr_mode:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == BUTTON_LEFT:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)				
			elif event.button_index == BUTTON_RIGHT:								
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif event is InputEventMouseMotion:
			xrot -= event.relative[1]/500.0
			yrot -= event.relative[0]/500.0
			cam.rotation = Vector3(xrot,0,0)
			cam.rotate(Vector3(0,1,0), yrot)
			
			update_controllers = true
		elif event is InputEventKey:
			update_controllers = true	
	
		if update_controllers:			
			var arm_length = min(0.6,demo_mode_player_height/2.0)
			var tmp = cam.transform.xform(Vector3(0.15,-0.25,-arm_length))
			if right_controller:
				right_controller.translation = tmp
			if left_controller:
				tmp = cam.transform.xform(Vector3(-0.15,-0.25,-arm_length))	
				left_controller.translation = tmp
	
			
func _on_level_finished	():
	_on_level_finished_actual(true)
	
func _on_level_finished_manually():
	_on_level_finished_actual(false)

func _on_level_finished_actual(valid_end):
	GameVariables.vr_camera.blackout_screen(true)
	GameVariables.vr_camera.show_hud(false)
	#In case the player exited while controller were hidden
	set_controller_visible(true)
	
	if record_tracker_data and ProjectSettings.get("game/is_oculusquest"):
		print ("Storing tracker data")
		var f = File.new()
		f.open("/sdcard/tracker.data", File.WRITE)
		f.store_var(tracking_data)
		f.close()
		tracking_data.clear()	
	
	GameVariables.override_beatmap = false
	
	print ("Level is finished ... remove from scene")
	GameVariables.game_result = level.get_points()
	GameVariables.game_result["level_finished"] = valid_end
	
	last_points = GameVariables.game_result["points"]
	total_points += GameVariables.game_result["points"]
	last_played = GameVariables.game_result["time"]
	total_played += GameVariables.game_result["time"]
	vrw_score = GameVariables.game_result["vrw_score"]
	
	print ("Preparing satistics upload")
	game_statistics["api_version"] = GameVariables.api_version
	game_statistics["score"] = GameVariables.game_result["points"]
	game_statistics["vrw_score"] = GameVariables.game_result["vrw_score"]
	game_statistics["duration"] =  GameVariables.game_result["time"]
	game_statistics["data"] = GameVariables.level_statistics_data
	if GameVariables.current_challenge and valid_end:
		#Do not send as challenge entry if the player exited manually
		game_statistics["challenge"] = GameVariables.current_challenge
	GameVariables.current_challenge = null
	var error = get_node("RemoteInterface").send_data(GameVariables.device_id, "workout", game_statistics)
	if error != OK:
		print ("Statistics not sent to portal. Error code %d"%error)
	else:
		print ("Statistics sent")
	
	#Battle mode does not persist for now
	GameVariables.battle_mode = GameVariables.BattleMode.NO
		
	level.queue_free()
	level = null 
	
	var evaluator = AchievementEvaluator.new(GameVariables.achievement_checks)
	var achievements = evaluator.evaluate_achievements(GameVariables.game_result)
	print ("Player achieved: %s"%str(achievements))
	GameVariables.game_result["achievements"] = achievements
	
	
	levelselect = levelselect_blueprint.instance()
	
	levelselect.translation = Vector3(0,0,0)
	levelselect.connect("level_selected",self,"_on_Area_level_selected")
	get_node("MultiplayerRoom").connect("room_joined",levelselect,"_on_multiplayer_room_joined")
	get_node("MultiplayerRoom").connect("room_left",levelselect,"_on_multiplayer_room_left")

	add_child(levelselect)
	
	
	var last_played_str = gu.seconds_to_timestring(last_played)
	var total_played_str = gu.seconds_to_timestring(total_played)
	
	levelselect.set_stat_text("Results for %s\n\nLast round\nScore: %.2f (%d/%d)\nPoints: %d"%[GameVariables.player_name, vrw_score,GameVariables.game_result["hits"],GameVariables.game_result["max_hits"],last_points]+" Duration: %s"%last_played_str+"\n\nTotal\nPoints: %d"%total_points+" Duration: %s"%total_played_str, vrw_score) 

	yield(get_tree().create_timer(1), "timeout")
	GameVariables.vr_camera.blackout_screen(false)
	if not GameVariables.vr_mode:
		pass
		#get_node("DemoTimer").start()

var prediction_limit_ms = 200
var prediction_history_size = 10
var prediction_max_dist = 0.2

func get_best_element_from_history(history, now, max_delta):
	var selected = 0
	for i in range(len(history)):
		if now - history[i]["ts"] > max_delta:
			break
		selected = i
	return history[selected]
	
func add_element_to_history(history, measurement):
	history.push_front(measurement)
	if len(history) > prediction_history_size:
		history.pop_back()			

var hand_ball_adjusted = false

#If the handtracking has lost the hand update the path for prediction_limt_ms before hiding it
func _update_hand_model(hand: ARVRController, model : Spatial, offset_model: Spatial, history):
	if ovr_hand_tracking: # check if the hand tracking API was loaded
	
		# scale of the hand model as reported by VrApi
		var ls = ovr_hand_tracking.get_hand_scale(hand.controller_id);
		var now = OS.get_ticks_msec()	
		var last = get_best_element_from_history(history, now, 150).duplicate()
				
		var delta_t = now - last["ts"]
		var confidence = ovr_hand_tracking.get_hand_pose(hand.controller_id, _vrapi_bone_orientations);
		if confidence and confidence > 0:
			
			if hand.tracking_lost:
				_on_Controller_Tracking_Regained(hand)
				hand.tracking_lost = false

			hand.update_bone_orientations(_vrapi_bone_orientations, confidence)
			in_hand_mode = true
			if delta_t > prediction_limit_ms:
				#The last valid measurement is too old to get a valid vector
				#start from 0,0,0
				last["vector"] = Vector3(0,0,0)
			else:
				var delta = model.translation - last["pos"]
				last["vector"] = delta/delta_t
			last["ts"] = now
			last["pos"] = model.translation
			add_element_to_history(history, last)
			if not model.visible:
				model.show()
		elif model.visible and in_hand_mode:
			#print ("Prediction for Controller %d delta: %.3f"%[hand.controller_id, delta_t])
			if not hand.tracking_lost:
				_on_Controller_Tracking_Lost(hand)
				hand.tracking_lost = true
			if delta_t < prediction_limit_ms:
				var vec = last["vector"]
				var predict_v = vec * delta_t / prediction_max_dist
				var tmp_v=predict_v-last["pos"]
				var vl = (tmp_v).length()
				if vl > prediction_max_dist:
					predict_v = tmp_v.normalized * prediction_max_dist
				model.translation = history[0]["pos"] + predict_v 
			else:
				model.hide()
		return true;
	else:
		return false;

var recenter_countdown_active = false
func start_countdown(secs, callback_signal):
	if not recenter_countdown_active:
		recenter_countdown_active = true
		var display = get_node("ARVROrigin/ARVRCamera/Countdown")
		display.scale = Vector3(1.0,1.0,1.0)
		display.show()
		for counter in range(secs):
			display.print_info("%d"%int(secs-counter))
			yield(get_tree().create_timer(1),"timeout")
		display.hide()
		emit_signal("recenter_scene")
		recenter_countdown_active = false

func on_recenter_scene():
	var player = get_node("ARVROrigin/ARVRCamera")
	var origin = get_node("ARVROrigin")
	var rot = player.global_transform.basis.get_euler()
	var origin_rot = origin.rotation
	var delta_rot = Vector3(origin_rot[0], origin_rot[1]-rot[1], origin_rot[2])
	print("P: %s   O: %s   D:%s"%[str(rot), str(origin_rot),str(delta_rot)])
	origin.set_rotation(delta_rot)

	var pos = player.global_transform.origin
	var origin_pos = origin.translation
	var delta = Vector3(origin_pos[0]-pos[0], origin_pos[1], origin_pos[2]-pos[2])
	print("P: %s   O: %s   D:%s"%[str(pos), str(origin_pos),str(delta)])
	origin.set_translation(delta)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if not GameVariables.vr_mode:
		if Input.is_key_pressed(KEY_P):
			# start screen capture
			var image = get_viewport().get_texture().get_data()
			image.flip_y()
			image.save_png("/tmp/vrworkout_screenshot_%d.png"%OS.get_ticks_msec())
		elif Input.is_key_pressed(KEY_R):
			start_countdown(5, "recenter_scene")
	if level != null:
		if beast_mode:
			var tmp = level.beast_mode_supported()
			for t in GameVariables.trackers:
				if t:
					t.set_beast_mode(tmp)
	
	for t in GameVariables.trackers:
		if t:	
			_update_hand_model(t, t.collision_root, t.model, t.last_controller);

	if record_tracker_data and left_controller and right_controller:
		tracking_data.append([OS.get_ticks_msec(), cam.translation, cam.rotation,left_controller.translation,left_controller.rotation,right_controller.translation, right_controller.rotation])

#Return the config parameters that should be stored in the config file
func get_persisting_parameters():
	return {"game/portal_connection": ProjectSettings.get("game/portal_connection"),
			"game/hud_enabled":ProjectSettings.get("game/hud_enabled"),
			"game/equalizer": ProjectSettings.get("game/equalizer"),
			"game/exercise/kneesaver": ProjectSettings.get("game/exercise/kneesaver"),
			"game/easy_transition": ProjectSettings.get("game/easy_transition"),
			"game/instructor": ProjectSettings.get("game/instructor"),
			"game/override_beats": ProjectSettings.get("game/override_beats"),
			"game/bpm": ProjectSettings.get("game/bpm"),
			"game/exercise/stand/windmill" : ProjectSettings.get("game/exercise/stand/windmill"),
			"game/default_playlist" : GameVariables.current_song
	}
	
var game_statistics = {}
func _on_Area_level_selected(filename, diff, num):
	if level == null:
		GameVariables.current_song = filename
		#Store the parameters that should survive a restart
		gu.store_persistent_config(GameVariables.config_file_location, get_persisting_parameters())
		
		record_tracker_data = ProjectSettings.get("game/record_tracker")
		
		set_beast_mode(ProjectSettings.get("game/beast_mode"))
		level = level_blueprint.instance()
		
		GameVariables.override_beatmap = ProjectSettings.get("game/override_beats")
		if diff == 3:
			GameVariables.override_beatmap = true
		
		if diff < 0:
			GameVariables.auto_difficulty = true
		else:
			GameVariables.auto_difficulty = false

		var song_names = gu.readable_song_list(filename)
		game_statistics = {"difficulty": diff, "song": song_names}

		GameVariables.difficulty = diff
		
		if num < 0:
			level.audio_filename = [abs(num)*100]
		else:
			level.audio_filename = filename
		level.song_index_parameter = num
		GameVariables.player_height = ProjectSettings.get("game/player_height")
		level.bpm = ProjectSettings.get("game/bpm")
		level.first_beat = levelselect.get_last_beat()
		level.connect("level_finished",self,"_on_level_finished")
		level.connect("level_finished_manually",self,"_on_level_finished_manually")
		levelselect.queue_free()
		add_child(level)	
	
		if not GameVariables.vr_mode:
			demo_mode_player_height = GameVariables.player_height
			level._on_HeartRateData(113)


func _on_DemoTimer_timeout():
	#levelselect.get_node("SettingsCarousel/Connections/VRHealthConnection").connect_vrhealth()
	#get_node("RemoteInterface").send_data(GameVariables.device_id, "exercise", {"test":"12345678"})
	change_environment("angry")
	#levelselect.get_node("SettingsCarousel/Connections/VRWorkoutConnection").connect_vrworkout()
	#GameVariables.exercise_state_list = GameVariables.predefined_exercises["Low pyramid"]
	#_on_Area_level_selected("res://audio/songs/01_VRWorkout.ogg", 0, 1)
	
	#_on_Area_level_selected("res://audio/nonfree_songs/03_Rule_The_World.ogg", -1, 1)
	#levelselect.show_settings("switchboard")	
	_on_Area_level_selected(["res://audio/songs/Z_120BPM_Test.ogg"], -1, 1)
	#_on_Area_level_selected("res://audio/songs/02_VRWorkout_Beater.ogg", 2, 1)


	#get_node("ARVROrigin/ARVRCamera").translation = Vector3(0,2,0.8)
	#get_node("ARVROrigin/ARVRCamera/AreaHead/hit_player").play(0)
	#print(get_node("ARVROrigin/ARVRCamera/AreaHead/hit_player").stream.get_length())

func get_running_speed():
	var s = get_node("ARVROrigin/ARVRCamera").get_running_speed()
	return s

func get_groove_bpm():
	var s = get_node("ARVROrigin/ARVRCamera").get_groove_bpm()
	return s

	
func set_beast_mode(enabled):
	beast_mode = enabled
	ProjectSettings.set("game/beast_mode",enabled)
	for t in GameVariables.trackers:
		if t:
			t.set_beast_mode(enabled)

func _on_Splashscreen_finished():
	GameVariables.vr_camera.blackout_screen(true)
	get_node("SongDatabase").intialize_song_database()
	var default_playlist = ProjectSettings.get("game/default_playlist")
	if default_playlist:
		GameVariables.current_song = default_playlist	
	
	red_environment = load("res://default_env_red.tres")
	blue_environment = load("res://default_env.tres")

	levelselect = levelselect_blueprint.instance()
	levelselect.translation = Vector3(0,0,0)
	levelselect.connect("level_selected",self,"_on_Area_level_selected")
	get_node("MultiplayerRoom").connect("room_joined",levelselect,"_on_multiplayer_room_joined")
	get_node("MultiplayerRoom").connect("room_left",levelselect,"_on_multiplayer_room_left")


	if not GameVariables.vr_mode:
		_on_Tracker_added("right", ARVRServer.TRACKER_CONTROLLER, 1)
		_on_Tracker_added("left", ARVRServer.TRACKER_CONTROLLER, 2)

	splashscreen.queue_free()
	add_child(levelselect)
	if not GameVariables.vr_mode:
		pass
		#get_node("DemoTimer").start()


func change_environment(value):
	if value == "angry":
		get_viewport().get_camera().environment = red_environment
		get_node("ARVROrigin/SkyBox").switch("angry")
	else:
		get_viewport().get_camera().environment = blue_environment
		get_node("ARVROrigin/SkyBox").switch("calm")




