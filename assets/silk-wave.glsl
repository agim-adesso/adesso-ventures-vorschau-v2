precision mediump float;

/** @resolution */
uniform vec2 u_resolution;
/** @time */
uniform float u_time;
/** @backdrop */
uniform sampler2D u_backdrop;

/**
 * @label Wave Amount (px)
 * @range 0.0, 40.0
 * @default 14.0
 */
uniform float u_amp;
/**
 * @label Play Duration (s, 0 = static)
 * @range 0.0, 5.0
 * @default 4.5
 */
uniform float u_play;
/**
 * @label Preview Loop (1 = repeat for canvas preview, 0 = play once like live)
 * @range 0.0, 1.0
 * @default 1.0
 */
uniform float u_preview;
/**
 * @label Rest in Preview (s)
 * @range 1.0, 10.0
 * @default 3.0
 */
uniform float u_rest;

// Bewegt das echte Ribbon-Bild dahinter wie Stoff. Die Verformung klingt in u_play Sekunden
// auf null ab: danach ist das Bild exakt die statische Grafik (WCAG 2.2.2).
void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  float cyc = u_play + u_rest;
  float tt = u_preview > 0.5 ? mod(u_time, cyc) : u_time;
  float p = u_play > 0.0 ? clamp(tt / u_play, 0.0, 1.0) : 1.0;
  float fade = pow(1.0 - p, 2.0);            // Ausschlag klingt weich aus
  float ph = tt * 2.2;

  float a = u_amp * fade / u_resolution.y;
  float wave = sin(uv.x * 6.0 - ph) * 0.7 + sin(uv.x * 13.0 + ph * 1.4) * 0.3;
  float along = sin(uv.y * 4.0 + ph * 0.8);
  vec2 off = vec2(along * a * 0.35 * u_resolution.y / u_resolution.x, wave * a);

  gl_FragColor = vec4(texture2D(u_backdrop, clamp(uv + off, 0.001, 0.999)).rgb, 1.0);
}
