extends OmniLight3D

@export var pulse_speed: float = 1.8
@export var dim_energy: float = 0.06
@export var flash_energy: float = 1.8

var elapsed: float = 0.0


func _process(delta: float) -> void:
	elapsed += delta
	var cycle_position := fposmod(elapsed * pulse_speed, 1.0)
	var flashing := cycle_position < 0.12 or (cycle_position > 0.2 and cycle_position < 0.32)
	light_energy = flash_energy if flashing else dim_energy