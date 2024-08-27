extern int amount;
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pixel_coords){
    vec2 size = vec2(love_ScreenSize.x, love_ScreenSize.y);
    vec2 coords = (floor(tc * size / vec2(amount,amount)) + vec2(0.5,0.5)) * vec2(amount,amount) / size;
    vec4 col = Texel(texture, coords);

    return col;
}