varying vec3 vColor;

void main() {
  float power = 1.2;
  float r = eqs.r * 128.0 / pow(length(position - eq1), power);
  float g = eqs.g * 128.0 / pow(length(position - eq2), power);
  float b = eqs.b * 128.0 / pow(length(position - eq3), power);
  vColor = vec3(r, g, b);
  gl_PointSize = 1.0;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}
