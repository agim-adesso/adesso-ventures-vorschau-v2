precision mediump float;

// Genie · Slash-Ribbon Grow + Flow
// Uses the REAL ribbon rendering (@content) as start motif:
//  1. growth: the ribbon builds up along its length (bottom-left → top-right),
//     cells appear as hairlines at the growth front and thicken behind it
//  2. flow: the silhouette stays, but folds and highlights stream along the band
//     (flow-map technique, two phases cross-faded), guided by a data texture
//     that stores centre line + half width of the ribbon per column.

/** @resolution */
uniform vec2 u_resolution;

/** @content */
uniform sampler2D u_content;

/** @time */
uniform float u_time;

/**
 * @label Band-Daten (Mittellinie/Breite je Spalte)
 */
uniform sampler2D u_data;

/**
 * @label Zellgröße (px)
 * @default 16
 * @range 6, 48
 */
uniform float u_size;

/**
 * @label Schwarzpunkt
 * @default 0.32
 * @range 0, 1
 */
uniform float u_lo;

/**
 * @label Weißpunkt
 * @default 0.92
 * @range 0, 1
 */
uniform float u_hi;

/**
 * @label Zweifarbig (1) / einfarbig (0)
 * @default 1
 * @range 0, 1
 */
uniform float u_twoTone;

/**
 * @label Schwelle Licht/Schatten
 * @default 0.45
 * @range 0, 1
 */
uniform float u_split;

/**
 * @label Fließen · Tempo (0 = aus)
 * @default 0.6
 * @range 0, 3
 */
uniform float u_flow;

/**
 * @label Fließen · Weg pro Zyklus (Anteil der Breite)
 * @default 0.12
 * @range 0.02, 0.4
 */
uniform float u_flowDist;

/**
 * @label Wachstum · Zyklus in Sekunden (0 = sofort voll)
 * @default 9
 * @range 0, 30
 */
uniform float u_growLoop;

/**
 * @label Wachstum · Anteil des Zyklus fürs Aufbauen
 * @default 0.55
 * @range 0.1, 1
 */
uniform float u_growPart;

/**
 * @label Farbe Licht
 * @color
 * @default #28DCAA
 */
uniform vec3 u_colLight;

/**
 * @label Farbe Schatten
 * @color
 * @default #00C1FF
 */
uniform vec3 u_colShade;

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

float lumOf(vec4 c) {
  vec3 col = c.rgb / max(c.a, 0.001);
  return dot(col, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
  vec2 cell = floor(gl_FragCoord.xy / u_size);
  vec2 center = (cell + 0.5) * u_size;
  vec2 uv = center / u_resolution;

  vec4 base = texture2D(u_content, uv);
  float a = base.a;
  if (a < 0.25) { gl_FragColor = vec4(0.0); return; }
  float lum = lumOf(base);

  // ---- flow along the ribbon ----
  if (u_flow > 0.0) {
    vec4 d0 = texture2D(u_data, vec2(uv.x, 0.5));
    if (d0.b > 0.5) {
      float hw0 = max(d0.g * 0.5, 0.002);
      float v = (uv.y - d0.r) / hw0;               // -1 … 1 across the band
      float acc = 0.0, wsum = 0.0;
      for (int k = 0; k < 2; k++) {
        float phase = fract(u_time * u_flow * 0.1 + float(k) * 0.5);
        float us = uv.x - phase * u_flowDist;
        vec4 ds = texture2D(u_data, vec2(us, 0.5));
        vec2 uvs = vec2(us, ds.r + v * ds.g * 0.5);
        vec4 s = texture2D(u_content, uvs);
        float l = (us > 0.0 && ds.b > 0.5 && s.a > 0.2) ? lumOf(s) : lum;
        float wk = 1.0 - abs(2.0 * phase - 1.0);
        acc += wk * l; wsum += wk;
      }
      lum = acc / max(wsum, 0.001);
    }
  }

  float L = clamp((lum - u_lo) / max(0.001, u_hi - u_lo), 0.0, 1.0);
  L *= smoothstep(0.25, 0.75, a);

  // ---- growth along the ribbon (bottom-left → top-right) ----
  if (u_growLoop > 0.0) {
    float ph = mod(u_time, u_growLoop) / u_growLoop;
    float g = smoothstep(0.0, u_growPart, ph) * 1.15;   // front position in uv.x
    if (uv.x > g) { gl_FragColor = vec4(0.0); return; }
    L *= smoothstep(g, g - 0.14, uv.x);                 // hairlines at the front
  }

  float w = slashWeight(floor(L * 10.0 + 0.5));
  vec2 p = fract(gl_FragCoord.xy / u_size);
  p.y = 1.0 - p.y;
  float dist = (abs(p.x + p.y - 1.0) - w) * u_size * 0.7071;
  float inside = clamp(0.5 - dist, 0.0, 1.0);
  vec3 outCol = u_colLight;
  if (u_twoTone > 0.5 && lum < mix(u_lo, u_hi, u_split)) outCol = u_colShade;
  gl_FragColor = vec4(outCol * inside, inside);
}
