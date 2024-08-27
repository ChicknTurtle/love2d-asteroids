extern float time;

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pixel_coords) {
  // Generate a unique seed based on pixel coordinates
  float seed = fract(sin(dot(tc * love_ScreenSize.xy, vec2(12.9898, 78.233))) * 43758.5453);

  // Calculate brightness for twinkling effect
  float brightness = 0.5 + 0.5 * sin((time + seed) * 5.0);

  // Define a threshold for star visibility
  float threshold = 0.995; // Adjust this to control star density
  float star = step(threshold, seed) * brightness;

  // Return the color for the star or black for the background
  return vec4(vec3(star), 1.0);
}
