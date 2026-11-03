extends CanvasLayer

@export var needs: Node
@export var inventory: Inventory
@export var player: Node

@onready var hotbar: HBoxContainer = $Hotbar
@onready var controls_hint: Label = $ControlsHint
@onready var slots: Array[Node] = $Hotbar.get_children()

@onready var free_stamina_panel: Panel = $Energy/Segments/FreeStamina
@onready var used_stamina_panel: Panel = $Energy/Segments/UsedStamina
@onready var hunger_panel: Panel = $Energy/Segments/HungerPenalty
@onready var fatigue_panel: Panel = $Energy/Segments/FatiguePenalty
@onready var pickup_bar: ProgressBar = $ProgressBar

const COLOR_FREE: Color = Color("aefc96ff")
const COLOR_USED: Color = Color("3d3d42ff")
const COLOR_HUNGER: Color = Color("e3c543ff")
const COLOR_FATIGUE: Color = Color("86604fff")

var corner_radius: int = 4
var last_count: int = 0
var tween: Tween
var reject_tween: Tween
var pop_tween: Tween

func _ready() -> void:
	if inventory:
		if not inventory.changed.is_connected(_on_inventory_changed):
			inventory.changed.connect(_on_inventory_changed)
		if not inventory.rejected.is_connected(_on_inventory_rejected):
			inventory.rejected.connect(_on_inventory_rejected)
		_on_inventory_changed()
		
		inventory.selected_changed.connect(_on_selected_changed)
	
	if not needs and Engine.has_singleton("Needs"):
		needs = get_node("/root/Needs")
		
	if needs:
		if needs.has_signal("hunger_changed"):
			needs.hunger_changed.connect(_on_needs_changed)
		if needs.has_signal("fatigue_changed"):
			needs.fatigue_changed.connect(_on_needs_changed)
		if needs.has_signal("stamina_changed"):
			needs.stamina_changed.connect(_on_needs_changed)
	
	_on_selected_changed()
	update_bar(false)
	
	var hint_tween: Tween = create_tween()
	hint_tween.tween_interval(12.0)
	hint_tween.tween_property(controls_hint, "modulate:a", 0.0, 1.5)
	hint_tween.tween_callback(controls_hint.hide)

func _process(_delta: float) -> void:
	if not player:
		return
		
	pickup_bar.value = maxf(player.pickup_progress / player.PICKUP_TIME, player.eat_progress / player.EAT_TIME) * 100
	pickup_bar.visible = pickup_bar.value != 0

func _on_inventory_changed() -> void:
	if not inventory:
		return
	for x in slots.size():
		var texture_rect: TextureRect = slots[x].get_node_or_null("TextureRect")
		if texture_rect:
			texture_rect.visible = x < inventory.items.size()
	if inventory.items.size() > last_count:
		var slot: Control = slots[inventory.items.size() - 1]
		slot.pivot_offset = slot.size / 2
		if pop_tween and pop_tween.is_valid():
			pop_tween.kill()
		pop_tween = create_tween()
		pop_tween.tween_property(slot, "scale", Vector2(1.25, 1.25), 0.08)
		pop_tween.tween_property(slot, "scale", Vector2.ONE, 0.12)
	last_count = inventory.items.size()

func _setup_panel_style(panel: Panel, color: Color, round_left: bool, round_right: bool) -> void:
	if not panel:
		return
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var style := StyleBoxFlat.new()
	style.bg_color = color
	
	style.anti_aliasing = false
	style.corner_detail = 2
	
	style.corner_radius_top_left = corner_radius if round_left else 0
	style.corner_radius_bottom_left = corner_radius if round_left else 0
	style.corner_radius_top_right = corner_radius if round_right else 0
	style.corner_radius_bottom_right = corner_radius if round_right else 0
		
	panel.add_theme_stylebox_override("panel", style)

func update_bar(animate: bool = true) -> void:
	var hunger: float = needs.hunger if needs else 0.0
	var fatigue: float = needs.fatigue if needs else 0.0
	var current_stamina: float = needs.stamina if needs and "stamina" in needs else 100.0
	
	var max_cap: float = maxf(0.0, 100.0 - fatigue - hunger)
	var safe_stamina: float = clampf(current_stamina, 0.0, max_cap)
	var used_stamina: float = maxf(0.0, max_cap - safe_stamina)
	
	if not free_stamina_panel or not used_stamina_panel or not hunger_panel or not fatigue_panel:
		return
	
	var show_free: bool = safe_stamina > 0.01
	var show_used: bool = used_stamina > 0.01
	var show_hunger: bool = hunger > 0.01
	var show_fatigue: bool = fatigue > 0.01
	
	free_stamina_panel.visible = show_free
	used_stamina_panel.visible = show_used
	hunger_panel.visible = show_hunger
	fatigue_panel.visible = show_fatigue
	
	var visible_panels: Array = []
	if show_free: visible_panels.append(free_stamina_panel)
	if show_used: visible_panels.append(used_stamina_panel)
	if show_hunger: visible_panels.append(hunger_panel)
	if show_fatigue: visible_panels.append(fatigue_panel)
	
	for i in range(visible_panels.size()):
		var panel: Panel = visible_panels[i]
		var is_first: bool = (i == 0)
		var is_last: bool = (i == visible_panels.size() - 1)
		
		var col: Color = COLOR_FREE
		if panel == used_stamina_panel: col = COLOR_USED
		elif panel == hunger_panel: col = COLOR_HUNGER
		elif panel == fatigue_panel: col = COLOR_FATIGUE
		
		_setup_panel_style(panel, col, is_first, is_last)
		
	if animate:
		if tween and tween.is_running():
			tween.kill()
		
		tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(free_stamina_panel, "size_flags_stretch_ratio", maxf(safe_stamina, 0.01), 0.3)
		tween.tween_property(used_stamina_panel, "size_flags_stretch_ratio", maxf(used_stamina, 0.01), 0.3)
		tween.tween_property(hunger_panel, "size_flags_stretch_ratio", maxf(hunger, 0.01), 0.3)
		tween.tween_property(fatigue_panel, "size_flags_stretch_ratio", maxf(fatigue, 0.01), 0.3)
	else:
		free_stamina_panel.size_flags_stretch_ratio = maxf(safe_stamina, 0.01)
		used_stamina_panel.size_flags_stretch_ratio = maxf(used_stamina, 0.01)
		hunger_panel.size_flags_stretch_ratio = maxf(hunger, 0.01)
		fatigue_panel.size_flags_stretch_ratio = maxf(fatigue, 0.01)

func set_hotbar_visible(v: bool) -> void:
	hotbar.visible = v

func _on_needs_changed(_new_val: float) -> void:
	update_bar(true)

func _on_selected_changed() -> void:
	for x in slots.size():
		slots[x].modulate = Color.WHITE if x == inventory.selected else Color(1, 1, 1, 0.5)

func _on_inventory_rejected() -> void:
	if reject_tween and reject_tween.is_valid():
		reject_tween.kill()
	reject_tween = create_tween()
	reject_tween.tween_property(hotbar, "modulate", Color(1.0, 0.4, 0.4), 0.2)
	reject_tween.tween_interval(0.2)
	reject_tween.tween_property(hotbar, "modulate", Color.WHITE, 0.2)
