extends Node

signal hunger_changed(new_hunger: float)
signal fatigue_changed(new_fatigue: float)
signal stamina_changed(new_value: float)

var hunger: float = 0.0
@export var hunger_per_hour: float = 10.0
@export var hunger_growth_per_day: float = 0.0

var fatigue: float = 0.0
@export var has_fatigue: bool = true
@export var fatigue_per_hour: float = 5.0
@export var rest_per_hour: float = 10.0
var in_den: bool = false

var stamina: float = 100.0

var elapsed: float = 0.0

func _process(delta: float) -> void:
	elapsed += delta
	var hours: float = TimeGlobal.time_scale * delta / TimeGlobal.seconds_per_hour
	
	var old_hunger: float = hunger
	var effective_hunger_per_hour: float = hunger_per_hour * (0.10 if in_den else 1.0)
	hunger = minf(hunger + hours * effective_hunger_per_hour * (1 + hunger_growth_per_day * (TimeGlobal.day - 1)), 100.0)
	if old_hunger != hunger:
		hunger_changed.emit(hunger)
	
	if has_fatigue:
		var old_fatigue: float = fatigue
		if in_den:
			fatigue = maxf(fatigue - hours * rest_per_hour, 0.0)
		else:
			fatigue = minf(fatigue + hours * fatigue_per_hour, 100.0)
			
		if old_fatigue != fatigue:
			fatigue_changed.emit(fatigue)
	
	var max_cap: float = maxf(0.0, 100.0 - fatigue - hunger)
	if in_den:
		stamina = minf(stamina + hours * rest_per_hour * 8.0, max_cap)
		stamina_changed.emit(stamina)
	elif stamina < max_cap:
		stamina = minf(stamina + hours * 80.0, max_cap)
		stamina_changed.emit(stamina)
			
	if elapsed >= 1.0:
		elapsed = fmod(elapsed, 1.0)
	
func eat(amount: float) -> void:
	hunger = maxf(hunger - amount, 0.0)
	hunger_changed.emit(hunger)
