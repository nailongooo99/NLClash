#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform vec4 u_cornerRadii;
uniform vec4 u_color;
uniform float u_angle;
uniform float u_falloff;
uniform float u_ambient;
uniform float u_alpha;

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

vec2 gradSdRoundedRect(vec2 coord, vec2 halfSize, float radius) {
  vec2 cornerCoord = abs(coord) - (halfSize - vec2(radius));
  if (cornerCoord.x >= 0.0 || cornerCoord.y >= 0.0) {
    return sign(coord) * normalize(max(cornerCoord, 0.0));
  } else {
    float gradX = step(cornerCoord.y, cornerCoord.x);
    return sign(coord) * vec2(gradX, 1.0 - gradX);
  }
}

void main() {
  vec2 coord = FlutterFragCoord().xy;
  vec2 halfSize = u_size * 0.5;
  vec2 centeredCoord = coord - halfSize;
  float radius = radiusAt(coord, u_cornerRadii);
  float gradRadius = min(radius * 1.5, min(halfSize.x, halfSize.y));
  vec2 grad = gradSdRoundedRect(centeredCoord, halfSize, gradRadius);
  vec2 normal = vec2(cos(u_angle), sin(u_angle));
  float d = dot(grad, normal);
  float intensity = pow(abs(d), u_falloff);
  if (u_ambient > 0.5) {
    float t = step(0.0, d);
    frag_color = vec4(t, t, t, 1.0) * intensity * u_alpha;
  } else {
    frag_color = u_color * intensity * u_alpha;
  }
}
