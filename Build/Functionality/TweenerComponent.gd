## MADE BY AHMED GD
@tool class_name TweenerComponent extends Node

signal finished()

@export var processMode: Tween.TweenProcessMode = Tween.TWEEN_PROCESS_IDLE ## ProcessType

@export_group("Minually")
@export var curves: Array[Curve] ## Used to make custom transitions

@export_group("Automatically")
@export var transType: Tween.TransitionType = Tween.TRANS_LINEAR ## Transition Type
@export var easeType: Tween.EaseType = Tween.EASE_IN ## Ease Type

var start: Variant # the value will the obj start with
var end: Variant = 1.0 # the value will the obj end with

var tween: Tween

## Automatically Transition Function
func play(obj: Variant, method: String, values: Array[Variant], duration: Array[float], loop: bool = false, trans: Tween.TransitionType = transType, _ease: Tween.EaseType = easeType, delay: float = 0) -> void:
	tween = create_tween().set_trans(trans).set_ease(_ease)
	tween.set_process_mode(processMode)
	
	# for every value in values -> the tween will play each value in values until the end
	var curr_dur: float
	for i in range(values.size()):
		if i <= duration.size() - 1: curr_dur = duration[i]
		tween.tween_property(obj, method, values[i], curr_dur).set_delay(delay)
	
	await tween.finished
	finished.emit() # A signal to check if the tween Ended!
	
	if (loop):
		play(obj, method, values, duration, loop, trans, _ease)

## Minually Transition Function
func play_curve(object: Variant, method: String, startIn: Variant = 0.0, endIn: Variant = 1.0, duration: float = 1.0, curveIndex: int = 0, loop: bool = false, delay: float = 0) -> void:
	tween = create_tween()
	tween.set_process_mode(processMode)
	
	tween.tween_method(interpolate.bind(object, method, curveIndex, startIn, endIn), 0.0, 1.0, duration).set_delay(delay)
	tween.play() # start the tween
	
	await tween.finished
	finished.emit() # A signal to check if the tween Ended!
	
	if (loop):
		play_curve(object, method, startIn, endIn, duration, curveIndex, loop, delay)

## Used to set up the values;
func interpolate(newValue: Variant, object: Variant, property: String, index: int, a: Variant, b: Variant) -> void:
	object.set(property, a + ((b - a) * curves[index].sample(newValue)))


func kill_tween() -> void:
	if tween: tween.kill()
