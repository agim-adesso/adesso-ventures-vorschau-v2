precision mediump float;

/** @resolution */
uniform vec2 u_resolution;
/** @time */
uniform float u_time;
/** @mouse */
uniform vec2 u_mouse;

/**
 * @label Base Blue
 * @color
 * @default #1A6ED8
 */
uniform vec3 u_base;
/**
 * @label Royal (top left)
 * @color
 * @default #1257D6
 */
uniform vec3 u_royal;
/**
 * @label Cyan (left)
 * @color
 * @default #04C3EA
 */
uniform vec3 u_cyan;
/**
 * @label Mint (light core)
 * @color
 * @default #A9F2D3
 */
uniform vec3 u_mint;
/**
 * @label Haze (top)
 * @color
 * @default #C7D8F2
 */
uniform vec3 u_haze;
/**
 * @label Lavender (top right)
 * @color
 * @default #D29BEC
 */
uniform vec3 u_lav;
/**
 * @label Indigo (right)
 * @color
 * @default #3E50D4
 */
uniform vec3 u_indigo;
/**
 * @label Edge (vignette, no black)
 * @color
 * @default #0B3C9E
 */
uniform vec3 u_edge;
/**
 * @label Speed
 * @range 0.0, 1.0
 * @default 0.16
 */
uniform float u_speed;
/**
 * @label Mouse Follow
 * @range 0.0, 1.0
 * @default 0.35
 */
uniform float u_follow;
/**
 * @label Light Core
 * @range 0.0, 1.5
 * @default 1.0
 */
uniform float u_core;
/**
 * @label Vignette
 * @range 0.0, 1.0
 * @default 0.45
 */
uniform float u_vignette;
/**
 * @label Light Beam
 * @range 0.0, 1.0
 * @default 0.5
 */
uniform float u_beam;
/**
 * @label Grain
 * @range 0.0, 0.12
 * @default 0.025
 */
uniform float u_grain;

float hash(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p){
  vec2 i = floor(p); vec2 f = fract(p);
  float a = hash(i), b = hash(i + vec2(1.0, 0.0)), c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p){ return noise(p) * 0.65 + noise(p * 2.1 + 7.3) * 0.35; }

float blob(vec2 q, vec2 c, vec2 s, float asp){
  vec2 d = (q - vec2(c.x * asp, c.y)) / vec2(s.x * asp, s.y);
  return exp(-dot(d, d));
}

float blobR(vec2 q, vec2 c, vec2 s, float a, float asp){
  vec2 d = q - vec2(c.x * asp, c.y);
  d = mat2(cos(a), -sin(a), sin(a), cos(a)) * d;
  d /= vec2(s.x * asp, s.y);
  return exp(-dot(d, d));
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  uv.y = 1.0 - uv.y;
  float asp = u_resolution.x / u_resolution.y;
  float t = u_time * u_speed;

  float hasM = step(1.0, u_mouse.x + u_mouse.y);
  vec2 m = u_mouse / u_resolution; m.y = 1.0 - m.y;
  vec2 mo = (m - vec2(0.56, 0.46)) * hasM * u_follow;

  vec2 q = vec2(uv.x * asp, uv.y);
  vec2 w = vec2(fbm(q * 1.4 + vec2(t, -t * 0.6)), fbm(q * 1.4 + vec2(-t * 0.7, t * 0.8) + 5.2)) - 0.5;
  q += w * 0.34;
  q.x += (fbm(vec2(q.y * 3.0 - t * 0.4, q.x * 0.8)) - 0.5) * 0.10;
  q -= vec2(mo.x * asp, mo.y) * 0.25;

  vec2 dr = vec2(sin(t * 0.9), cos(t * 0.7)) * 0.035;

  float gCyan  = blob(q, vec2(0.08, 0.68) + dr,                      vec2(0.36, 0.48), asp) * 2.3;
  float gRoyal = blob(q, vec2(0.26, 0.08) - dr,                      vec2(0.32, 0.30), asp) * 1.7;
  float gMint  = blobR(q, vec2(0.56, 0.47) + mo + dr * 0.6, vec2(0.17, 0.13), 0.55, asp) * 3.0 * u_core
               + blobR(q, vec2(0.62, 0.34) + mo * 0.8, vec2(0.10, 0.06), 0.75, asp) * 1.6 * u_core;
  float gMint2 = blob(q, vec2(0.46, 0.60) + mo * 0.6 - dr * 0.5,     vec2(0.19, 0.12), asp) * 1.9 * u_core;
  float gHaze  = blob(q, vec2(0.53, 0.02) + vec2(dr.y, 0.0),         vec2(0.22, 0.15), asp) * 1.6;
  float gLav   = blob(q, vec2(0.74, 0.12) + vec2(-dr.x, dr.y) * 0.8, vec2(0.14, 0.19), asp) * 2.6;
  float gInd   = blob(q, vec2(0.79, 0.60) + vec2(dr.y, -dr.x),       vec2(0.10, 0.26), asp) * 1.7;
  float gBlue  = blob(q, vec2(0.90, 0.90),                           vec2(0.32, 0.30), asp) * 1.6;
  float wBase  = 0.10;
  gCyan = pow(gCyan, 1.6); gRoyal = pow(gRoyal, 1.6); gMint = pow(gMint, 1.6); gMint2 = pow(gMint2, 1.6); gHaze = pow(gHaze, 1.6); gLav = pow(gLav, 1.6); gInd = pow(gInd, 1.6); gBlue = pow(gBlue, 1.6);

  vec3 col = u_base * (wBase + gBlue) + u_cyan * gCyan + u_royal * gRoyal + u_mint * gMint
           + mix(u_mint, u_cyan, 0.35) * gMint2 + u_haze * gHaze + u_lav * gLav + u_indigo * gInd;
  col /= (wBase + gBlue + gCyan + gRoyal + gMint + gMint2 + gHaze + gLav + gInd);

  vec2 bd = normalize(vec2(1.0, -0.62));
  vec2 bp = uv - vec2(0.80 + sin(t * 0.5) * 0.03, 0.90);
  float across = dot(bp, vec2(-bd.y, bd.x));
  float along = dot(bp, bd);
  float beam = exp(-pow(across / 0.055, 2.0)) * smoothstep(0.32, 0.0, abs(along));
  col += beam * u_beam * 0.10 * vec3(0.55, 0.85, 1.0);

  float v = smoothstep(0.42, 1.0, length((uv - 0.5) * vec2(1.0, 1.2)) * 1.25);
  col = mix(col, u_edge, v * u_vignette);

  col += (hash(gl_FragCoord.xy + fract(u_time * 3.0) * 71.3) - 0.5) * u_grain;
  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
