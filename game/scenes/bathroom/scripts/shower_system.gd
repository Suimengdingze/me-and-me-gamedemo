extends Node
class_name ShowerSystem

@export var cold_supply_temp: float = 20.0
@export var base_hot_temp: float = 52.0
@export var base_hot_pressure: float = 0.75
@export var base_cold_pressure: float = 0.85

@export var comfort_temp_min: float = 38.0
@export var comfort_temp_max: float = 41.0
@export var comfort_flow_min: float = 0.65
@export var comfort_flow_max: float = 0.95
@export var success_required_time: float = 3.0

var hot_valve_open: float = 0.0
var cold_valve_open: float = 0.0

var hot_supply_temp: float = 52.0
var hot_supply_pressure: float = 0.75
var cold_supply_pressure: float = 0.85

var output_temp: float = 20.0
var output_flow: float = 0.0

var comfort_hold_time: float = 0.0
var drift_time: float = 0.0
var next_event_cd: float = 5.0
var event_temp_offset: float = 0.0
var event_pressure_offset: float = 0.0

signal output_changed(temp: float, flow: float, progress: float)
signal shower_ready

func _process(delta: float) -> void:
	drift_time += delta
	next_event_cd -= delta

	_update_disturbance(delta)
	_update_supply_state(delta)
	_update_output()
	_check_comfort(delta)

	var progress: float = clampf(comfort_hold_time / success_required_time, 0.0, 1.0)
	output_changed.emit(output_temp, output_flow, progress)

func _update_disturbance(delta: float) -> void:
	event_temp_offset = lerpf(event_temp_offset, 0.0, delta * 1.5)
	event_pressure_offset = lerpf(event_pressure_offset, 0.0, delta * 1.5)

	if next_event_cd <= 0.0:
		_trigger_random_event()
		next_event_cd = randf_range(4.0, 8.0)

func _trigger_random_event() -> void:
	var event_type: int = randi() % 3

	match event_type:
		0:
			event_temp_offset = randf_range(-4.5, -2.0)
			event_pressure_offset = randf_range(-0.20, -0.10)
		1:
			event_temp_offset = randf_range(1.0, 3.0)
			event_pressure_offset = randf_range(0.05, 0.12)
		2:
			event_temp_offset = randf_range(-1.0, 1.0)
			event_pressure_offset = randf_range(-0.15, 0.15)

func _update_supply_state(delta: float) -> void:
	var temp_drift: float = sin(drift_time * 0.55) * 1.8 + sin(drift_time * 0.17) * 1.2
	var pressure_drift: float = sin(drift_time * 0.42) * 0.06 + sin(drift_time * 0.11) * 0.04

	var target_hot_temp: float = base_hot_temp + temp_drift + event_temp_offset
	var target_hot_pressure: float = base_hot_pressure + pressure_drift + event_pressure_offset

	hot_supply_temp = lerpf(hot_supply_temp, target_hot_temp, delta * 2.0)
	hot_supply_pressure = lerpf(hot_supply_pressure, target_hot_pressure, delta * 2.5)
	cold_supply_pressure = base_cold_pressure

	hot_supply_temp = clampf(hot_supply_temp, 44.0, 58.0)
	hot_supply_pressure = clampf(hot_supply_pressure, 0.35, 1.0)
	cold_supply_pressure = clampf(cold_supply_pressure, 0.6, 1.0)

func _update_output() -> void:
	var hot_flow: float = hot_valve_open * hot_supply_pressure
	var cold_flow: float = cold_valve_open * cold_supply_pressure

	output_flow = clampf(hot_flow + cold_flow, 0.0, 1.2)

	if hot_flow + cold_flow <= 0.001:
		output_temp = cold_supply_temp
	else:
		output_temp = (
			hot_flow * hot_supply_temp +
			cold_flow * cold_supply_temp
		) / (hot_flow + cold_flow)

func _check_comfort(delta: float) -> void:
	var temp_ok: bool = output_temp >= comfort_temp_min and output_temp <= comfort_temp_max
	var flow_ok: bool = output_flow >= comfort_flow_min and output_flow <= comfort_flow_max

	if temp_ok and flow_ok:
		comfort_hold_time += delta
	else:
		comfort_hold_time = maxf(comfort_hold_time - delta * 1.5, 0.0)

	if comfort_hold_time >= success_required_time:
		shower_ready.emit()
