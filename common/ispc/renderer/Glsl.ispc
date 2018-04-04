/* Copyright (c) 2018, Cyrille Favreau
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
 *
 * This file is part of the reseach Brayns module
 * <https://github.com/favreau/Brayns-Research-Modules>
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 3.0 as published
 * by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "Glsl.ih"

inline float mix(const float x, const float y, const float a)
{
    return x * (1.f - a) + y * a;
}

inline vec3f mod(const vec3f& v, const int m)
{
    return make_vec3f(v.x - m * floor(v.x / m), v.y - m * floor(v.y / m),
                      v.z - m * floor(v.z / m));
}

inline vec3f mod(const vec3f& v, const vec3f& u)
{
    return v - u * floor(v / u);
}

inline float smoothstep(const float edge0, const float edge1, float x)
{
    float t;
    t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

inline float sign(const float v)
{
    return v > 0 ? 1.f : v == 0.f ? 0.f : -1.f;
}

inline vec3f sign(const vec3f& v)
{
    return make_vec3f(sign(v.x), sign(v.y), sign(v.z));
}
