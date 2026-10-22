precision mediump float;

/** @resolution */
uniform vec2 u_resolution;
/** @time */
uniform float u_time;
/** @mouse */
uniform vec2 u_mouse;

/**
 * @label Edge (deep)
 * @color
 * @default #0A3FA8
 */
uniform vec3 u_edge;
/**
 * @label Field (main)
 * @color
 * @default #1C7FE0
 */
uniform vec3 u_field;
/**
 * @label Wash (large area)
 * @color
 * @default #08C6EA
 */
uniform vec3 u_wash;
/**
 * @label Glow (light core)
 * @color
 * @default #A8F2DA
 */
uniform vec3 u_glow;
/**
 * @label Accent (top corner)
 * @color
 * @default #C98CE8
 */
uniform vec3 u_accent;
/**
 * @label Depth (counter blob)
 * @color
 * @default #3B4FD6
 */
uniform vec3 u_depth;

/** @label Wash position (0-1, y down) */
uniform vec2 u_pWash;
/** @label Glow position (0-1, y down) */
uniform vec2 u_pGlow;
/** @label Accent position (0-1, y down) */
uniform vec2 u_pAccent;
/** @label Depth position (0-1, y down) */
uniform vec2 u_pDepth;

/**
 * @label Glow size
 * @range 0.05, 0.8
 * @default 0.26
 */
uniform float u_glowSize;
/**
 * @label Wash size
 * @range 0.2, 1.4
 * @default 0.8
 */
uniform float u_washSize;
/**
 * @label Haze (top light)
 * @color
 * @default #9FC6F0
 */
uniform vec3 u_haze;
/**
 * @label Haze strength
 * @range 0.0, 1.0
 * @default 0.5
 */
uniform float u_hazeAmt;
/**
 * @label Accent strength
 * @range 0.0, 1.0
 * @default 0.85
 */
uniform float u_accentAmt;
/**
 * @label Vignette
 * @range 0.0, 1.0
 * @default 0.55
 */
uniform float u_vignette;
/**
 * @label Light streak
 * @range 0.0, 1.0
 * @default 0.35
 */
uniform float u_streak;
/**
 * @label Flow (warp)
 * @range 0.0, 0.4
 * @default 0.16
 */
uniform float u_warp;
/**
 * @label Speed
 * @range 0.0, 1.0
 * @default 0.12
 */
uniform float u_speed;
/**
 * @label Mouse follow
 * @range 0.0, 1.0
 * @default 0.25
 */
uniform float u_follow;
/**
 * @label Grain
 * @range 0.0, 0.12
 * @default 0.035
 */
uniform float u_grain;

float hash(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p) {
  vec2 i = floor(p); vec2 f = fract(p);
  float a = hash(i), b = hash(i + vec2(1.0, 0.0)), c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; } return v; }

float blob(vec2 q, vec2 c, float r) { vec2 d = q - c; return exp(-dot(d, d) / (r * r)); }

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  uv.y = 1.0 - uv.y;
  float asp = u_resolution.x / u_resolution.y;
  float t = u_time * u_speed;

  vec2 m = u_mouse / u_resolution;
  m.y = 1.0 - m.y;
  float hasMouse = step(0.001, u_mouse.x + u_mouse.y);

  vec2 q = vec2(uv.x * asp, uv.y);
  vec2 w = vec2(fbm(q * 1.4 + vec2(t, -t * 0.6)), fbm(q * 1.4 + vec2(-t * 0.7, t) + 5.2)) - 0.5;
  q += w * u_warp * 2.0;

  vec2 gp = mix(u_pGlow, m, u_follow * hasMouse);
  vec2 cWash = vec2(u_pWash.x * asp, u_pWash.y) + vec2(sin(t * 0.8), cos(t * 0.6)) * 0.05;
  vec2 cGlow = vec2(gp.x * asp, gp.y) + vec2(cos(t * 0.9), sin(t * 1.1)) * 0.04;
  vec2 cAcc = vec2(u_pAccent.x * asp, u_pAccent.y) + vec2(sin(t * 0.5 + 2.0), cos(t * 0.7)) * 0.04;
  vec2 cDep = vec2(u_pDepth.x * asp, u_pDepth.y) + vec2(cos(t * 0.6 + 1.0), sin(t * 0.8)) * 0.05;

  vec3 col = u_field;
  col = mix(col, u_wash, clamp(blob(q, cWash, u_washSize), 0.0, 1.0) * 0.95);
  vec2 cHaze = vec2((0.48 + 0.04 * sin(t * 0.7)) * asp, -0.08);
  col = mix(col, u_haze, clamp(blob(q, cHaze, 0.42), 0.0, 1.0) * u_hazeAmt);
  col = mix(col, u_depth, clamp(blob(q, cDep, 0.30), 0.0, 1.0) * 0.75);
  col = mix(col, u_accent, clamp(blob(q, cAcc, 0.32), 0.0, 1.0) * u_accentAmt);
  float g = blob(q, cGlow, u_glowSize);
  float gTail = blob(q, cGlow + vec2(0.2, -0.18), u_glowSize * 0.75) + blob(q, cGlow + vec2(-0.12, 0.12), u_glowSize * 0.8) * 0.6;
  col = mix(col, u_glow, clamp(g * 0.95 + gTail * 0.45, 0.0, 1.0));

  vec2 sd = normalize(vec2(1.0, -0.55));
  float sDist = dot(vec2(uv.x * asp, uv.y) - vec2(0.62 * asp, 0.92), vec2(-sd.y, sd.x));
  float along = dot(vec2(uv.x * asp, uv.y) - vec2(0.62 * asp, 0.92), sd);
  float streak = exp(-sDist * sDist / 0.006) * smoothstep(-0.2, 0.15, along) * smoothstep(0.9, 0.3, along);
  col = mix(col, mix(col, u_wash, 0.6) + 0.06, streak * u_streak);

  vec2 vc = uv - 0.5;
  float vig = smoothstep(0.3, 0.9, length(vc * vec2(1.0, 1.25)));
  col = mix(col, u_edge, vig * u_vignette);

  col += (hash(gl_FragCoord.xy + fract(u_time) * 37.0) - 0.5) * u_grain;
  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
