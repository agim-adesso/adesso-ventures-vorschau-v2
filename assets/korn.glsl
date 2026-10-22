/** @resolution */
uniform vec2 u_resolution;
/** @time */
uniform float u_time;
/**
 * @label Ground
 * @color
 * @default #07080B
 */
uniform vec3 u_ground;
/**
 * @label Blue (anchor)
 * @color
 * @default #006EC7
 */
uniform vec3 u_blue;
/**
 * @label Second
 * @color
 * @default #28DCAA
 */
uniform vec3 u_second;
/**
 * @label Third
 * @color
 * @default #0B2A5B
 */
uniform vec3 u_third;
/**
 * @label Light Center X
 * @range 0.0, 1.0
 * @default 0.7
 */
uniform float u_cx;
/**
 * @label Light Center Y
 * @range 0.0, 1.0
 * @default 0.35
 */
uniform float u_cy;
/**
 * @label Spread
 * @range 0.2, 2.0
 * @default 0.9
 */
uniform float u_spread;
/**
 * @label Intensity
 * @range 0.0, 1.5
 * @default 1.0
 */
uniform float u_int;
/**
 * @label Grain
 * @range 0.0, 0.25
 * @default 0.09
 */
uniform float u_grain;
/**
 * @label Speed
 * @range 0.0, 1.0
 * @default 0.12
 */
uniform float u_speed;

float hash(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p){
  vec2 i = floor(p); vec2 f = fract(p);
  float a = hash(i), b = hash(i + vec2(1.0, 0.0)), c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p){ float v = 0.0; float a = 0.5; for (int i = 0; i < 4; i++){ v += a * noise(p); p *= 2.02; a *= 0.5; } return v; }

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  uv.y = 1.0 - uv.y;
  float asp = u_resolution.x / u_resolution.y;
  float t = u_time * u_speed;
  vec2 q = vec2(uv.x * asp, uv.y);
  vec2 w = vec2(fbm(q * 1.3 + vec2(t, -t * 0.7)), fbm(q * 1.3 + vec2(-t * 0.6, t) + 3.1));
  vec2 c1 = vec2(u_cx * asp, u_cy) + (w - 0.5) * 0.35;
  vec2 c2 = c1 + vec2(-0.28 * asp * u_spread, 0.32 * u_spread) + vec2(sin(t * 1.3), cos(t)) * 0.08;
  vec2 c3 = c1 + vec2(0.18 * asp * u_spread, 0.42 * u_spread) + vec2(cos(t * 0.9), sin(t * 1.1)) * 0.08;
  float d1 = length(q - c1) / u_spread;
  float d2 = length(q - c2) / u_spread;
  float d3 = length(q - c3) / u_spread;
  vec3 col = u_ground;
  col = mix(col, u_third, smoothstep(1.1, 0.0, d3) * 0.9 * u_int);
  col = mix(col, u_blue, smoothstep(0.85, 0.0, d1) * u_int);
  col = mix(col, u_second, smoothstep(0.55, 0.0, d2) * 0.75 * u_int);
  col += smoothstep(0.35, 0.0, d1) * 0.08 * u_int;
  float g = hash(gl_FragCoord.xy + fract(u_time * 7.0) * 91.7) - 0.5;
  col += g * u_grain;
  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
