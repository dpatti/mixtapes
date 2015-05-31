#define TOUCH_EVENT_COUNT 10
precision highp float;
uniform vec3 te[TOUCH_EVENT_COUNT];
uniform vec3 colormod;

void main() {
  vec2 vUv = gl_FragCoord.xy / resolution.xy;
	float fft = texture2D(audioTexture, vec2(vUv.x, 0.25)).r;
  float visibility = ceil(fft - vUv.y);
  vec4 freq = vec4(visibility, visibility, visibility,1.0);

  for(int i=0;i<TOUCH_EVENT_COUNT;i++) {
    vec3 tec = te[i];

    if (tec.z == 0.0) {
      continue;
    }

    float distTouch = length(tec.xy - vUv);

    float c = 1.0 - (time - tec.z) / 2.0;
    if (distTouch < 0.1) {
      freq = max(freq, vec4(c, c, c, 1.0));
    }
  }

	gl_FragColor = freq;
}
