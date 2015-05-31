precision highp float;

void main(void)
{
        vec2 uv=gl_FragCoord.xy / resolution.xy;
        uv=abs(2.0*(uv-0.5));

        float scaledResolution = 0.33;

        vec4 t1 = texture2D(audioTexture, vec2(uv[0] * scaledResolution,0.1) );
        vec4 t2 = texture2D(audioTexture, vec2(uv[1] * scaledResolution,0.1) );
        float fft = t1[0]*t2[0]*0.6;
        gl_FragColor = applyHueShift(vec4( sin(fft*3.141*2.5), sin(fft*3.141*2.0),sin(fft*3.141*1.0),1.0));
}
