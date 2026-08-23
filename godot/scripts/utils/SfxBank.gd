class_name SfxBank
extends RefCounted

## Banco de efeitos sonoros gerado por síntese em tempo de execução.
## O projeto não tem arquivos de SFX — em vez de ficar mudo, sintetizamos
## ondas 8-bit (quadrada, seno, ruído) direto em AudioStreamWAV.
## Cada som é gerado sob demanda e fica em cache.

const RATE := 22050

enum Wave { SINE, SQUARE, SAW, TRIANGLE, NOISE }

static var _cache: Dictionary = {}


static func get_sound(key: String) -> AudioStreamWAV:
	if _cache.has(key):
		return _cache[key]
	var stream: AudioStreamWAV = _build(key)
	_cache[key] = stream
	return stream


static func _build(key: String) -> AudioStreamWAV:
	match key:
		"shoot":
			return _mix([
				_tone(880.0, 520.0, 0.09, Wave.SQUARE, 0.32, 0.004, 0.05),
				_tone(1760.0, 900.0, 0.05, Wave.SINE, 0.16, 0.002, 0.04),
			])
		"shoot_magic":
			return _mix([
				_tone(620.0, 1180.0, 0.13, Wave.SINE, 0.30, 0.006, 0.08),
				_tone(310.0, 590.0, 0.13, Wave.TRIANGLE, 0.18, 0.006, 0.08),
			])
		"shoot_heavy":
			return _mix([
				_tone(240.0, 90.0, 0.20, Wave.SQUARE, 0.34, 0.005, 0.14),
				_noise(0.10, 0.18, 0.002, 0.08),
			])
		"blade":
			return _mix([
				_noise(0.09, 0.22, 0.002, 0.07, 2600.0, 900.0),
				_tone(1400.0, 620.0, 0.07, Wave.SAW, 0.10, 0.002, 0.05),
			])
		"hit":
			return _mix([
				_noise(0.055, 0.26, 0.001, 0.045, 3200.0, 1200.0),
				_tone(420.0, 180.0, 0.05, Wave.SQUARE, 0.16, 0.001, 0.04),
			])
		"crit":
			return _mix([
				_tone(1320.0, 1980.0, 0.12, Wave.SQUARE, 0.26, 0.002, 0.09),
				_tone(660.0, 990.0, 0.12, Wave.SINE, 0.20, 0.002, 0.09),
				_noise(0.05, 0.14, 0.001, 0.04, 4000.0, 2000.0),
			])
		"kill":
			return _mix([
				_tone(520.0, 140.0, 0.16, Wave.SQUARE, 0.24, 0.003, 0.12),
				_noise(0.10, 0.16, 0.002, 0.08, 2200.0, 400.0),
			])
		"explosion":
			return _mix([
				_noise(0.42, 0.42, 0.004, 0.40, 1800.0, 120.0),
				_tone(180.0, 40.0, 0.40, Wave.TRIANGLE, 0.30, 0.004, 0.36),
			])
		"thunder":
			return _mix([
				_noise(0.28, 0.40, 0.001, 0.26, 5200.0, 700.0),
				_tone(900.0, 120.0, 0.20, Wave.SAW, 0.18, 0.001, 0.18),
			])
		"freeze":
			return _mix([
				_tone(1500.0, 2400.0, 0.22, Wave.SINE, 0.22, 0.01, 0.18),
				_tone(2400.0, 1900.0, 0.18, Wave.TRIANGLE, 0.12, 0.01, 0.15),
			])
		"burn":
			return _to_stream(_noise(0.30, 0.14, 0.02, 0.26, 1200.0, 300.0))
		"hurt":
			return _mix([
				_tone(330.0, 110.0, 0.22, Wave.SQUARE, 0.34, 0.002, 0.18),
				_noise(0.12, 0.20, 0.002, 0.10, 1600.0, 300.0),
			])
		"heal":
			return _arpeggio([523.25, 659.25, 783.99], 0.09, Wave.SINE, 0.26)
		"levelup":
			return _arpeggio([523.25, 659.25, 783.99, 1046.5], 0.10, Wave.SQUARE, 0.24)
		"evolve":
			return _arpeggio([392.0, 523.25, 659.25, 783.99, 1046.5, 1318.5], 0.09, Wave.SQUARE, 0.26)
		"gem":
			return _to_stream(_tone(1046.5, 1568.0, 0.07, Wave.SINE, 0.20, 0.002, 0.05))
		"coin":
			return _arpeggio([987.77, 1318.51], 0.055, Wave.SQUARE, 0.20)
		"chest":
			return _arpeggio([659.25, 830.61, 987.77, 1318.51], 0.085, Wave.TRIANGLE, 0.24)
		"boss":
			return _mix([
				_tone(110.0, 82.41, 0.75, Wave.SAW, 0.30, 0.04, 0.5),
				_tone(220.0, 164.81, 0.75, Wave.SQUARE, 0.14, 0.04, 0.5),
			])
		"dash":
			return _to_stream(_noise(0.16, 0.20, 0.004, 0.13, 900.0, 2800.0))
		"click":
			return _to_stream(_tone(880.0, 1320.0, 0.045, Wave.SQUARE, 0.18, 0.001, 0.035))
		"select":
			return _arpeggio([659.25, 987.77], 0.05, Wave.SQUARE, 0.18)
		"deny":
			return _to_stream(_tone(220.0, 165.0, 0.16, Wave.SQUARE, 0.22, 0.002, 0.13))
		"altar":
			return _arpeggio([392.0, 587.33, 784.0], 0.13, Wave.SINE, 0.24)
		"death":
			return _mix([
				_tone(392.0, 65.0, 0.9, Wave.SAW, 0.30, 0.01, 0.8),
				_noise(0.5, 0.14, 0.05, 0.45, 900.0, 100.0),
			])
		"victory":
			return _arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.51, 1567.98], 0.12, Wave.SQUARE, 0.26)
		_:
			return _to_stream(_tone(660.0, 660.0, 0.06, Wave.SQUARE, 0.15, 0.002, 0.05))


# --- Síntese -----------------------------------------------------------------

static func _samples(seconds: float) -> int:
	return maxi(1, int(RATE * seconds))


static func _wave_value(kind: Wave, phase: float, rng: RandomNumberGenerator) -> float:
	match kind:
		Wave.SINE:
			return sin(phase * TAU)
		Wave.SQUARE:
			return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		Wave.SAW:
			return fmod(phase, 1.0) * 2.0 - 1.0
		Wave.TRIANGLE:
			var t := fmod(phase, 1.0)
			return (t * 4.0 - 1.0) if t < 0.5 else (3.0 - t * 4.0)
		Wave.NOISE:
			return rng.randf_range(-1.0, 1.0)
	return 0.0


static func _envelope(i: int, total: int, attack: float, release: float) -> float:
	var t: float = float(i) / float(RATE)
	var dur: float = float(total) / float(RATE)
	var a: float = 1.0
	if attack > 0.0 and t < attack:
		a = t / attack
	var remaining: float = dur - t
	if release > 0.0 and remaining < release:
		a = min(a, max(0.0, remaining / release))
	return a


## Tom com varredura de frequência (freq_start → freq_end)
static func _tone(
	freq_start: float,
	freq_end: float,
	seconds: float,
	kind: Wave,
	volume: float,
	attack: float = 0.005,
	release: float = 0.05
) -> PackedFloat32Array:
	var total := _samples(seconds)
	var out := PackedFloat32Array()
	out.resize(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var phase: float = 0.0
	for i in range(total):
		var t: float = float(i) / float(total)
		var freq: float = lerpf(freq_start, freq_end, t)
		phase += freq / float(RATE)
		out[i] = _wave_value(kind, phase, rng) * volume * _envelope(i, total, attack, release)
	return out


## Ruído filtrado (passa-baixa simples com corte variável) — usado em impactos
static func _noise(
	seconds: float,
	volume: float,
	attack: float = 0.002,
	release: float = 0.05,
	cutoff_start: float = 2000.0,
	cutoff_end: float = 400.0
) -> PackedFloat32Array:
	var total := _samples(seconds)
	var out := PackedFloat32Array()
	out.resize(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = 987
	var prev: float = 0.0
	for i in range(total):
		var t: float = float(i) / float(total)
		var cutoff: float = lerpf(cutoff_start, cutoff_end, t)
		var alpha: float = clampf(cutoff / float(RATE), 0.02, 1.0)
		var raw: float = rng.randf_range(-1.0, 1.0)
		prev = prev + alpha * (raw - prev)
		out[i] = prev * volume * _envelope(i, total, attack, release)
	return out


## Sequência de notas (usada em level-up, baú, vitória)
static func _arpeggio(freqs: Array, note_seconds: float, kind: Wave, volume: float) -> AudioStreamWAV:
	var chunks: Array = []
	for f in freqs:
		chunks.append(_tone(float(f), float(f) * 1.01, note_seconds, kind, volume, 0.004, note_seconds * 0.55))
	return _to_stream(_concat(chunks))


static func _concat(chunks: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for c in chunks:
		out.append_array(c)
	return out


static func _mix(chunks: Array) -> AudioStreamWAV:
	var longest: int = 0
	for c in chunks:
		longest = maxi(longest, (c as PackedFloat32Array).size())
	var out := PackedFloat32Array()
	out.resize(longest)
	for c in chunks:
		var arr: PackedFloat32Array = c
		for i in range(arr.size()):
			out[i] = out[i] + arr[i]
	return _to_stream(out)


static func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v: float = clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream
