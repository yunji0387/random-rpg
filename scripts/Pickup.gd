extends Area3D

## A bobbing world item that applies itself to the player on contact.

@export var item: Item
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.2

var _base_y: float
var _time := 0.0


func _ready() -> void:
	add_to_group("pickup")
	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * bob_speed) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if item and body.has_method("collect_item"):
		body.collect_item(item)
		queue_free()
