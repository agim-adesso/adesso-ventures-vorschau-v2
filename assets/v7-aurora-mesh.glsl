precision mediump float;

/** @resolution */
uniform vec2 u_resolution;

/** @time */
uniform float u_time;

/**
 * @label Base (light)
 * @color
 * @default #F2F6FB
 */
uniform vec3 u_base;

/**
 * @label adesso Blue
 * @color
 * @default #006EC7
 */
uniform vec3 u_blue;

/**
 * @label Sky
 * @color
 * @default #12A4E3
 */
uniform vec3 u_sky;

/**
 * @label Turquoise
 * @color
 * @default #27D3B0
 */
uniform vec3 u_turq;

/**
 * @label Violet
 * @color
 * @default #9C8BE3
 */
uniform vec3 u_violet;

/**
 * @label Speed
 * @range 0.0, 1.0
 * @default 0.18
 */
uniform float u_speed;

/**
 * @label Softness
 * @range 0.2, 1.2
 * @default 0.62
 */
uniform float u_soft;

float blob(vec2 uv, vec2 c, float r) {
  float d = length(uv - c);
  return exp(-(d * d) / (r * r));
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  float aspect = u_resolution.x / u_resolution.y;
  vec2 p = vec2(uv.x * aspect, uv.y);
  float t = u_time * u_speed;

  vec2 w = vec2(sin(p.y * 2.3 + t * 1.3), cos(p.x * 1.7 - t * 1.1)) * 0.08;
  p += w;

  vec2 cBlue   = vec2(aspect * (0.78 + 0.10 * sin(t * 0.9)), 0.30 + 0.12 * cos(t * 0.7));
  vec2 cSky    = vec2(aspect * (0.62 + 0.10 * cos(t * 0.6)), 0.78 + 0.08 * sin(t * 0.8));
  vec2 cTurq   = vec2(aspect * (0.12 + 0.08 * sin(t * 0.7 + 1.3)), -0.05 + 0.06 * sin(t * 1.1));
  vec2 cViolet = vec2(aspect * (0.95 + 0.06 * cos(t * 0.5 + 2.0)), 0.85 + 0.08 * sin(t * 0.9));

  float r = u_soft * 0.9;
  float bB = blob(p, cBlue, r * 1.05);
  float bS = blob(p, cSky, r * 0.95);
  float bT = blob(p, cTurq, r * 0.70);
  float bV = blob(p, cViolet, r * 0.75);

  vec3 col = u_base;
  col = mix(col, u_sky, clamp(bS, 0.0, 1.0) * 0.85);
  col = mix(col, u_turq, clamp(bT, 0.0, 1.0) * 0.75);
  col = mix(col, u_violet, clamp(bV, 0.0, 1.0) * 0.70);
  col = mix(col, u_blue, clamp(bB, 0.0, 1.0) * 0.90);

  float sheen = 0.5 + 0.5 * sin((p.x + p.y) * 3.0 + t * 1.6);
  col += vec3(0.04) * sheen;

  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
