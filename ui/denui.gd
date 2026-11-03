extends Control

const FOOD_VALUE: float = 25.0

@export var children_scene: PackedScene

@onready var mouse_manager: MouseBabyManager = $Children
@onready var time_indicator: AnimatedSprite2D = $AnimatedSprite2D
@onready var sleep_button: Button = $Button
@onready var vignette: TextureRect = $Vignette

@onready var hunger_bar: ProgressBar = $VBoxContainer/HungerBar
@onready var food_needed_label: Label = $VBoxContainer/FoodNeededLabel
@onready var food_label: Label = $Buttons/FoodLabel # FIXED PATH TO MATCH HIERARCHY
@onready var feed_button: Button = $Buttons/FeedButton
@onready var eat_button: Button = $Buttons/EatButton

var was_sleeping: bool = false
var current_den: Area3D = null
var player_needs: Node = null
var label_tween: Tween

func _ready() -> void:
	if sleep_button:
		sleep_button.button_down.connect(_on_sleep_button_down)
		sleep_button.button_up.connect(_on_sleep_button_up)
	
	if vignette:
		vignette.modulate.a = 0.0
		vignette.visible = true
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if feed_button:
		feed_button.pressed.connect(_on_feed_pressed)
	if eat_button:
		eat_button.pressed.connect(_on_eat_pressed)

func _process(_delta: float) -> void:
	update_time_indicator()
	
	if mouse_manager:
		if hunger_bar:
			hunger_bar.value = mouse_manager.collective_hunger
		update_labels()

	var is_sleeping: bool = TimeGlobal.time_scale > 10.0
	if is_sleeping != was_sleeping:
		was_sleeping = is_sleeping
		fade_sleep_effects(is_sleeping)

func update_time_indicator() -> void:
	if not time_indicator or not time_indicator.sprite_frames:
		return
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

func open(den_node: Area3D, needs_node: Node) -> void:
	current_den = den_node
	player_needs = needs_node
	update_labels()

func update_labels() -> void:
	if food_label and current_den:
		food_label.text = "Food: " + str(current_den.stored_food)
	
	if food_needed_label and mouse_manager:
		var hunger_per_food: float = 10.0
		var food_needed: int = ceili(mouse_manager.collective_hunger / hunger_per_food)
		food_needed_label.text = "Food Needed: " + str(food_needed)

func _on_eat_pressed() -> void:
	if not current_den or current_den.stored_food <= 0 or not player_needs:
		return
	
	current_den.stored_food -= 1
	player_needs.eat(1)
	update_labels()

func _on_feed_pressed() -> void:
	if not current_den or current_den.stored_food <= 0 or not mouse_manager:
		return
	
	var food_to_feed: int = current_den.stored_food
	mouse_manager.feed_mice(food_to_feed)
	current_den.stored_food = 0
	
	update_labels()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("jump"):
		TimeGlobal.start_sleeping()
	elif event.is_action_released("jump"):
		TimeGlobal.stop_sleeping()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_den and current_den.stored_food > 0 and mouse_manager:
			mouse_manager.feed_mice(1)
			current_den.stored_food -= 1
			update_labels()
			get_viewport().set_input_as_handled()
