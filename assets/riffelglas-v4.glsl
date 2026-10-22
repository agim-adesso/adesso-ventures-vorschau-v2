precision mediump float;

/** @resolution */
uniform vec2 u_resolution;
/** @backdrop */
uniform sampler2D u_backdrop;
/** @mouse */
uniform vec2 u_mouse;

/**
 * @label Ribs (count across width)
 * @range 4.0, 80.0
 * @default 22.0
 */
uniform float u_ribs;
/**
 * @label Lens (neg = flipped image per rib)
 * @range -4.0, 2.0
 * @default -1.8
 */
uniform float u_lens;
/**
 * @label Frost (vertical blur)
 * @range 0.0, 0.05
 * @default 0.012
 */
uniform float u_frost;
/**
 * @label Chromatic dispersion
 * @range 0.0, 0.01
 * @default 0.0025
 */
uniform float u_ca;
/**
 * @label Light
 * @range 0.0, 1.0
 * @default 0.6
 */
uniform float u_light;
/**
 * @label Light angle (-1 left .. 1 right)
 * @range -1.0, 1.0
 * @default -0.35
 */
uniform float u_angle;
/**
 * @label Milk (glass body)
 * @range 0.0, 0.4
 * @default 0.07
 */
uniform float u_milk;
/**
 * @label Clear (scroll state, 1 = clear)
 * @range 0.0, 1.0
 * @default 0.0
 */
uniform float u_clear;
/**
 * @label Grain
 * @range 0.0, 0.1
 * @default 0.02
 */
uniform float u_grain;
/**
 * @label Tint
 * @color
 * @default #EAF6FF
 */
uniform vec3 u_tint;

float hash(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }

vec2 mirror(vec2 v) { v = abs(v); v = 1.0 - abs(1.0 - v); return clamp(v, 0.001, 0.999); }
vec3 tap(vec2 uv) { return texture2D(u_backdrop, mirror(uv)).rgb; }

void main() {
  vec2 frag = gl_FragCoord.xy;
  vec2 uv = frag / u_resolution;
  float k = 1.0 - u_clear;

  float rib = u_resolution.x / u_ribs;
  float cell = floor(frag.x / rib);
  float p = fract(frag.x / rib);
  float s = p * 2.0 - 1.0;
  float h = sqrt(max(1.0 - s * s, 0.0));

  float cx = (cell + 0.5) * rib;
  float lensX = cx + s * rib * 0.5 * u_lens;
  float sx = mix(frag.x, lensX, k) / u_resolution.x;

  float ca = u_ca * s * k;
  vec3 acc = vec3(0.0);
  float wsum = 0.0;
  for (int i = -4; i <= 4; i++) {
    float fi = float(i);
    float wt = exp(-fi * fi / 8.0);
    float oy = fi * u_frost * 0.25 * k;
    float ox = fi * 0.0008 * k;
    vec3 c;
    c.r = tap(vec2(sx + ox + ca, uv.y + oy)).r;
    c.g = tap(vec2(sx + ox, uv.y + oy)).g;
    c.b = tap(vec2(sx + ox - ca, uv.y + oy)).b;
    acc += c * wt;
    wsum += wt;
  }
  vec3 col = acc / wsum;

  float ang = u_angle;
  if (u_mouse.x + u_mouse.y > 0.001) {
    ang = clamp((u_mouse.x / u_resolution.x) * 2.0 - 1.0, -1.0, 1.0) * 0.8;
  }
  vec2 n = normalize(vec2(s, h));
  vec2 L = normalize(vec2(ang, 1.0));
  float diff = dot(n, L);
  col *= mix(1.0, 0.80 + 0.30 * smoothstep(-0.2, 1.0, diff), u_light * k);

  float spec = pow(max(dot(n, L), 0.0), 10.0);
  col += spec * 0.16 * u_light * k;

  float rim = pow(1.0 - h, 4.0);
  col += rim * 0.05 * u_light * k;

  float groove = smoothstep(0.0, 0.02, p) * smoothstep(1.0, 0.985, p);
  col *= mix(1.0, mix(0.84, 1.0, groove), k * u_light);
  float lip = exp(-pow((p - 0.03) / 0.012, 2.0));
  col += lip * 0.07 * u_light * k;

  float sheen = smoothstep(0.35, 0.0, abs(uv.x - uv.y * 0.6 - 0.25 - ang * 0.2));
  col += sheen * 0.05 * u_light * k;

  col = mix(col, col * u_tint + (u_tint - 0.5) * 0.04, k);
  col = mix(col, vec3(1.0), u_milk * k);

  col += (hash(frag) - 0.5) * u_grain * k;
  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
