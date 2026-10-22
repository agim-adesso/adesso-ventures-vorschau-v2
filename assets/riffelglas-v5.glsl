precision mediump float;

/** @resolution */
uniform vec2 u_resolution;
/** @backdrop */
uniform sampler2D u_backdrop;

/**
 * @label Rib Width (px)
 * @range 12.0, 120.0
 * @default 40.0
 */
uniform float u_rib;
/**
 * @label Lens (−1 = mirrored, 1 = flat)
 * @range -1.5, 1.0
 * @default -0.45
 */
uniform float u_mag;
/**
 * @label Frost (px)
 * @range 0.0, 24.0
 * @default 12.0
 */
uniform float u_frost;
/**
 * @label Light
 * @range 0.0, 1.5
 * @default 0.8
 */
uniform float u_light;
/**
 * @label Milk (glass body)
 * @range 0.0, 0.4
 * @default 0.07
 */
uniform float u_milk;
/**
 * @label Chromatic Edge
 * @range 0.0, 3.0
 * @default 1.0
 */
uniform float u_aberr;
/**
 * @label Clear (scroll/hover, 1 = clear)
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

float hash(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }

vec3 tap(vec2 px){ return texture2D(u_backdrop, clamp(px / u_resolution, vec2(0.001), vec2(0.999))).rgb; }

void main() {
  float k = 1.0 - u_clear;
  vec2 px = gl_FragCoord.xy;
  float rib = u_rib;
  float xw = px.x + sin(px.y * 0.0035 + floor(px.x / rib) * 1.7) * 0.8 * k;
  float cell = floor(xw / rib);
  float cx = (cell + 0.5) * rib;
  float lx = (xw - cx) / (rib * 0.5);
  float h = sqrt(max(1.0 - lx * lx, 0.0));

  float mag = mix(1.0, u_mag, k);
  float sx = cx + (px.x - cx) * mag - lx * (1.0 - h) * rib * 0.35 * k;

  vec3 acc = vec3(0.0);
  float fr = u_frost * k;
  for (int i = -3; i <= 3; i++) {
    for (int j = -1; j <= 1; j++) {
      vec2 o = vec2(float(i) * fr * 0.5, float(j) * fr * 0.35);
      acc += tap(vec2(sx, px.y) + o);
    }
  }
  acc /= 21.0;

  float ab = u_aberr * k * lx * 2.0;
  vec3 col = acc;
  col.r = mix(acc.r, tap(vec2(sx + ab, px.y)).r, 0.5);
  col.b = mix(acc.b, tap(vec2(sx - ab, px.y)).b, 0.5);

  // v5: Licht fest von links oben, keine Maus-Reaktion mehr (Hover entfernt)
  float lightX = -0.42;
  float near = 1.0;

  float spec = pow(max(0.0, 1.0 - abs(lx - lightX) / 0.34), 2.0) * 0.16 * near;
  float hot = pow(max(0.0, 1.0 - abs(lx - lightX - 0.06) / 0.07), 2.0) * 0.10 * near;
  float body = -lx * sign(lightX + 0.0001) * -0.075;
  float groove = smoothstep(0.90, 1.0, abs(lx));
  float rim = smoothstep(0.70, 0.88, -lx * sign(lightX + 0.0001)) * (1.0 - smoothstep(0.88, 0.96, -lx * sign(lightX + 0.0001)));
  float fres = pow(abs(lx), 4.0);

  col = mix(col, vec3(1.0), u_milk * k * (0.55 + 0.45 * h));
  col += (spec + hot + body) * u_light * k;
  col *= 1.0 - (groove * 0.28 + fres * 0.10) * u_light * k;
  col += rim * 0.06 * u_light * k;
  col += (hash(px) - 0.5) * u_grain * k;

  gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
