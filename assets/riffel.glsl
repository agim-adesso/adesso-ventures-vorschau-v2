/** @resolution */
uniform vec2 u_resolution;
/** @backdrop */
uniform sampler2D u_backdrop;
/**
 * @label Rib Width
 * @range 6.0, 80.0
 * @default 26.0
 */
uniform float u_rib;
/**
 * @label Distortion
 * @range 0.0, 0.08
 * @default 0.025
 */
uniform float u_disp;
/**
 * @label Light
 * @range 0.0, 1.0
 * @default 0.35
 */
uniform float u_light;
/**
 * @label Tint
 * @color
 * @default #FFFFFF
 */
uniform vec3 u_tint;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  float p = fract(gl_FragCoord.x / u_rib);
  float lens = (p - 0.5) * 2.0;
  vec2 off = vec2(lens * u_disp * -1.6, 0.0);
  vec3 acc = vec3(0.0);
  for (int i = -3; i <= 3; i++) {
    vec2 o = off + vec2(float(i) * 0.0025, 0.0);
    acc += texture2D(u_backdrop, uv + o).rgb;
  }
  acc /= 7.0;
  float hl = pow(1.0 - abs(lens), 3.0) * u_light * 0.35;
  float sh = pow(abs(lens), 6.0) * u_light * 0.25;
  vec3 col = acc * u_tint + hl - sh;
  gl_FragColor = vec4(col, 1.0);
}
