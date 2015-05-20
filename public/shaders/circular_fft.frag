vec4 fromPos(vec2 uv, vec3 te) {
    vec2 cuv = toPolar(uv, te.xy);

    // FFT
    float fft = texture2D(audioTexture, vec2(cuv.y, 0.25)).x * getVolume() * 0.75;

    // Rotating colors
    vec4 base = vec4(uv,0.5+0.5*sin(time),1.0);
    return base * (sin(cuv.y * 64.0 * 3.1415 + time ) * fft);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    vec4 color = vec4(fromPos(uv, vec3(0.5)).rbg, 1.0);

    gl_FragColor = color;
}
