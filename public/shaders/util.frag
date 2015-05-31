vec2 toCartesian(vec2 p) {
  return vec2(p.y * cos(p.x), p.y * sin(p.x));
}

vec2 toPolar(vec2 p, vec2 origin) {
  vec2 cuv = p - origin;

  float ca = atan(cuv.x, cuv.y) + radians(90.0);
  float cr = length(cuv);

  return vec2(ca, cr);
}

vec2 toPolar(vec2 p) {
  return toPolar(p, vec2(0.5));
}

vec2 closestPoint(vec2 uv, float r) {
  vec2 C = vec2(0.5, 0.5);
  vec2 V = uv - C;

  vec2 closest = C + V * r/ length(V);

  return closest;
}

vec3 rgb2hsv(vec3 c) {
  vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
  vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
  vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
  vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 applyHueShift(vec4 color, float shift) {
  vec3 hsv = rgb2hsv(color.rgb);
  hsv.x = fract(hsv.x + shift);
  return vec4(hsv2rgb(hsv), color.w);
}

vec4 applyHueShift(vec4 color) {
  return applyHueShift(color, getHue());
}

vec3 baseHue(float time) {
  return hsv2rgb(vec3(fract(sin(time)), 1.0, 0.5));
}

vec3 baseHue(float time, float lightness) {
  return hsv2rgb(vec3(fract(sin(time)), 1.0, lightness));
}
