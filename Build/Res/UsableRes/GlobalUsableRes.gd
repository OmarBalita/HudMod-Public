class_name GlobalUsableRes extends UsableRes

@export var noise_texture: NoiseTexture2D = create_noise_texture(512, 512, create_noise(0))
@export var noise_texture_seamless: NoiseTexture2D = create_noise_texture(512, 512, create_noise(0), true)

static func create_noise_texture(width: int, height: int, noise: FastNoiseLite,
	seamless: bool = false, invert: bool = false, as_normal_map: bool = true, normalize: bool = true) -> NoiseTexture2D:
	
	var noise_texture:= NoiseTexture2D.new()
	noise_texture.width = width
	noise_texture.height = height
	noise_texture.noise = noise
	noise_texture.seamless = seamless
	noise_texture.invert = invert
	noise_texture.as_normal_map = as_normal_map
	noise_texture.normalize = normalize
	
	return noise_texture

static func create_noise(noise_type: FastNoiseLite.NoiseType, seed: int = 0, frequency: float = .2) -> FastNoiseLite:
	var noise:= FastNoiseLite.new()
	noise.noise_type = noise_type
	noise.seed = seed
	noise.frequency = frequency
	return noise
