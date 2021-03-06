extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var current_playback_time = 0
var points = 0
var hits = 0
var max_hits = 0
var point_indicator

var hud_enabled = false

signal show_hud()
signal hide_hud()
signal streak_changed(count)
signal hit_scored(hit_score, base_score, points, obj)


# Called when the node enters the scene tree for the first time.
func _ready():
	point_indicator = get_node("PointIndicatorOrigin")
	hud_enabled = ProjectSettings.get("game/hud_enabled")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func get_cue_by_id(ingame_id):
	var retVal = null
	for c in self.get_children():
		if "ingame_id" in c and c.ingame_id == ingame_id:
			retVal = c
			break
	return retVal

var current_points = 0
var current_hits = 0
var current_max_hits = 0
var streak_length = 0

func reset_current_points():
	current_points = 0
	current_hits = 0
	current_max_hits = 0
	streak_length = 0

func get_current_streak():
	return streak_length

func get_hit_score():
	return current_points
	
func get_success_rate():
	var retVal = 100.0
	if current_max_hits > 0:
		retVal = 100.0 * float(current_hits)/float(current_max_hits)

func update_statistics_element(obj, hit, points):
	current_points += points
	var hit_score = 1
	var actual_hit_score = 0
	if obj:
		hit_score = obj.hit_score
	if hit:
		actual_hit_score = hit_score
		streak_length += 1
	else:
		streak_length = 0
		
	current_hits +=  actual_hit_score
	current_max_hits += hit_score

	emit_signal("streak_changed", get_current_streak())
	emit_signal("hit_scored", actual_hit_score, hit_score, points, obj)
	if obj:
		if GameVariables.level_statistics_data.has(obj.ingame_id):
			GameVariables.level_statistics_data[obj.ingame_id]["h"] = hit
			GameVariables.level_statistics_data[obj.ingame_id]["p"] = points

func update_hits(hit_score, is_hit):
	self.max_hits += max(0,hit_score)
	if is_hit:
		self.hits += hit_score
		self.hits = max(self.hits, 0)

func score_negative_hits(hits):
	GameVariables.vr_camera.tint_screen(0.2)
	update_hits(-hits, true)
	point_indicator.emit_text("-%d hits"%hits, "red")

func score_positive_hits(hits):
	update_hits(hits, true)

	point_indicator.emit_text("+%d hits"%hits, "green")

func score_miss(obj):
	point_indicator.emit_text("miss", "red")
	update_hits(obj.hit_score, false)
	update_statistics_element(obj, false, 0)

#If a cue that should not have been hit has been avoided
func score_avoided(obj):
	update_statistics_element(obj, false, 0)

func score_points(hit_points):
	update_statistics_element(null, hit_points > 0, hit_points)

	if hit_points > 0:
		points += hit_points
		update_hits(1,true)
		point_indicator.emit_text("+%d"%hit_points,"green")
		get_parent().update_info(hits,max_hits,points) 
	return hit_points

func score_hit(delta, obj = null):
	var multiplier = get_parent().run_point_multiplier
	if obj and "point_multiplier" in obj:
		multiplier = multiplier * obj.point_multiplier
	var p = int(200 - min(delta*1000, 200))
	
	var hit_points = p * multiplier
	points += hit_points
	update_hits(obj.hit_score, true)
	var pts_color = "green"
	if multiplier > 1.0:
		pts_color = "white"
	point_indicator.emit_text("+%d"%hit_points,pts_color)

	update_statistics_element(obj, true, hit_points)

	get_parent().update_info(hits,max_hits,points) 
	return p


func get_closest_cue(pos, type, left = true):
	var nodes = self.get_children()
	var mindist = 1000
	var selected_node = null
	
	for n in nodes:
		var cue_type = n.get("cue_type")
		var is_left = n.get("cue_left")
		if cue_type == "hand" and not n.hit:
			if left == is_left:
				var d = pos.distance_to(n.global_transform.origin)
				if d < mindist:
					selected_node = n
					mindist = d
	return selected_node
		
func _on_VisibilityNotifier_camera_entered(camera):
	if hud_enabled:
		emit_signal("hide_hud")

func _on_VisibilityNotifier_camera_exited(camera):
	if hud_enabled:
		emit_signal("show_hud")
