/** @resolution */
uniform vec2 u_resolution;

/** @time */
uniform float u_time;

/**
 * @label Blue
 * @color
 * @default #006EC7
 */
uniform vec3 u_blue;

/**
 * @label Cream
 * @color
 * @default #FFFDF1
 */
uniform vec3 u_cream;

/**
 * @label Lavender
 * @color
 * @default #BDB1E0
 */
uniform vec3 u_lavender;

/**
 * @label Background
 * @color
 * @default #FFFDF1
 */
uniform vec3 u_bg;

/**
 * @label Ribbon Width
 * @range 0.06, 0.5
 * @default 0.22
 */
uniform float u_bandwidth;

/**
 * @label Speed
 * @range 0.0, 1.5
 * @default 0.35
 */
uniform float u_speed;

float ribbon(vec2 uv, float phase, float freq, float amp, float yoff, float t) {
  float wave = sin(uv.x * freq + phase + t) * amp
             + sin(uv.x * freq * 1.9 + phase * 1.7 - t * 0.8) * amp * 0.45;
  float center = yoff + wave;
  float d = abs(uv.y - center);
  return d;
}

vec3 shadeBand(vec2 uv, float phase, float freq, float amp, float yoff, float t, vec3 lo, vec3 hi, out float mask) {
  float d = ribbon(uv, phase, freq, amp, yoff, t);
  float hw = u_bandwidth * 0.5;
  mask = smoothstep(hw, hw * 0.55, d);
  // silk shading across the band width
  float across = clamp((uv.y - (yoff)) / hw, -1.0, 1.0);
  float sheen = 0.5 + 0.5 * sin(across * 3.14159 + uv.x * 6.0 + t * 1.4);
  float lightBand = smoothstep(0.0, 1.0, sheen);
  vec3 col = mix(lo, hi, lightBand);
  // bright specular highlight streak
  float spec = smoothstep(0.82, 1.0, sheen);
  col = mix(col, u_cream, spec * 0.7);
  return col;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  float t = u_time * u_speed;
  vec3 color = u_bg;

  float m1;
  vec3 c1 = shadeBand(uv, 0.0, 5.0, 0.10, 0.52, t, u_blue * 0.55, u_blue, m1);
  color = mix(color, c1, m1);

  float m2;
  vec3 c2 = shadeBand(uv, 2.1, 4.2, 0.13, 0.46, t * 0.9, u_lavender * 0.7, u_lavender, m2);
  color = mix(color, c2, m2 * 0.85);

  float m3;
  vec3 c3 = shadeBand(uv, 4.3, 6.0, 0.08, 0.58, t * 1.15, u_blue * 0.7, mix(u_blue, u_cream, 0.35), m3);
  color = mix(color, c3, m3 * 0.75);

  gl_FragColor = vec4(color, 1.0);
}
