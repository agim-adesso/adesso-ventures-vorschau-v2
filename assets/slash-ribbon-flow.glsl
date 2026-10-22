precision mediump float;

// Genie · Slash-Ribbon Flow
// Procedural silk ribbon (twisted strip) whose twists travel along its length,
// lit per pixel (diffuse + silk specular), rendered as adesso slashes.

/** @resolution */
uniform vec2 u_resolution;

/** @time */
uniform float u_time;

/**
 * @label Zellgröße (px)
 * @default 16
 * @range 6, 48
 */
uniform float u_size;

/**
 * @label Fließgeschwindigkeit
 * @default 0.6
 * @range 0, 3
 */
uniform float u_speed;

/**
 * @label Anzahl Drehungen
 * @default 1.6
 * @range 0.3, 4
 */
uniform float u_twist;

/**
 * @label Bandbreite
 * @default 0.12
 * @range 0.04, 0.3
 */
uniform float u_width;

/**
 * @label Wellenhub der Mittellinie
 * @default 0.035
 * @range 0, 0.12
 */
uniform float u_sway;

/**
 * @label Glanz (Specular)
 * @default 0.9
 * @range 0, 2
 */
uniform float u_gloss;

/**
 * @label Nur 10 Brand-Stärken (1) / stufenlos (0)
 * @default 1
 * @range 0, 1
 */
uniform float u_quantize;

/**
 * @label Farbe nach Seite (1) / nach Licht (0)
 * @default 1
 * @range 0, 1
 */
uniform float u_faceColor;

/**
 * @label Farbe Vorderseite / Licht
 * @color
 * @default #28DCAA
 */
uniform vec3 u_colFront;

/**
 * @label Farbe Rückseite / Schatten
 * @color
 * @default #00C1FF
 */
uniform vec3 u_colBack;

const float PI = 3.14159265;

float slashWeight(float level) {
  if (level > 9.5) return 2.0;
  if (level > 8.5) return 0.8145;
  if (level > 7.5) return 0.6788;
  if (level > 6.5) return 0.5430;
  if (level > 5.5) return 0.4073;
  if (level > 4.5) return 0.2987;
  if (level > 3.5) return 0.2172;
  if (level > 2.5) return 0.0943;
  if (level > 1.5) return 0.0629;
  if (level > 0.5) return 0.0314;
  return 0.0136;
}

// centerline in normalised coords (y up): rises from bottom-left to top-right with a plateau
float centre(float u, float t) {
  // bottom-left entry, plateau between headline and CTA block, steep rise after the headline
  return -0.02 + 0.42 * smoothstep(0.0, 0.3, u) + 0.12 * smoothstep(0.45, 0.75, u)
       + 0.40 * smoothstep(0.78, 1.0, u)
       + u_sway * sin(u * 6.0 - t * 0.8) + u_sway * 0.5 * sin(u * 13.0 - t * 1.3);
}

// returns lum (x), coverage (y), face (z: 1 front, 0 back)
vec3 ribbon(vec2 px, float t) {
  float aspect = u_resolution.y / u_resolution.x;
  float u = px.x / u_resolution.x;
  float y = px.y / u_resolution.y;
  float c = centre(u, t);
  float dc = (centre(u + 0.002, t) - centre(u - 0.002, t)) / 0.004;    // dy/du (normalised)
  float slope = dc * aspect;                                         // in square units
  float cosA = inversesqrt(1.0 + slope * slope);
  float w = u_width * (0.85 + 0.15 * sin(u * 4.0 + 1.0)) * (1.0 - 0.35 * smoothstep(0.6, 1.0, u));
  float theta = 2.0 * PI * u_twist * u - t * u_speed * 2.0;          // twist travels along +u
  float ct = cos(theta), st = sin(theta);
  float hw = w * max(abs(ct), 0.03);
  float s = (y - c) * cosA;                                          // perpendicular-ish distance
  float edge = abs(s) - hw;
  float cov = clamp(1.0 - edge / (u_size / u_resolution.y), 0.0, 1.0);
  if (edge > u_size / u_resolution.y) return vec3(0.0);
  float v = clamp(s / hw, -1.0, 1.0);
  // in-plane frame
  vec2 T = normalize(vec2(1.0, slope));
  vec2 N = vec2(-T.y, T.x);
  // surface normal of the twisted strip + soft cross-curvature (silk drape)
  vec3 n = vec3(N * st, ct);
  vec3 Wd = vec3(N * ct, -st);
  n = normalize(n + Wd * v * 0.55);
  float face = 1.0;
  if (n.z < 0.0) { n = -n; face = 0.0; }
  vec3 L = normalize(vec3(-0.45, 0.65, 0.62));
  vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
  float diff = max(dot(n, L), 0.0);
  float spec = pow(max(dot(n, H), 0.0), 36.0);
  float lum = 0.10 + 0.62 * diff + u_gloss * spec;
  lum *= 1.0 - 0.25 * v * v;                                         // darker towards the edges
  return vec3(clamp(lum, 0.0, 1.0), cov, face);
}

void main() {
  vec2 cell = floor(gl_FragCoord.xy / u_size);
  vec2 center = (cell + 0.5) * u_size;
  vec3 r = ribbon(center, u_time);
  if (r.y < 0.2) { gl_FragColor = vec4(0.0); return; }
  float L = r.x * smoothstep(0.2, 0.8, r.y);
  float w = u_quantize > 0.5 ? slashWeight(floor(L * 10.0 + 0.5)) : (L > 0.97 ? 2.0 : mix(0.0136, 0.8145, L));
  vec2 p = fract(gl_FragCoord.xy / u_size);
  p.y = 1.0 - p.y;
  float dist = (abs(p.x + p.y - 1.0) - w) * u_size * 0.7071;
  float inside = clamp(0.5 - dist, 0.0, 1.0);
  vec3 col;
  if (u_faceColor > 0.5) col = r.z > 0.5 ? u_colFront : u_colBack;
  else col = r.x > 0.45 ? u_colFront : u_colBack;
  gl_FragColor = vec4(col * inside, inside);
}
