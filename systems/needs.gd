extends Node

var hunger: float = 0.0
@export var hunger_per_hour: float = 10.0
@export var fatigue_per_hour: float = 5.0
@export var rest_per_hour: float = 10.0
var fatigue: float = 0.0
var in_den: bool = false

var elapsed: float = 0.0

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		eat(10.0)

func _process(delta: float) -> void:
	elapsed += delta
	var hours: float = TimeGlobal.time_scale * delta / TimeGlobal.seconds_per_hour
	hunger = minf(hunger + hours * hunger_per_hour, 100.0)
	if in_den:
		fatigue = maxf(fatigue - hours * rest_per_hour, 0.0)
	else:
		fatigue = minf(fatigue + hours * fatigue_per_hour, 100.0)
	if elapsed >= 1.0:
		print("hunger: ", hunger)
		print("fatigue: ", fatigue, " and in den is ", in_den)
		elapsed -= 1.0
	
func eat(amount: float) -> void:
	hunger = maxf(hunger - amount, 0)
