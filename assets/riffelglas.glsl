/** @resolution */
uniform vec2 u_resolution;
/** @backdrop */
uniform sampler2D u_backdrop;
/**
 * @label Rib Width
 * @range 6.0, 80.0
 * @default 28.0
 */
uniform float u_rib;
/**
 * @label Distortion
 * @range 0.0, 0.08
 * @default 0.03
 */
uniform float u_disp;
/**
 * @label Light
 * @range 0.0, 1.0
 * @default 0.55
 */
uniform float u_light;
/**
 * @label Clear (scroll state, 1 = clear glass)
 * @range 0.0, 1.0
 * @default 0.0
 */
uniform float u_clear;
/**
 * @label Grain
 * @range 0.0, 0.2
 * @default 0.05
 */
uniform float u_grain;
/**
 * @label Tint
 * @color
 * @default #FFFFFF
 */
uniform vec3 u_tint;

float hash(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  float k = 1.0 - u_clear;
  float p = fract(gl_FragCoord.x / u_rib);
  float lens = (p - 0.5) * 2.0;
  vec2 off = vec2(lens * u_disp * -1.6 * k, 0.0);
  vec3 acc = vec3(0.0);
  for (int i = -3; i <= 3; i++) {
    vec2 o = off + vec2(float(i) * 0.0025 * k, 0.0);
    acc += texture2D(u_backdrop, uv + o).rgb;
  }
  acc /= 7.0;
  float hl = pow(1.0 - abs(lens), 3.0) * u_light * 0.35 * k;
  float sh = pow(abs(lens), 6.0) * u_light * 0.25 * k;
  float edge = (1.0 - smoothstep(0.0, 1.5, abs(p * u_rib))) * 0.06 * u_light;
  vec3 col = acc * mix(vec3(1.0), u_tint, k) + hl - sh + edge;
  col += (hash(gl_FragCoord.xy) - 0.5) * u_grain;
  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
