precision mediump float;

/** @resolution */
uniform vec2 u_resolution;
/** @time */
uniform float u_time;
/** @backdrop */
uniform sampler2D u_backdrop;

/**
 * @label Deep
 * @color
 * @default #0B4FA0
 */
uniform vec3 u_deep;
/**
 * @label Mid
 * @color
 * @default #1E8FE0
 */
uniform vec3 u_mid;
/**
 * @label Light
 * @color
 * @default #8FD8F5
 */
uniform vec3 u_light;
/**
 * @label Ribbon Width
 * @range 0.04, 0.3
 * @default 0.2
 */
uniform float u_width;
/**
 * @label Twist (turns)
 * @range 0.5, 4.0
 * @default 2.1
 */
uniform float u_twist;
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
/**
 * @label Motion Amount
 * @range 0.0, 2.0
 * @default 1.0
 */
uniform float u_amp;

vec4 strand(vec2 uv, float ph, float wScale, float tOff, float yOff) {
  float x = uv.x;
  float cy = 0.08 + yOff + 0.84 * smoothstep(-0.2, 1.2, x) + 0.06 * sin(x * 5.0 + 0.8 + ph * 0.7 + tOff * 0.5);
  float hw = u_width * wScale * (0.8 + 0.3 * sin(x * 3.0 + 1.1 + ph * 0.4 + tOff));
  float th = x * u_twist * 3.14159 + 0.9 + ph * 1.8 + tOff;
  float ct = cos(th);
  float facing = abs(ct);
  float proj = max(hw * facing, 1.2 / u_resolution.y);
  float s = (uv.y - cy) / proj;
  float aa = 1.2 / (u_resolution.y * proj);
  float inside = 1.0 - smoothstep(1.0 - aa, 1.0 + aa, abs(s));
  float side = ct >= 0.0 ? 1.0 : -1.0;
  float sheenPos = 0.35 * sin(th * 0.5 + 0.4);
  float sheen = exp(-pow((s * side - sheenPos) / 0.30, 2.0)) * pow(facing, 1.2);
  float rim = smoothstep(0.5, 1.0, abs(s));
  vec3 col = mix(u_deep, u_mid, 0.3 + 0.7 * facing);
  col = mix(col, u_light, sheen * 0.85);
  col += vec3(1.0) * pow(sheen, 8.0) * 0.5;
  col = mix(col, u_light, (1.0 - facing) * 0.5);
  col *= 1.0 - rim * 0.25;
  if (side < 0.0) col *= 0.84;
  return vec4(clamp(col, 0.0, 1.0), inside);
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;   // y nach oben: Band steigt von links unten nach rechts oben

  // Animation: spielt u_play Sekunden mit Ease-out, dann Stillstand (WCAG 2.2.2).
  // Preview wiederholt Spiel + Pause nur für die Canvas-Vorschau.
  float cyc = u_play + u_rest;
  float tt = u_preview > 0.5 ? mod(u_time, cyc) : u_time;
  float p = u_play > 0.0 ? clamp(tt / u_play, 0.0, 1.0) : 1.0;
  float e = 1.0 - pow(1.0 - p, 3.0);
  float ph = (e - 1.0) * u_amp * 1.6; // endet bei 0 = Ruhepose

  vec3 bg = texture2D(u_backdrop, uv).rgb;
  vec4 back = strand(uv, ph * 1.3, 0.55, 2.2, -0.035);   // zweite, schmalere Lage dahinter
  vec4 front = strand(uv, ph, 1.0, 0.0, 0.0);
  vec3 col = mix(bg, back.rgb, back.a * 0.75);
  col = mix(col, front.rgb, front.a);
  gl_FragColor = vec4(col, 1.0);
}
