extends StaticBody3D

## Shows a greeting message on the HUD while the player is nearby.

@export var dialogue_text: String = "Welcome, traveler. The wilds are dangerous beyond here."

@onready var detector: Area3D = $Detector


func _ready() -> void:
	detector.body_entered.connect(_on_body_entered)
	detector.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("show_message"):
			hud.show_message(dialogue_text)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		var hud := get_tree().get_first_node_in_group("hud")
		if hud and hud.has_method("hide_message"):
			hud.hide_message()
