precision mediump float;

/** @resolution */
uniform vec2 u_resolution;

/** @content */
uniform sampler2D u_content;

/** @time */
uniform float u_time;

/**
 * @label Zellgröße (px)
 * @default 16
 * @range 6, 48
 */
uniform float u_size;

/**
 * @label Schwarzpunkt (Helligkeit → Haarlinie)
 * @default 0.32
 * @range 0, 1
 */
uniform float u_lo;

/**
 * @label Weißpunkt (Helligkeit → Quadrat)
 * @default 0.92
 * @range 0, 1
 */
uniform float u_hi;

/**
 * @label Nur 10 Brand-Stärken (1) oder stufenlos (0)
 * @default 1
 * @range 0, 1
 */
uniform float u_quantize;

/**
 * @label Zweifarbig (1) oder einfarbig (0)
 * @default 1
 * @range 0, 1
 */
uniform float u_twoTone;

/**
 * @label Schwelle Vorder-/Rückseite
 * @default 0.45
 * @range 0, 1
 */
uniform float u_split;

/**
 * @label Wandernder Glanz (0 = aus)
 * @default 0
 * @range 0, 1
 */
uniform float u_sweep;

/**
 * @label Welle · Amplitude (0 = steht still)
 * @default 0
 * @range 0, 0.05
 */
uniform float u_wave;

/**
 * @label Welle · Geschwindigkeit
 * @default 0.8
 * @range 0, 4
 */
uniform float u_waveSpeed;

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

// The ten adesso slash weights (half-width of the diagonal band, cell = 1).
float slashWeight(float level) {
  if (level > 9.5) return 2.0;          // Quadrat
  if (level > 8.5) return 0.8145;       // slashes-01
  if (level > 7.5) return 0.6788;
  if (level > 6.5) return 0.5430;
  if (level > 5.5) return 0.4073;
  if (level > 4.5) return 0.2987;
  if (level > 3.5) return 0.2172;
  if (level > 2.5) return 0.0943;
  if (level > 1.5) return 0.0629;
  if (level > 0.5) return 0.0314;
  return 0.0136;                        // slashes-10, Haarlinie
}

void main() {
  vec2 cell = floor(gl_FragCoord.xy / u_size);
  vec2 center = (cell + 0.5) * u_size;
  vec2 uv = center / u_resolution;
  if (u_wave > 0.0) {
    // silk-like undulation: two travelling sine waves displace the sampling position
    float t = u_time * u_waveSpeed;
    uv.y += u_wave * sin(uv.x * 9.0 - t) + u_wave * 0.5 * sin(uv.x * 23.0 + t * 1.7);
    uv.x += u_wave * 0.4 * sin(uv.y * 7.0 + t * 0.6);
  }
  vec4 c = texture2D(u_content, uv);
  float a = c.a;
  if (a < 0.25) { gl_FragColor = vec4(0.0); return; }
  vec3 col = c.rgb / a;
  float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
  float L = clamp((lum - u_lo) / max(0.001, u_hi - u_lo), 0.0, 1.0);

  // optional light sweep along the diagonal (animation)
  if (u_sweep > 0.0) {
    float d = (center.x + center.y) / (u_resolution.x + u_resolution.y);
    float band = smoothstep(0.12, 0.0, abs(fract(d - u_time * 0.08) - 0.5));
    L = clamp(L + band * u_sweep * 0.6, 0.0, 1.0);
  }

  // thin out at the silhouette (partial coverage)
  L *= smoothstep(0.25, 0.75, a);

  float w;
  if (u_quantize > 0.5) {
    w = slashWeight(floor(L * 10.0 + 0.5));
  } else {
    w = L > 0.97 ? 2.0 : mix(0.0136, 0.8145, L);
  }

  // local coordinates inside the cell, y pointing down like the SVG slashes
  vec2 p = fract(gl_FragCoord.xy / u_size);
  p.y = 1.0 - p.y;
  float dist = (abs(p.x + p.y - 1.0) - w) * u_size * 0.7071; // pixels
  float inside = clamp(0.5 - dist, 0.0, 1.0);

  vec3 outCol = u_colLight;
  if (u_twoTone > 0.5 && lum < mix(u_lo, u_hi, u_split)) outCol = u_colShade;
  gl_FragColor = vec4(outCol * inside, inside);
}
