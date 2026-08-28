#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform vec2 u_offset;
uniform vec4 u_cornerRadii;
uniform float u_refractionHeight;
uniform float u_refractionAmount;
uniform float u_depthEffect;
uniform float u_chromaticAberration;

uniform sampler2D u_texture_input;

out vec4 frag_color;

float radiusAt(vec2 coord, vec4 radii) {
  if (coord.x >= 0.0) {
    if (coord.y <= 0.0) {
      return radii.y;
    } else {
      return radii.z;
    }
  } else {
    if (coord.y <= 0.0) {
      return radii.x;
    } else {
      return radii.w;
    }
  }
}

float sdRoundedRect(vec2 coord, vec2 halfSize, float radius) {
  vec2 cornerCoord = abs(coord) - (halfSize - vec2(radius));
  float outside = length(max(cornerCoord, 0.0)) - radius;
  float inside = min(max(cornerCoord.x, cornerCoord.y), 0.0);
  return outside + inside;
}

vec2 gradSdRoundedRect(vec2 coord, vec2 halfSize, float radius) {
  vec2 cornerCoord = abs(coord) - (halfSize - vec2(radius));
  if (cornerCoord.x >= 0.0 || cornerCoord.y >= 0.0) {
    return sign(coord) * normalize(max(cornerCoord, 0.0));
  } else {
    float gradX = step(cornerCoord.y, cornerCoord.x);
    return sign(coord) * vec2(gradX, 1.0 - gradX);
  }
}

float circleMap(float x) {
  return 1.0 - sqrt(1.0 - x * x);
}

vec2 toUv(vec2 coord) {
  vec2 uv = coord / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return uv;
}

vec4 sampleContent(vec2 coord) {
  return texture(u_texture_input, toUv(coord));
}

void main() {
  vec2 coord = FlutterFragCoord().xy;
  vec2 halfSize = u_size * 0.5;
  vec2 centeredCoord = (coord + u_offset) - halfSize;
  float radius = radiusAt(coord, u_cornerRadii);

  float sd = sdRoundedRect(centeredCoord, halfSize, radius);
  if (-sd >= u_refractionHeight) {
    frag_color = sampleContent(coord);
    return;
  }
  sd = min(sd, 0.0);

  float d = circleMap(1.0 - -sd / u_refractionHeight) * u_refractionAmount;
  float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y));
  vec2 grad = gradSdRoundedRect(centeredCoord, halfSize, gradRadius) +
      u_depthEffect * normalize(centeredCoord + vec2(0.0001));
  float gradLength = max(length(grad), 0.0001);
  grad /= gradLength;

  vec2 refractedCoord = coord + d * grad;
  float dispersionIntensity =
      u_chromaticAberration * ((centeredCoord.x * centeredCoord.y) / (halfSize.x * halfSize.y));
  vec2 dispersedCoord = d * grad * dispersionIntensity;

  vec4 color = vec4(0.0);

  vec4 red = sampleContent(refractedCoord + dispersedCoord);
  color.r += red.r / 3.5;
  color.a += red.a / 7.0;

  vec4 orange = sampleContent(refractedCoord + dispersedCoord * (2.0 / 3.0));
  color.r += orange.r / 3.5;
  color.g += orange.g / 7.0;
  color.a += orange.a / 7.0;

  vec4 yellow = sampleContent(refractedCoord + dispersedCoord * (1.0 / 3.0));
  color.r += yellow.r / 3.5;
  color.g += yellow.g / 3.5;
  color.a += yellow.a / 7.0;

  vec4 green = sampleContent(refractedCoord);
  color.g += green.g / 3.5;
  color.a += green.a / 7.0;

  vec4 cyan = sampleContent(refractedCoord - dispersedCoord * (1.0 / 3.0));
  color.g += cyan.g / 3.5;
  color.b += cyan.b / 3.0;
  color.a += cyan.a / 7.0;

  vec4 blue = sampleContent(refractedCoord - dispersedCoord * (2.0 / 3.0));
  color.b += blue.b / 3.0;
  color.a += blue.a / 7.0;

  vec4 purple = sampleContent(refractedCoord - dispersedCoord);
  color.r += purple.r / 7.0;
  color.b += purple.b / 3.0;
  color.a += purple.a / 7.0;

  frag_color = color;
}
