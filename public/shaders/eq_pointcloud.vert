varying vec3 vColor;

void main() {
  float r = eqs.r * 32.0 / length(position - eq1);
  float g = eqs.g * 32.0 / length(position - eq2);
  float b = eqs.b * 32.0 / length(position - eq3);
  vColor = vec3(r, g, b);
  gl_PointSize = 1.0;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
