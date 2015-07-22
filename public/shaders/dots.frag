float iDot(float section, vec2 uv) {

  float l = 0.0;
  if (section == 0.0) {
    l = eqSegments.x;
  }
  else if (section == 1.0) {
    l = eqSegments.y;
  }
  else if (section == 2.0) {
    l = eqSegments.z;
  }
  else if (section == 3.0){
    l = eqSegments.w;
  }
  else {
    l = 0.0;
  }

  vec2 cuv = vec2(accumulatedLoudness / (64.0 / (section * 0.5 + 1.0)) , cos(time + section * 0.75));
  vec2 center = toCartesian(cuv);
  float dist = length(center - uv);

  return smoothstep(l * 4.0, 0.0, dist * dist);
}

void main() {
  vec2 uv = ((2.0 * gl_FragCoord.xy) / resolution.xy - vec2(1.0)) * vec2(resolution.x/resolution.y, 1.0);

  vec3 col = vec3(0.0);
  for(float i = 0.0; i < 4.0; i++) {
    vec3 color = hsv2rgb(vec3(i * 0.25, 1.0, 1.0));

    col += iDot(i, uv) * color ;
  }

  gl_FragColor = vec4(col, 1.0);
}
