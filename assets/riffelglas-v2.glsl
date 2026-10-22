precision mediump float;

/** @resolution */
uniform vec2 u_resolution;

/** @backdrop */
uniform sampler2D u_backdrop;

/**
 * @label Rillenbreite (px)
 * @range 12.0, 120.0
 * @default 44.0
 */
uniform float u_rib;

/**
 * @label Brechung
 * @range 0.0, 0.12
 * @default 0.045
 */
uniform float u_refr;

/**
 * @label Milchglas (Unschärfe)
 * @range 0.0, 1.0
 * @default 0.55
 */
uniform float u_frost;

/**
 * @label Licht
 * @range 0.0, 1.0
 * @default 0.6
 */
uniform float u_light;

/**
 * @label Klar (Scroll-Zustand, 1 = klar)
 * @range 0.0, 1.0
 * @default 0.0
 */
uniform float u_clear;

/**
 * @label Farbsaum
 * @range 0.0, 1.0
 * @default 0.35
 */
uniform float u_chroma;

/**
 * @label Korn
 * @range 0.0, 0.1
 * @default 0.025
 */
uniform float u_grain;

float hash(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }

vec3 frosted(vec2 uv, float amt) {
  // 9-Tap-Weichzeichner, quer stärker als längs (wie gezogenes Glas)
  vec2 px = 1.0 / u_resolution;
  vec2 rx = vec2(px.x * 30.0 * amt, 0.0);
  vec2 ry = vec2(0.0, px.y * 10.0 * amt);
  vec3 c = texture2D(u_backdrop, uv).rgb * 0.20;
  c += texture2D(u_backdrop, uv + rx).rgb * 0.13;
  c += texture2D(u_backdrop, uv - rx).rgb * 0.13;
  c += texture2D(u_backdrop, uv + rx * 2.0).rgb * 0.08;
  c += texture2D(u_backdrop, uv - rx * 2.0).rgb * 0.08;
  c += texture2D(u_backdrop, uv + ry).rgb * 0.12;
  c += texture2D(u_backdrop, uv - ry).rgb * 0.12;
  c += texture2D(u_backdrop, uv + rx + ry).rgb * 0.07;
  c += texture2D(u_backdrop, uv - rx - ry).rgb * 0.07;
  return c;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  float k = 1.0 - u_clear;

  // Position innerhalb der Rille: -1 (linke Kante) .. 1 (rechte Kante)
  float f = fract(gl_FragCoord.x / u_rib);
  float x = f * 2.0 - 1.0;

  // Zylinderlinse: Bild wird zur Rillenmitte gestaucht, an den Kanten gedehnt
  float bend = x * (1.0 + 0.6 * x * x);
  vec2 off = vec2(-bend * u_refr * k, 0.0);

  // leichte Unregelmäßigkeit pro Rille, damit es nicht wie ein Muster aussieht
  float ribId = floor(gl_FragCoord.x / u_rib);
  off.x += (hash(vec2(ribId, 3.1)) - 0.5) * 0.004 * k;

  float amt = u_frost * k * (0.55 + 0.45 * x * x);
  vec2 ch = vec2(u_chroma * 0.004 * x * k, 0.0);
  vec3 col;
  col.r = frosted(uv + off + ch, amt).r;
  col.g = frosted(uv + off, amt).g;
  col.b = frosted(uv + off - ch, amt).b;

  // Licht: weiche Glanzbahn links der Mitte, oben etwas heller
  float vert = mix(0.75, 1.15, uv.y);
  float spec = exp(-pow((x + 0.35) / 0.22, 2.0)) * 0.22 * u_light * k * vert;
  // dünne helle Kante am Rillenanfang, dunkle Fuge am Rillenende
  float rim = smoothstep(-0.86, -1.0, x) * 0.18 * u_light * k;
  float groove = smoothstep(0.80, 1.0, x) * 0.16 * u_light * k;
  // leichte Abdunklung zur rechten Rillenhälfte (Rundung)
  float shade = smoothstep(0.0, 1.0, x) * 0.06 * u_light * k;

  col = col + spec + rim - groove - shade;
  col = mix(col, col * 0.96 + 0.04, 0.5 * k); // minimal milchig
  col += (hash(gl_FragCoord.xy) - 0.5) * u_grain;
  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
