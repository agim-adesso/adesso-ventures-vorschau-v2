precision mediump float;

/** @resolution */
uniform vec2 u_resolution;

/** @time */
uniform float u_time;

/**
 * @label Deep Blue (Grund)
 * @color
 * @default #0A48BC
 */
uniform vec3 u_deep;

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
 * @label Cyan Glow
 * @color
 * @default #6CD3DF
 */
uniform vec3 u_glow;

/**
 * @label Violet
 * @color
 * @default #9E8BE6
 */
uniform vec3 u_violet;

/**
 * @label Mouse X (0 = links, 1 = rechts)
 * @range 0.0, 1.0
 * @default 0.5
 */
uniform float u_mx;

/**
 * @label Mouse Y (0 = unten, 1 = oben)
 * @range 0.0, 1.0
 * @default 0.5
 */
uniform float u_my;

/**
 * @label Mouse Influence
 * @range 0.0, 1.0
 * @default 0.35
 */
uniform float u_follow;

/**
 * @label Speed
 * @range 0.0, 1.0
 * @default 0.12
 */
uniform float u_speed;

/**
 * @label Grain
 * @range 0.0, 0.1
 * @default 0.025
 */
uniform float u_grain;

float hash(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }

float glow(vec2 p, vec2 c, vec2 r) {
  vec2 d = (p - c) / r;
  return exp(-dot(d, d));
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  float aspect = u_resolution.x / u_resolution.y;
  vec2 p = vec2(uv.x * aspect, uv.y);
  float t = u_time * u_speed;

  // weiche Strömung, damit nichts statisch wirkt
  p += vec2(sin(p.y * 2.1 + t * 1.2), cos(p.x * 1.6 - t)) * 0.035;

  // Maus zieht die Lichtzentren leicht mit
  vec2 m = vec2((u_mx - 0.5) * aspect, u_my - 0.5) * u_follow;

  vec2 cGlow   = vec2(aspect * 0.42, 0.50) + m + vec2(0.06 * sin(t * 0.8), 0.05 * cos(t * 0.6));
  vec2 cCore   = cGlow + vec2(aspect * 0.04, -0.03);
  vec2 cViolet = vec2(aspect * 0.80, 0.86) + m * 0.6 + vec2(0.05 * cos(t * 0.5), 0.04 * sin(t * 0.7));
  vec2 cSky    = vec2(aspect * 0.10, 0.18) - m * 0.4 + vec2(0.05 * sin(t * 0.6 + 1.0), 0.0);
  vec2 cBlue   = vec2(aspect * 0.92, 0.20) - m * 0.3;

  vec3 col = u_deep;
  col = mix(col, u_blue,   clamp(glow(p, cBlue,   vec2(aspect * 0.45, 0.55)), 0.0, 1.0) * 0.85);
  col = mix(col, u_sky,    clamp(glow(p, cSky,    vec2(aspect * 0.30, 0.38)), 0.0, 1.0) * 0.80);
  col = mix(col, u_violet, clamp(glow(p, cViolet, vec2(aspect * 0.22, 0.30)), 0.0, 1.0) * 0.80);
  col = mix(col, u_glow,   clamp(glow(p, cGlow,   vec2(aspect * 0.28, 0.32)), 0.0, 1.0) * 0.85);
  col = mix(col, mix(u_glow, vec3(1.0), 0.35), clamp(glow(p, cCore, vec2(aspect * 0.10, 0.12)), 0.0, 1.0) * 0.45);

  // dunklere Ränder wie im Deck
  float vig = smoothstep(1.15, 0.35, length((uv - 0.5) * vec2(1.0, 1.25)));
  col *= mix(0.86, 1.0, vig);

  col += (hash(gl_FragCoord.xy + floor(t * 10.0)) - 0.5) * u_grain;
  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
