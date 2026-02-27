shader_type canvas_item;

uniform float time;

uniform bool overlay = false;

uniform float scanlines_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float scanlines_width : hint_range(0.0, 0.5) = 0.25;
uniform float grille_opacity : hint_range(0.0, 1.0) = 0.3;
uniform vec2 resolution = vec2(640.0, 480.0);

uniform bool pixelate = true;

uniform bool roll = true;
uniform float roll_speed = 8.0;
uniform float roll_size : hint_range(0.0, 100.0) = 15.0;
uniform float roll_variation : hint_range(0.1, 5.0) = 1.8;
uniform float distort_intensity : hint_range(0.0, 0.2) = 0.05;

uniform float noise_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float noise_speed = 5.0;

uniform float static_noise_intensity : hint_range(0.0, 1.0) = 0.06;

uniform float aberration : hint_range(-1.0, 1.0) = 0.03;
uniform float brightness = 1.4;
uniform bool discolor = true;

uniform float warp_amount : hint_range(0.0, 5.0) = 1.0;
uniform bool clip_warp = false;

uniform float vignette_intensity = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;



vec2 random(vec2 uv){
    uv = vec2(dot(uv, vec2(127.1,311.7)), dot(uv, vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(uv) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 uv_index = floor(uv);
    vec2 uv_fract = fract(uv);
    vec2 blur = smoothstep(0.0, 1.0, uv_fract);

    return mix(
        mix(dot(random(uv_index + vec2(0.0,0.0)), uv_fract - vec2(0.0,0.0)),
            dot(random(uv_index + vec2(1.0,0.0)), uv_fract - vec2(1.0,0.0)), blur.x),
        mix(dot(random(uv_index + vec2(0.0,1.0)), uv_fract - vec2(0.0,1.0)),
            dot(random(uv_index + vec2(1.0,1.0)), uv_fract - vec2(1.0,1.0)), blur.x), 
        blur.y
    ) * 0.5 + 0.5;
}

vec2 warp(vec2 uv){
    vec2 delta = uv - 0.5;
    float delta2 = dot(delta.xy, delta.xy);
    float delta4 = delta2 * delta2;
    float delta_offset = delta4 * warp_amount;
    return uv + delta * delta_offset;
}

float border (vec2 uv){
    float radius = min(warp_amount, 0.08);
    radius = max(min(min(abs(radius * 2.0), abs(1.0)), abs(1.0)), 1e-5);
    vec2 abs_uv = abs(uv * 2.0 - 1.0) - vec2(1.0, 1.0) + radius;
    float dist = length(max(vec2(0.0), abs_uv)) / radius;
    float square = smoothstep(0.96, 1.0, dist);
    return clamp(1.0 - square, 0.0, 1.0);
}

float vignette(vec2 uv){
    uv *= 1.0 - uv.xy;
    float vignette = uv.x * uv.y * 15.0;
    return pow(vignette, vignette_intensity * vignette_opacity);
}


void fragment()
{
    vec2 uv = overlay ? warp(SCREEN_UV) : warp(UV);
    vec2 text_uv = uv;
    vec2 roll_uv = vec2(0.0);
    float _time = roll ? time : 0.0;

    if (pixelate){
        text_uv = ceil(uv * resolution) / resolution;
    }

    float roll_line = 0.0;
    if (roll || noise_opacity > 0.0){
        roll_line = smoothstep(0.3, 0.9, sin(uv.y * roll_size - (_time * roll_speed)));
        roll_line *= roll_line * smoothstep(0.3, 0.9, sin(uv.y * roll_size * roll_variation - (_time * roll_speed * roll_variation)));
        roll_uv = vec2((roll_line * distort_intensity * (1.-UV.x)), 0.0);
    }

    vec4 text;
    if (roll){
        text.r = texture(TEXTURE, text_uv + roll_uv * 0.8 + vec2(aberration, 0.0) * .1).r;
        text.g = texture(TEXTURE, text_uv + roll_uv * 1.2 - vec2(aberration, 0.0) * .1).g;
        text.b = texture(TEXTURE, text_uv + roll_uv).b;
        text.a = 1.0;
    } else {
        text.r = texture(TEXTURE, text_uv + vec2(aberration, 0.0) * .1).r;
        text.g = texture(TEXTURE, text_uv - vec2(aberration, 0.0) * .1).g;
        text.b = texture(TEXTURE, text_uv).b;
        text.a = 1.0;
    }

    float r = text.r;
    float g = text.g;
    float b = text.b;

    uv = warp(UV);

    if (grille_opacity > 0.0){
        float g_r = smoothstep(0.85, 0.95, abs(sin(uv.x * (resolution.x * 3.14159265))));
        r = mix(r, r * g_r, grille_opacity);

        float g_g = smoothstep(0.85, 0.95, abs(sin(1.05 + uv.x * (resolution.x * 3.14159265))));
        g = mix(g, g * g_g, grille_opacity);

        float b_b = smoothstep(0.85, 0.95, abs(sin(2.1 + uv.x * (resolution.x * 3.14159265))));
        b = mix(b, b * b_b, grille_opacity);
    }

    text.r = clamp(r * brightness, 0.0, 1.0);
    text.g = clamp(g * brightness, 0.0, 1.0);
    text.b = clamp(b * brightness, 0.0, 1.0);

    float scanlines = 0.5;
    if (scanlines_opacity > 0.0){
        scanlines = smoothstep(scanlines_width, scanlines_width + 0.5, abs(sin(uv.y * (resolution.y * 3.14159265))));
        text.rgb = mix(text.rgb, text.rgb * vec3(scanlines), scanlines_opacity);
    }

    if (noise_opacity > 0.0){
        float n = smoothstep(0.4, 0.5, noise(uv * vec2(2.0, 200.0) + vec2(10.0, (time * (noise_speed)))));
        roll_line *= n * scanlines * clamp(random((ceil(uv * resolution) / resolution) + vec2(time * 0.8, 0.0)).x + 0.8, 0.0, 1.0);
        text.rgb = clamp(mix(text.rgb, text.rgb + roll_line, noise_opacity), vec3(0.0), vec3(1.0));
    }

    if (static_noise_intensity > 0.0){
        text.rgb += clamp(random((ceil(uv * resolution) / resolution) + fract(time)).x, 0.0, 1.0) * static_noise_intensity;
    }

    text.rgb *= border(uv);
    text.rgb *= vignette(uv);

    if (clip_warp){
        text.a = border(uv);
    }

    if (discolor){
        float saturation = 0.5;
        float contrast = 1.2;
        vec3 greyscale = vec3(text.r + text.g + text.b) / 3.;
        text.rgb = mix(text.rgb, greyscale, saturation);

        float midpoint = pow(0.5, 2.2);
        text.rgb = (text.rgb - vec3(midpoint)) * contrast + midpoint;
    }

    COLOR = text;
}
