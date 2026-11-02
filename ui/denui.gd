extends Control

const FOOD_VALUE: float = 25.0

@export var children_scene: PackedScene

@onready var children: Node2D = $Children

@onready var time_indicator: AnimatedSprite2D = $AnimatedSprite2D
@onready var sleep_button: TextureButton = $TextureButton
@onready var vignette: TextureRect = $Vignette

@onready var food_label: Label = $VBoxContainer/FoodLabel
@onready var eat_button: Button = $VBoxContainer/EatButton
@onready var feed_button: Button = $VBoxContainer/FeedButton

var was_sleeping: bool = false
var den: Area3D = null
var player_needs: Node = null

func _ready() -> void:
	if sleep_button:
		sleep_button.button_down.connect(_on_sleep_button_down)
		sleep_button.button_up.connect(_on_sleep_button_up)
	
	if vignette:
		vignette.modulate.a = 0.0
		vignette.visible = true
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	eat_button.pressed.connect(_on_eat_pressed)
	feed_button.pressed.connect(_on_feed_pressed)

func _process(_delta: float) -> void:
	update_time_indicator()
	
	var is_sleeping: bool = TimeGlobal.time_scale > 10.0
	if is_sleeping != was_sleeping:
		was_sleeping = is_sleeping
		fade_sleep_effects(is_sleeping)

func update_time_indicator() -> void:
	var max_frames: int = time_indicator.sprite_frames.get_frame_count(time_indicator.animation)
	var total_minutes: int = (TimeGlobal.hour * 60) + TimeGlobal.minute
	var target_frame: int = floori((float(total_minutes) / 1440.0) * max_frames) % max_frames
	
	time_indicator.stop()
	time_indicator.frame = target_frame
	
func _on_sleep_button_down() -> void:
	TimeGlobal.start_sleeping()

func _on_sleep_button_up() -> void:
	TimeGlobal.stop_sleeping()
	
func fade_sleep_effects(active: bool) -> void:
	var tween: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if active:
		if vignette:
			tween.tween_property(vignette, "modulate:a", 0.75, 0.3)
		if sleep_button:
			tween.tween_property(sleep_button, "modulate", Color(1.3, 1.3, 1.0, 1.0), 0.3)
			tween.tween_property(sleep_button, "scale", Vector2(1.05, 1.05), 0.3)
	else:
		if vignette:
			tween.tween_property(vignette, "modulate:a", 0.0, 0.3)
		if sleep_button:
			tween.tween_property(sleep_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
			tween.tween_property(sleep_button, "scale", Vector2(1.0, 1.0), 0.3)

func open(d: Area3D, n: Node) -> void:
	den = d
	player_needs = n
	update_label()
	for child in children.get_children():
		child.queue_free()
	for child in den.get_children():
		if not child.has_node("Needs"):
			continue
		var c: MouseBaby = children_scene.instantiate()
		c.position = Vector2(randf_range(300, 700), randf_range(300, 500))
		c.needs = child.get_node("Needs")
		children.add_child(c)

func update_label() -> void:
	food_label.text = "food: " + str(den.stored_food)

func _on_eat_pressed() -> void:
	feed(player_needs)

func _on_feed_pressed() -> void:
	if den.stored_food <= 0:
		return
	var hungriest: Node = null
	for child in den.get_children():
		if not child.has_node("Needs"):
			continue
		var child_needs: Node = child.get_node("Needs")
		if hungriest == null or hungriest.hunger < child_needs.hunger:
			hungriest = child_needs
	if hungriest != null:
		feed(hungriest)

func feed(target_needs: Node) -> void:
	if den.stored_food <= 0 or target_needs.hunger <= 0:
		return
	den.stored_food -= 1
	target_needs.eat(FOOD_VALUE)
	update_label()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("jump"):
		TimeGlobal.start_sleeping()
	elif event.is_action_released("jump"):
		TimeGlobal.stop_sleeping()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var reverse_children: Array = children.get_children()
		reverse_children.reverse()
		for child: MouseBaby in reverse_children:
			if child.is_hit(event.position):
				feed(child.needs)
				get_viewport().set_input_as_handled()
				return
