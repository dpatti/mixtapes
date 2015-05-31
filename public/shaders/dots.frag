float iDot(float section, vec2 uv) {

  float l = 0.0;
  float sectionWidth = 128.0;
  float validArea = section * 4.0;

  for(float i=0.0;i < 128.0;i++) {
    float absI = i + section * sectionWidth;
    float val = texture2D(audioTexture, vec2(absI / 1024.0, 0.25)).r;
    l += val * val / (1.0 - ((1.0 - val) * absI / (sectionWidth * 4.0)));
  }

  vec2 cuv = vec2(accumulatedLoudness / (10.0 / (section * 0.5 + 1.0)) , cos(time + section * 0.75) / 3.0);
  vec2 center = toCartesian(cuv);
  float dist = length((center + vec2(0.5)) - uv);

  // if(dist > 0.5) return 0.0;

  l = l / sectionWidth;

  return smoothstep(l * 0.1, 0.0, dist);
}

void main() {
  vec2 scale = vec2(resolution.x/resolution.y, 1.0);
  vec2 uv = (gl_FragCoord.xy / resolution.xy) * scale - vec2((scale.x - 1.0)/2.0, 0.0);

  vec3 col = vec3(0.0);
  for(float i = 0.0; i < 4.0; i++) {
    vec3 color = hsv2rgb(vec3(i * 0.25, 1.0, 1.0));

    col += iDot(i, uv) * color ;
  }

  gl_FragColor = vec4(col, 1.0);
}
