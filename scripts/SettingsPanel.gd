extends PanelContainer

signal close_requested

@onready var sensitivity_slider: HSlider = $MarginContainer/VBoxContainer/SensitivitySlider
@onready var sensitivity_value_label: Label = $MarginContainer/VBoxContainer/SensitivityValueLabel
@onready var brightness_slider: HSlider = $MarginContainer/VBoxContainer/BrightnessSlider
@onready var brightness_value_label: Label = $MarginContainer/VBoxContainer/BrightnessValueLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	sensitivity_slider.value = Settings.mouse_sensitivity
	brightness_slider.value = Settings.brightness
	_update_value_labels()
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)


func _on_sensitivity_changed(value: float) -> void:
	Settings.set_mouse_sensitivity(value)
	_update_value_labels()


func _on_brightness_changed(value: float) -> void:
	Settings.set_brightness(value)
	_update_value_labels()


func _update_value_labels() -> void:
	sensitivity_value_label.text = "%.4f" % sensitivity_slider.value
	brightness_value_label.text = "%d%%" % roundi(brightness_slider.value * 100.0)


func _on_close_pressed() -> void:
	close_requested.emit()
