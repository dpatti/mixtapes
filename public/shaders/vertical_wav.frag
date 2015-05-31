precision highp float;

void main(void)
{
	vec2 uv = gl_FragCoord.xy / resolution.xy;

  float wav = texture2D(audioTexture, vec2(uv.y, 0.5)).y;
  wav = wav * 0.2;

  float wavl = cos(3.1415*5.0*abs(uv.x-wav));
  float cl = clamp((wavl - 0.5) * 5.0, 0.0, 1.0);

  float coord1 = sin(cl + uv.x) - cos(uv.y);
  float coord2 = cos(uv.y) - sin(uv.y + cl);

  float mixed = mix(coord1, coord2, 0.5 + 0.5 * sin(time));

  float mw = texture2D(audioTexture, clamp(vec2(abs(mixed), 0.5), 0.0, 0.7)).x;

	vec3 sun = vec3(-0.5, 0.96, 0.99);

  float beat = texture2D(audioTexture, vec2(0.3, 0.25)).x;
  sun.x = -0.8 + beat * 0.3;
  sun.y = 0.7 + cos(uv.y * 6.0 + uv.y * 0.3)*0.1 + sin(time * 0.1);
  sun.z = 0.8 + 0.3*sin(time);

  float colorizer = mw;
  float fac1 = dot(vec3(uv.x, uv.y, colorizer), sun);
  float fac2 = dot(vec3(uv.x, colorizer, uv.y), sun);
  float fac3 = dot(vec3(colorizer, uv.x, uv.y), sun);

  vec3 bcolor = vec3(fac1, fac2, fac3);

  gl_FragColor = vec4(bcolor, 1.0);
}
