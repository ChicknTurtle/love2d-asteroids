extern int amount;
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pixel_coords){
    vec2 coords = floor(tc * float(amount)) / float(amount);
    vec4 col = Texel(texture, coords);

    return Texel(texture, tc);
}