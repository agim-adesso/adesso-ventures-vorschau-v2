/** @resolution */
uniform vec2 u_resolution;

/** @backdrop */
uniform sampler2D u_backdrop;

/**
 * @label Dot Size
 * @range 4.0, 20.0
 * @default 8.0
 */
uniform float u_dot;

/**
 * @label Ink
 * @color
 * @default #006EC7
 */
uniform vec3 u_ink;

/**
 * @label Strength
 * @range 0.0, 1.0
 * @default 0.85
 */
uniform float u_strength;

float luma(vec3 c){ return dot(c, vec3(0.299, 0.587, 0.114)); }

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  vec3 src = texture2D(u_backdrop, uv).rgb;
  float l = luma(src);

  vec2 grid = gl_FragCoord.xy / u_dot;
  vec2 cell = fract(grid) - 0.5;
  float d = length(cell);

  // darker areas -> bigger dots
  float radius = (1.0 - l) * 0.72;
  float dot = smoothstep(radius, radius - 0.18, d);

  // white where no dot (multiply identity), ink where dot
  vec3 col = mix(vec3(1.0), u_ink, dot * u_strength);
  gl_FragColor = vec4(col, 1.0);
}
