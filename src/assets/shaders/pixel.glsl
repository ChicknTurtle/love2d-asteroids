extern float amount;
extern vec2 size;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pixel_coords) {
    vec2 pixelSize = vec2(amount / 1000.0);

    if (size.x > size.y) {
        pixelSize.x *= (size.y / size.x);
    } else {
        pixelSize.y *= (size.x / size.y);
    }

    vec2 coords = vec2(floor(tc.x / pixelSize.x) * pixelSize.x,
                       floor(tc.y / pixelSize.y) * pixelSize.y);

    vec4 col = Texel(texture, coords);
    return col;
}
