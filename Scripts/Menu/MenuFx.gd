class_name MenuFx
extends RefCounted
## Small UI animation helpers shared by the menus.

const HOVER_SCALE: float = 1.07


## Keeps a control's pivot at its center so scale/rotation tweens grow from the middle.
static func keep_pivot_centered(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	control.resized.connect(func(): control.pivot_offset = control.size / 2.0)


## Makes a button grow slightly on hover/focus. Disabled buttons stay still.
static func setup_hover(button: BaseButton, hover_scale: float = HOVER_SCALE) -> void:
	keep_pivot_centered(button)
	var grow := func():
		if not button.disabled:
			tween_scale(button, hover_scale)
	var shrink := func(): tween_scale(button, 1.0)
	button.mouse_entered.connect(grow)
	button.focus_entered.connect(grow)
	button.mouse_exited.connect(shrink)
	button.focus_exited.connect(shrink)


static func tween_scale(control: Control, target: float, duration: float = 0.12) -> void:
	control.create_tween().tween_property(control, "scale", Vector2(target, target), duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
