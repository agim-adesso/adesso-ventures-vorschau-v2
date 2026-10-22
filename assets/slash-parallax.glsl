precision mediump float;

// Genie · Slash-Parallax
// Two layers of adesso slashes behind a cut-out portrait. Both layers shift
// against the mouse position by different amounts → depth. Persons stay still
// (they are separate layers above this fill).

/** @resolution */
uniform vec2 u_resolution;

/** @mouse */
uniform vec2 u_mouse;

/**
 * @label Tiefe (max. Verschiebung in px)
 * @default 18
 * @range 0, 60
 */
uniform float u_depth;

/**
 * @label Zellgröße hinten (px)
 * @default 18
 * @range 8, 40
 */
uniform float u_sizeBack;

/**
 * @label Zellgröße vorne (px)
 * @default 32
 * @range 12, 64
 */
uniform float u_sizeFront;

/**
 * @label Dichte vorne
 * @default 0.22
 * @range 0, 1
 */
uniform float u_frontDensity;

/**
 * @label Farbe
 * @color
 * @default #28DCAA
 */
uniform vec3 u_col;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

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

// coverage of one slash layer at pixel px
float layer(vec2 px, float S, float seed, float density, float heavy) {
  vec2 cell = floor(px / S);
  float r1 = hash(cell + seed);
  float r2 = hash(cell + seed + 17.0);
  if (r1 > density) return 0.0;
  // heavier towards the bottom of the card (hairline at the top → block at the bottom)
  float t = 1.0 - clamp(((cell.y + 0.5) * S) / u_resolution.y, 0.0, 1.0);
  float v = clamp(t * 0.9 + heavy + (r2 - 0.5) * 0.25, 0.0, 1.0);
  float w = slashWeight(floor(v * 10.0 + 0.5));
  vec2 p = fract(px / S);
  p.y = 1.0 - p.y;
  float d = (abs(p.x + p.y - 1.0) - w) * S * 0.7071;
  return clamp(0.5 - d, 0.0, 1.0);
}

void main() {
  // mouse relative to the centre of this node, -1 … 1 (clamped so it also behaves outside the node)
  vec2 m = clamp((u_mouse - u_resolution * 0.5) / (u_resolution * 0.5), -1.5, 1.5);
  vec2 px = gl_FragCoord.xy;
  float back  = layer(px + m * u_depth * 0.35, u_sizeBack, 3.0, 0.85, -0.15) * 0.45;
  float front = layer(px + m * u_depth, u_sizeFront, 11.0, u_frontDensity, 0.15) * 0.9;
  float a = max(back, front);
  gl_FragColor = vec4(u_col * a, a);
}
