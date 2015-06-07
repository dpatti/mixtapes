vec4 fromPos(vec2 uv, vec3 te) {
    vec2 cuv = toPolar(uv, te.xy);

    // FFT
    float fft = texture2D(audioTexture, vec2(cuv.y * 0.33, 0.25)).x * getVolume();

    // Rotating colors
    float fftSin = (0.5 + 0.3 * sin(cuv.y * 64.0 * 3.1415 - accumulatedLoudness * 0.33)) * fft * fft * 0.6;
    fftSin = smoothstep(0.0, 1.0, fftSin) * 0.6;
    return vec4(sin(fftSin * 3.1415 * 2.5), sin(fftSin * 3.1415 * 2.0), sin(fftSin * 3.1415 * 1.0), 1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    vec4 color = vec4(fromPos(uv, vec3(0.5)).rbg, 1.0);

    gl_FragColor = applyHueShift(color);
}
