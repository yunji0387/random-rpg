extends DirectionalLight3D

## Rotates the sun and adjusts sky/ambient light to simulate a day/night cycle.

@export var day_length_seconds: float = 120.0
@export var environment_path: NodePath

var _environment: Environment
var time_of_day := 0.25 # 0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset
var day_count := 1


func _ready() -> void:
	if environment_path != NodePath():
		var world_env: WorldEnvironment = get_node(environment_path)
		_environment = world_env.environment


func _process(delta: float) -> void:
	var previous_time := time_of_day
	time_of_day = fmod(time_of_day + delta / day_length_seconds, 1.0)
	if time_of_day < previous_time:
		day_count += 1
	var sun_angle := time_of_day * TAU - PI / 2.0
	rotation.x = sun_angle
	rotation.y = deg_to_rad(-20.0)

	var elevation := sin(sun_angle)
	var day_factor: float = clamp(elevation, 0.0, 1.0)
	var horizon_factor: float = clamp(1.0 - abs(elevation), 0.0, 1.0)

	light_energy = lerp(0.05, 1.2, day_factor)
	light_color = Color(1.0, 0.95, 0.85).lerp(Color(1.0, 0.55, 0.3), horizon_factor * 0.6)

	if _environment:
		_environment.ambient_light_energy = lerp(0.15, 1.0, day_factor)
		var sky_material: Material = _environment.sky.sky_material
		if sky_material is ProceduralSkyMaterial:
			sky_material.sky_energy_multiplier = lerp(0.05, 1.0, day_factor)
			sky_material.ground_energy_multiplier = lerp(0.05, 1.0, day_factor)


func get_time_string() -> String:
	var total_minutes := int(time_of_day * 24.0 * 60.0)
	var hours := floori(total_minutes / 60.0)
	var minutes := total_minutes % 60
	return "Day %d - %02d:%02d" % [day_count, hours, minutes]
