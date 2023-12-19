
class_name SignalWaiter

signal finished

func wait() -> Array:
	return []

func cancel():
	pass


static func wait_all(signals : Array[Signal]) -> Array:
	var all := All.new(signals)
	return await all.wait()

static func wait_any(signals : Array[Signal]) -> Array:
	var any := Any.new(signals)
	return await any.wait()

static func wait_one(one_signal : Signal) -> Array:
	var one := One.new(one_signal)
	return await one.wait()


class All extends SignalWaiter:
	var _signaled_count : int
	var _params : Array
	var _signals : Array[Signal]
	
	func _init(signals : Array[Signal]):
		_signaled_count = 0
		_signals = signals.duplicate()
		_params.resize(_signals.size())

	func wait() -> Array:
		for i in _signals.size():
			_wait_signal(i)
		await finished
		if _signaled_count < 0:
			return []
		return _params

	func _wait_signal(index : int):
		_params[index] = await _signals[index]
		_signaled_count += 1
		if _signaled_count == _signals.size():
			finished.emit()

	func cancel():
		_signaled_count = -1
		finished.emit()


class Any extends SignalWaiter:
	var _index : int
	var _param
	var _signals : Array[Signal]
	
	func _init(signals : Array[Signal]):
		_index = -1
		_signals = signals.duplicate()

	func wait() -> Array:
		for i in _signals.size():
			_wait_signal(i)
		await finished
		if _index < 0:
			return []
		return [_index,_param]

	func _wait_signal(index : int):
		_param = await _signals[index]
		_index = index
		finished.emit()

	func cancel():
		_index = -1
		finished.emit()


class One extends SignalWaiter:
	var _signal : Signal
	var _param
	var _canceled : bool = false
	
	func _init(one_signal : Signal):
		_signal = one_signal

	func wait() -> Array:
		_wait_signal()
		await finished
		if _canceled:
			return []
		if _param is Array:
			return _param
		else:
			return [_param]

	func _wait_signal():
		_param = await _signal
		finished.emit()

	func cancel():
		_canceled = true
		finished.emit()


