extends Spatial

signal level_selected(filename, difficulty, level_number)

var gu = GameUtilities.new()

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
	
func update_widget():
	get_node("SettingsCarousel/Switchboard/BeastModeSelector").beast_mode = ProjectSettings.get("game/beast_mode")
	get_node("SettingsCarousel/Switchboard/BeastModeSelector").update_switch()
	
	get_node("SettingsCarousel/Switchboard/JumpSwitch").value = ProjectSettings.get("game/exercise/jump")
	get_node("SettingsCarousel/Switchboard/JumpSwitch").update_switch()
	
	get_node("SettingsCarousel/Switchboard/StandSwitch").value = ProjectSettings.get("game/exercise/stand")
	get_node("SettingsCarousel/Switchboard/StandSwitch").update_switch()

	get_node("SettingsCarousel/Switchboard/WindmillSwitch").value = ProjectSettings.get("game/exercise/stand/windmill")
	get_node("SettingsCarousel/Switchboard/WindmillSwitch").update_switch()
	
	get_node("SettingsCarousel/Switchboard/SquatSwitch").value = ProjectSettings.get("game/exercise/squat")
	get_node("SettingsCarousel/Switchboard/SquatSwitch").update_switch()
	
	get_node("SettingsCarousel/Switchboard/PushupSwitch").value = ProjectSettings.get("game/exercise/pushup")
	get_node("SettingsCarousel/Switchboard/PushupSwitch").update_switch()
	
	get_node("SettingsCarousel/Switchboard/SafePushupSwitch").value = ProjectSettings.get("game/hud_enabled")
	get_node("SettingsCarousel/Switchboard/SafePushupSwitch").update_switch()

	get_node("SettingsCarousel/Switchboard/CrunchSwitch").value = ProjectSettings.get("game/exercise/crunch")
	get_node("SettingsCarousel/Switchboard/CrunchSwitch").update_switch()

	get_node("SettingsCarousel/Switchboard/BurpeeSwitch").value = ProjectSettings.get("game/exercise/burpees")
	get_node("SettingsCarousel/Switchboard/BurpeeSwitch").update_switch()

	get_node("SettingsCarousel/Switchboard/DuckSwitch").value = ProjectSettings.get("game/exercise/duck")
	get_node("SettingsCarousel/Switchboard/DuckSwitch").update_switch()

	get_node("SettingsCarousel/Switchboard/YogaSwitch").value = ProjectSettings.get("game/exercise/yoga")
	get_node("SettingsCarousel/Switchboard/YogaSwitch").update_switch()

	get_node("SettingsCarousel/Switchboard/SprintSwitch").value = ProjectSettings.get("game/exercise/sprint")
	get_node("SettingsCarousel/Switchboard/SprintSwitch").update_switch()

	get_node("SettingsCarousel/Switchboard/EqualizerSwitch").value = ProjectSettings.get("game/equalizer")
	get_node("SettingsCarousel/Switchboard/EqualizerSwitch").update_switch()


	get_node("SettingsCarousel/Switchboard/KneesaverSwitch").value = ProjectSettings.get("game/exercise/kneesaver")
	get_node("SettingsCarousel/Switchboard/KneesaverSwitch").update_switch()

	get_node("SettingsCarousel/Switchboard/StrengthCardioSwitch").value = ProjectSettings.get("game/exercise/strength_focus")
	get_node("SettingsCarousel/Switchboard/StrengthCardioSwitch").update_switch()

	get_node("SettingsCarousel/Connections/VRWorkoutConnection/PortalInfo").set_state(ProjectSettings.get("game/portal_connection"))

	get_node("SettingsCarousel/Switchboard/InstructorSwitch").value = ProjectSettings.get("game/instructor")
	get_node("SettingsCarousel/Switchboard/InstructorSwitch").update_switch()

	get_node("SettingsCarousel/Switchboard/ExtendedSwitch").value = ProjectSettings.get("game/easy_transition")
	get_node("SettingsCarousel/Switchboard/ExtendedSwitch").update_switch()

	get_node("BPM/OverrideBeats").value = ProjectSettings.get("game/override_beats")
	get_node("BPM/OverrideBeats").update_switch()


	GameVariables.exercise_state_list = []
	
	get_node("SettingsCarousel/Exercises/StandardWorkout").mark_active()
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	show_settings("empty")
	update_online_features()
	
	get_node("SongSelector").set_songs(get_tree().current_scene.get_node("SongDatabase").song_list())
	if GameVariables.current_song:
		get_node("SongSelector").playlist_from_song_files(GameVariables.current_song)
	
	get_node("MainText").print_info("VRWorkout\nSelect song by touching a block\nBest played hands only - no controllers\nPosition yourself between the green poles\nRun in place to get multipliers\n")
	
	get_node("Tutorial").print_info("How to play\n- Hit the hand cues to the beat of the music\n- Head cues should only be touched no headbutts\n- Run in place to receive point multipliers!\nThe optimal time to hit the cues is when the\nrotating marker meets the static one")	
	
	update_widget()
	get_node("SongSelector").select_difficulty(GameVariables.difficulty)
	GameVariables.vr_camera.blackout_screen(false)
	#show_settings("battle")
	#show_settings("switchboard")
	yield(get_tree().create_timer(1.0),"timeout")
	show_settings("exercises")
	


func set_main_text(text):
	get_node("MainText").print_info(text)

func set_stat_text(text, score):
	get_node("Stats").print_info(text)
	get_node("Stats/gauge").set_value(score)
	get_node("Stats/gauge").show()

func get_last_beat():
	return get_node("BPM").last_beat

func _on_multiplayer_room_joined(as_host):
	if not as_host:
		gu.deactivate_node(get_node("SongSelector"))
		
func _on_multiplayer_room_left():
		gu.activate_node(get_node("SongSelector"))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
var controller_detail_set = false
func _process(delta):
	if not controller_detail_set:
		print ("Set small controller")
		get_tree().current_scene.set_detail_selection_mode(true)
		controller_detail_set = true
	


func _on_JumpSwitch_toggled(value):
	ProjectSettings.set("game/exercise/jump", value)
	
func _on_StandSwitch_toggled(value):
	ProjectSettings.set("game/exercise/stand", value)

func _on_WindmillSwitch_toggled(value):
	ProjectSettings.set("game/exercise/stand/windmill", value)

func _on_CrunchSwitch_toggled(value):
	ProjectSettings.set("game/exercise/crunch", value)


func _on_SquatSwitch_toggled(value):
	ProjectSettings.set("game/exercise/squat", value)


func _on_PushupSwitch_toggled(value):
	ProjectSettings.set("game/exercise/pushup", value)


func _on_BurpeeSwitch_toggled(value):
	ProjectSettings.set("game/exercise/burpees", value)


func _on_DuckSwitch_toggled(value):
	ProjectSettings.set("game/exercise/duck", value)


func _on_SprintSwitch_toggled(value):
	ProjectSettings.set("game/exercise/sprint", value)

func _on_KneesaverSwitch_toggled(value):
	ProjectSettings.set("game/exercise/kneesaver", value)

func _on_SafePushupSwitch_toggled(value):
	ProjectSettings.set("game/hud_enabled", value)

func _on_StrengthCardioSwitch_toggled(value):
	ProjectSettings.set("game/exercise/strength_focus", value)

func _on_EqualizerSwitch_toggled(value):
	ProjectSettings.set("game/equalizer", value)
	
func _on_OverrideBeats_toggled(value):
	ProjectSettings.set("game/override_beats", value)



func _on_SongSelector_level_selected(filename, difficulty, level_number):
	emit_signal("level_selected", filename, difficulty, level_number)

func _on_YogaSwitch_toggled(value):
	ProjectSettings.set("game/exercise/yoga", value)


func _on_ExerciseCollection_selected(collection):
	GameVariables.game_mode = GameVariables.GameMode.EXERCISE_SET
	GameVariables.achievement_checks = Array()
	gu.set_exercise_collection(collection)
	update_widget()

func show_settings(panel):
	var switchboard_node = get_node("SettingsCarousel/Switchboard")
	var connections_node = get_node("SettingsCarousel/Connections")
	var exercises_node = get_node("SettingsCarousel/Exercises")
	var battle_node = get_node("SettingsCarousel/Battle")
	var carousel = get_node("SettingsCarousel")
	var t = get_node("SettingsCarousel/Tween")

	var angle = 0

	carousel.translation.y = -3

	if panel == "switchboard":
		gu.activate_node(switchboard_node)
		gu.deactivate_node(connections_node)
		gu.deactivate_node(exercises_node)
		gu.deactivate_node(battle_node)
		angle = 0
	elif panel == "connections":
		gu.deactivate_node(switchboard_node)
		gu.activate_node(connections_node)
		gu.deactivate_node(exercises_node)
		gu.deactivate_node(battle_node)
		angle = 3*PI/2.0
	elif panel == "exercises":
		gu.deactivate_node(switchboard_node)
		gu.deactivate_node(connections_node)
		gu.activate_node(exercises_node)
		gu.deactivate_node(battle_node)
		angle = PI
	elif panel == "battle":
		gu.deactivate_node(switchboard_node)
		gu.deactivate_node(connections_node)
		gu.deactivate_node(exercises_node)
		gu.activate_node(battle_node)
		update_online_features()
		angle = PI/2.0
	elif panel == "empty":
		gu.deactivate_node(switchboard_node)
		gu.deactivate_node(connections_node)
		gu.deactivate_node(exercises_node)
		gu.deactivate_node(battle_node)
		angle = PI/2.0
		return

	t.interpolate_property(carousel, "rotation:y", carousel.rotation.y, angle, 0.5, Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0)
	t.interpolate_property(carousel, "translation:y", -3, 0, 0.5, Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0)
	t.interpolate_property(carousel, "scale", Vector3(0,0,0), Vector3(1,1,1) , 0.5, Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0)

	t.start()

		
func _on_SettingsButton_selected():
	show_settings("switchboard")	
	
func _on_ExerciseButton_selected():
	show_settings("exercises")	

func _on_ConnectionsButton_selected():
	show_settings("connections")	

func _on_BattleButton_selected():
	show_settings("battle")	


func _on_PresetCollector_selected(collection, achievements):
	GameVariables.game_mode = GameVariables.GameMode.STANDARD
	GameVariables.exercise_state_list = collection
	GameVariables.achievement_checks = achievements
	
func update_online_features():
	var enabled = ProjectSettings.get("game/portal_connection")
	if enabled:
		if has_node("SettingsCarousel/Connections/ConnectPad"):
			gu.activate_node(get_node("SettingsCarousel/Connections/ConnectPad"))
		gu.activate_node(get_node("SettingsCarousel/Battle/ChallengeSlot1"))
		gu.activate_node(get_node("SettingsCarousel/Battle/ChallengeSlot2"))
		gu.activate_node(get_node("SettingsCarousel/Battle/ChallengeSlot3"))
		gu.activate_node(get_node("SettingsCarousel/Battle/ChallengeSlot4"))
		gu.activate_node(get_node("SettingsCarousel/Battle/CreateChallengeButton"))		
	else:
		if has_node("SettingsCarousel/Connections/ConnectPad"):
			gu.deactivate_node(get_node("SettingsCarousel/Connections/ConnectPad"))
		gu.deactivate_node(get_node("SettingsCarousel/Battle/ChallengeSlot1"))
		gu.deactivate_node(get_node("SettingsCarousel/Battle/ChallengeSlot2"))
		gu.deactivate_node(get_node("SettingsCarousel/Battle/ChallengeSlot3"))
		gu.deactivate_node(get_node("SettingsCarousel/Battle/ChallengeSlot4"))
		gu.deactivate_node(get_node("SettingsCarousel/Battle/CreateChallengeButton"))		


	#Connect Pad Deactivated for now
	if not GameVariables.FEATURE_MULTIPLAYER and has_node("SettingsCarousel/Connections/ConnectPad"):
		get_node("SettingsCarousel/Connections/ConnectPad").queue_free()

func _on_PortalSwitch_toggled(value):
	ProjectSettings.set("game/portal_connection", value)
	update_online_features()

func _on_InstructorSwitch_toggled(value):
	ProjectSettings.set("game/instructor", value)


func _on_Recenter_selected():
	get_tree().current_scene.start_countdown(5,"recenter_screen")


func _on_ExtendedSwitch_toggled(value):
	ProjectSettings.set("game/easy_transition", value)


func _on_StoredSlot_selected(exercise_list, slot_number):
	if len(exercise_list) > 0:
		GameVariables.game_mode = GameVariables.GameMode.STORED
		GameVariables.selected_game_slot = slot_number
		GameVariables.cue_list = exercise_list.duplicate()
	else:
		GameVariables.game_mode = GameVariables.GameMode.STANDARD
	GameVariables.achievement_checks = Array()

var challenge_upload_possible = true
func _on_CreateChallengeButton_selected():
	if challenge_upload_possible:
		challenge_upload_possible = false
		gu.upload_challenge(get_tree().current_scene.get_node("RemoteInterface"))
		#Prevent double uploads from spurious button events
		yield(get_tree().create_timer(2.0),"timeout")
	challenge_upload_possible = true

func update_battle_mode():
	if GameVariables.battle_mode == GameVariables.BattleMode.NO:
		get_node("SettingsCarousel/Battle/Opponents/NoEnemy").mark_active()
	else:
		if GameVariables.battle_enemy == "easy":
			get_node("SettingsCarousel/Battle/Opponents/EasyEnemy").mark_active()
		elif GameVariables.battle_enemy == "medium":
			get_node("SettingsCarousel/Battle/Opponents/MediumEnemy").mark_active()
		elif GameVariables.battle_enemy == "hard":
			get_node("SettingsCarousel/Battle/Opponents/HardEnemy").mark_active()


func _on_BattleMode_selected(team, enemy):
	if team == "red":
		GameVariables.battle_team = GameVariables.BattleTeam.RED
	else:	
		GameVariables.battle_team = GameVariables.BattleTeam.BLUE
	
	if enemy == "none":
		GameVariables.battle_enemy = enemy	
		GameVariables.battle_mode = GameVariables.BattleMode.NO
	else:
		GameVariables.battle_enemy = enemy	
		GameVariables.battle_mode = GameVariables.BattleMode.CPU
	update_battle_mode()




func _on_TrackerRecorderButton_selected():
	ProjectSettings.set("game/record_tracker",true)


func _on_AudioStreamPlayer_finished():
	get_node("AudioStreamPlayer").play(0)
