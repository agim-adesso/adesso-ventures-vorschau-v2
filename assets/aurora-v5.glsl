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
 * @default #2263D8
 */
uniform vec3 u_base;
/**
 * @label Royal (top left)
 * @color
 * @default #1556D8
 */
uniform vec3 u_royal;
/**
 * @label Cyan (left)
 * @color
 * @default #06C6EA
 */
uniform vec3 u_cyan;
/**
 * @label Teal (transition)
 * @color
 * @default #2CC4D2
 */
uniform vec3 u_teal;
/**
 * @label Mint (light core)
 * @color
 * @default #A4F0D2
 */
uniform vec3 u_mint;
/**
 * @label Haze (top)
 * @color
 * @default #BACBEA
 */
uniform vec3 u_haze;
/**
 * @label Lavender (top right)
 * @color
 * @default #D8A6EE
 */
uniform vec3 u_lav;
/**
 * @label Orchid (lavender core)
 * @color
 * @default #BC7CE0
 */
uniform vec3 u_orchid;
/**
 * @label Indigo (right)
 * @color
 * @default #3C4FD2
 */
uniform vec3 u_indigo;
/**
 * @label Edge (corners, no black)
 * @color
 * @default #0A2C82
 */
uniform vec3 u_edge;
/**
 * @label Speed (0 = static / reduced motion)
 * @range 0.0, 1.0
 * @default 0.10
 */
uniform float u_speed;
/**
 * @label Mouse Parallax (minimal)
 * @range 0.0, 0.3
 * @default 0.05
 */
uniform float u_follow;
/**
 * @label Light Core
 * @range 0.0, 2.0
 * @default 1.4
 */
uniform float u_core;
/**
 * @label Corners
 * @range 0.0, 1.0
 * @default 0.7
 */
uniform float u_vignette;
/**
 * @label Light Beam
 * @range 0.0, 1.0
 * @default 1.0
 */
uniform float u_beam;
/**
 * @label Softness (fold warp)
 * @range 0.0, 0.4
 * @default 0.16
 */
uniform float u_warp;
/**
 * @label Zone Sharpness
 * @range 1.0, 2.0
 * @default 1.6
 */
uniform float u_sharp;
/**
 * @label Saturation
 * @range 0.8, 1.5
 * @default 1.18
 */
uniform float u_sat;
/**
 * @label Grain
 * @range 0.0, 0.12
 * @default 0.02
 */
uniform float u_grain;

float hash(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float noise(vec2 p){
  vec2 i = floor(p); vec2 f = fract(p);
  float a = hash(i), b = hash(i + vec2(1.0, 0.0)), c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p){ return noise(p) * 0.65 + noise(p * 2.03 + 7.3) * 0.35; }

// Jedes Feld treibt auf eigener Bahn: eigene Frequenz, eigene Phase, eigene Amplitude
vec2 drift(float t, float f1, float f2, float ph, float amp){
  return vec2(sin(t * f1 + ph), cos(t * f2 + ph * 1.7)) * amp;
}

float field(vec2 q, vec2 c, vec2 s, float a, float asp){
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

  // Maus: nur sanfte Parallaxe (wenige Prozent), Tiefe je Ebene verschieden
  float hasM = step(1.0, u_mouse.x + u_mouse.y);
  vec2 m = u_mouse / u_resolution; m.y = 1.0 - m.y;
  vec2 mo = (m - 0.5) * hasM * u_follow;

  vec2 q = vec2(uv.x * asp, uv.y);
  // großflächige, langsame Faltung statt Blob-Kanten
  vec2 w = vec2(fbm(q * 0.9 + vec2(t * 0.6, -t * 0.4)), fbm(q * 0.9 + vec2(-t * 0.5, t * 0.45) + 5.2)) - 0.5;
  q += w * u_warp;

  // Hinten (wenig Parallaxe) -> vorne (mehr Parallaxe)
  float gRoyal  = field(q, vec2(0.24, 0.04) + drift(t, 0.53, 0.41, 0.0, 0.04) + mo * 0.3, vec2(0.34, 0.20), 0.10, asp) * 1.3;
  float gCyan   = field(q, vec2(0.15, 0.60) + drift(t, 0.37, 0.49, 1.3, 0.05) + mo * 0.4, vec2(0.44, 0.42), 0.35, asp) * 2.6;
  float gCyan2  = field(q, vec2(0.10, 0.80) + drift(t, 0.61, 0.33, 2.1, 0.04) + mo * 0.4, vec2(0.22, 0.19), 0.0, asp) * 1.6;
  float gTeal   = field(q, vec2(0.36, 0.45) + drift(t, 0.44, 0.58, 3.7, 0.05) + mo * 0.6, vec2(0.25, 0.24), 0.5, asp) * 1.4;
  float gMint   = field(q, vec2(0.54, 0.50) + drift(t, 0.29, 0.38, 0.8, 0.045) + mo * 1.0, vec2(0.25, 0.19), -0.55, asp) * 4.0 * u_core;
  float gFold   = field(q, vec2(0.48, 0.32) + drift(t, 0.47, 0.31, 4.4, 0.035) + mo * 0.9, vec2(0.22, 0.06), -0.62, asp) * 2.2 * u_core;
  float gLight  = field(q, vec2(0.57, 0.56) + drift(t, 0.35, 0.52, 5.9, 0.03) + mo * 1.0, vec2(0.11, 0.09), -0.4, asp) * 2.6 * u_core;
  float gMint3  = field(q, vec2(0.42, 0.60) + drift(t, 0.51, 0.34, 6.6, 0.04) + mo * 0.8, vec2(0.16, 0.10), -0.3, asp) * 1.6 * u_core;
  float gHaze   = field(q, vec2(0.55, 0.02) + drift(t, 0.31, 0.27, 2.6, 0.04) + mo * 0.3, vec2(0.22, 0.14), 0.0, asp) * 2.0;
  float gLav    = field(q, vec2(0.70, 0.10) + drift(t, 0.39, 0.45, 1.9, 0.035) + mo * 0.5, vec2(0.18, 0.22), 0.0, asp) * 3.6;
  float gOrchid = field(q, vec2(0.72, 0.22) + drift(t, 0.57, 0.36, 3.1, 0.03) + mo * 0.5, vec2(0.08, 0.12), 0.0, asp) * 2.6;
  float gInd    = field(q, vec2(0.78, 0.55) + drift(t, 0.33, 0.55, 4.9, 0.035) + mo * 0.7, vec2(0.06, 0.20), 0.15, asp) * 2.6;
  float gRight  = field(q, vec2(0.96, 0.42) + drift(t, 0.27, 0.43, 0.4, 0.03) + mo * 0.3, vec2(0.14, 0.42), 0.0, asp) * 1.0;
  float gBottom = field(q, vec2(0.70, 0.97) + drift(t, 0.42, 0.29, 5.3, 0.04) + mo * 0.3, vec2(0.42, 0.17), 0.12, asp) * 1.0;
  float wBase = 0.10;
  // Zonen klarer trennen (wie im Deck), ohne harte Blob-Kanten
  float sp = u_sharp;
  gRoyal = pow(gRoyal, sp); gCyan = pow(gCyan, sp); gCyan2 = pow(gCyan2, sp); gTeal = pow(gTeal, sp);
  gMint = pow(gMint, sp); gFold = pow(gFold, sp); gLight = pow(gLight, sp); gMint3 = pow(gMint3, sp);
  gHaze = pow(gHaze, sp); gLav = pow(gLav, sp); gOrchid = pow(gOrchid, sp); gInd = pow(gInd, sp);
  gRight = pow(gRight, sp); gBottom = pow(gBottom, sp);

  vec3 col = u_base * (wBase + gRight * 0.6 + gBottom * 0.7)
           + vec3(0.17, 0.50, 0.89) * gRight * 0.4 + u_royal * gBottom * 0.3
           + u_royal * gRoyal + u_cyan * gCyan + mix(u_cyan, vec3(0.30, 0.90, 0.96), 0.35) * gCyan2
           + u_teal * gTeal + u_mint * gMint + mix(u_mint, u_teal, 0.3) * gFold
           + mix(u_mint, vec3(1.0), 0.55) * gLight + mix(u_mint, u_teal, 0.45) * gMint3 + u_haze * gHaze + u_lav * gLav
           + u_orchid * gOrchid + u_indigo * gInd;
  col /= (wBase + gRight + gBottom + gRoyal + gCyan + gCyan2 + gTeal + gMint + gFold + gLight + gMint3 + gHaze + gLav + gOrchid + gInd);

  // Sättigung leicht anheben (Mischfarben werden sonst pastellig)
  float lum = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(vec3(lum), col, u_sat);

  // schwache diagonale Lichtbahn unten rechts (wie im Deck)
  vec2 bd = normalize(vec2(1.0, 0.85));
  vec2 bp = uv - vec2(0.79 + sin(t * 0.45 + 1.0) * 0.02, 0.90) - mo * 0.4;
  float across = dot(bp, vec2(-bd.y, bd.x));
  float along = dot(bp, bd);
  float beam = smoothstep(0.06, 0.01, abs(across)) * smoothstep(0.22, 0.04, abs(along));
  col = mix(col, vec3(0.20, 0.66, 0.88), beam * u_beam * 0.9);

  // dunkle Ecken (navy, nie schwarz) – oben links, unten links stärker
  vec2 cv = (uv - 0.5) * vec2(1.0, 1.15);
  float v = smoothstep(0.45, 0.85, length(cv));
  float leftBias = smoothstep(0.35, 0.0, uv.x) * smoothstep(0.30, 0.0, min(uv.y, 1.0 - uv.y));
  col = mix(col, u_edge, clamp(v * 0.8 + leftBias * 0.8, 0.0, 1.0) * u_vignette);

  col += (hash(gl_FragCoord.xy + fract(u_time * 3.0) * 71.3) - 0.5) * u_grain;
  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
