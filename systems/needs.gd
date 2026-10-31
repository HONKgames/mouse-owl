extends Node

var hunger: float = 0.0
@export var hunger_per_hour: float = 10.0
@export var hunger_growth_per_day: float = 0.0

var fatigue: float = 0.0
@export var has_fatigue: bool = true
@export var fatigue_per_hour: float = 5.0
@export var rest_per_hour: float = 10.0
var in_den: bool = false

var elapsed: float = 0.0

func _process(delta: float) -> void:
	elapsed += delta
	var hours: float = TimeGlobal.time_scale * delta / TimeGlobal.seconds_per_hour
	hunger = minf(hunger + hours * hunger_per_hour * (1 + hunger_growth_per_day * (TimeGlobal.day - 1)), 100.0)
	if has_fatigue:
		if in_den:
			fatigue = maxf(fatigue - hours * rest_per_hour, 0.0)
		else:
			fatigue = minf(fatigue + hours * fatigue_per_hour, 100.0)
	if elapsed >= 1.0:
		print(get_parent().name, "\n Hunger: ", hunger, "\n Fatigue: ", fatigue)
		print("______________________________________________________________\n")
		elapsed -= 1.0
	
func eat(amount: float) -> void:
	hunger = maxf(hunger - amount, 0)
