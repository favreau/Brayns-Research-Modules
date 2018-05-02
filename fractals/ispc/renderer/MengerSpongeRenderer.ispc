/* Copyright (c) 2018, Cyrille Favreau
 * Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
 *
 * This file is part of the reseach Brayns module
 * <https://github.com/favreau/Brayns-Research-Modules>
 *
 * This code a translation from:
 * https://www.shadertoy.com/view/4sX3Rn
 *
 * The MIT License
 * Copyright © 2013 Inigo Quilez
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions: The above copyright
 * notice and this permission notice shall be included in all copies or
 * substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS",
 * WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
 * FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <common/ispc/renderer/Glsl.ih>
#include <ospray/SDK/lights/Light.ih>
#include <ospray/SDK/render/Renderer.ih>

struct MengerSpongeRenderer
{
    Renderer super;

    // Rendering attributes
    const uniform Light* uniform* uniform lights;
    uint32 numLights;
    vec3f bgColor;
    float shadows;
    bool shadingEnabled;
    float softShadows;
    float timer;
    int spp;

    // Menger params
    LinearSpace3f ma;
    uint32 samplesPerRay;
};

const float FAR_PLANE = 100.f;
const int MAP_NB_ITERATION = 0;

inline float maxcomp(const vec3f& p)
{
    return max(p.x, max(p.y, p.z));
}

// -----------------------------------------------------------------------------
// Shapes
// -----------------------------------------------------------------------------

inline float sdCappedCone(const vec3f& p, const vec3f& c)
{
    vec3f q = make_vec3f(length(make_vec3f(p.x, p.z, 0.f)), p.y, 0.f);
    vec3f v = make_vec3f(c.z * c.y / c.x, -c.z, 0.f);
    vec3f w = v - q;
    vec3f vv = make_vec3f(dot(v, v), v.x * v.x, 0.f);
    vec3f qv = make_vec3f(dot(v, w), v.x * w.x, 0.f);
    vec3f d = max(qv, make_vec3f(0.f)) * qv / vv;
    return sqrt(dot(w, w) - max(d.x, d.y)) *
           sign(max(q.y * v.x - q.x * v.y, w.y));
}

inline float sdTorus(const vec3f& p, const vec3f& t)
{
    vec3f q = make_vec3f(length(make_vec3f(p.x, p.z, 0.f)) - t.x, p.y, 0.f);
    return length(q) - t.y;
}

inline float sdBox(const vec3f& p, const vec3f& b)
{
    const vec3f di = abs(p) - b;
    const float mc = maxcomp(di);
    return min(mc, length(max(di, make_vec3f(0.f))));
}

inline float sdSphere(const vec3f& p, const vec3f& s)
{
    return length(p) - s.x;
}

inline float sdCapsule(const vec3f& p, const vec3f& a, const vec3f& b, float r)
{
    const vec3f pa = p - a, ba = b - a;
    const float h = clamp(dot(pa, ba) / dot(ba, ba), 0.f, 1.f);
    return length(pa - ba * h) - r;
}

inline float sdEquilateralTriangle(const vec2f& p)
{
    vec3f point = make_vec3f(p.x, p.y, 0.f);
    const float k = 1.73205f;
    point.x = abs(point.x) - 1.f;
    point.y = point.y + 1.f / k;
    if (point.x + k * point.y > 0.f)
        point = make_vec3f(point.x - k * point.y, -k * point.x - point.y, 0.f) /
                2.f;
    point.x += 2.0 - 2.0 * clamp((point.x + 2.0) / 2.0, 0.0, 1.0);
    return -length(point) * sign(point.y);
}

inline float sdTriPrism(const vec3f& p, const vec2f& h)
{
    vec3f q = abs(p);
    const float d1 = q.z - h.y;
    const float d2 = max(q.x * 0.866025f + p.y * 0.5f, -p.y) - h.x * 0.5f;
    return length(max(make_vec3f(d1, d2, 0.f), make_vec3f(0.f))) +
           min(max(d1, d2), 0.f);
}

inline float sdCylinder(const vec3f& p, const vec3f& h)
{
    const vec3f a = make_vec3f(p.x, p.z, 0.f);
    const vec3f b = make_vec3f(length(a), p.y, 0.f);
    const vec3f c = b - make_vec3f(h.x, h.y, 0.f);
    const vec3f d = abs(max(c, make_vec3f(0.f)));
    return min(max(d.x, d.y), 0.f) + length(d);
}

inline float udRoundBox(const vec3f& p, const vec3f& b, float r)
{
    return length(max(abs(p) - b, make_vec3f(0.f))) - r;
}

inline float sdEllipsoid(const vec3f& p, const vec3f& r)
{
    return (length(p / r) - 1.f) * min(min(r.x, r.y), r.z);
}

inline float length8(const vec2f& v)
{
    vec2f p = v;
    p = p * p;
    p = p * p;
    p = p * p;
    return pow(p.x + p.y, 1.f / 8.f);
}

inline float sdTorus82(const vec3f& p, const vec2f& t)
{
    const vec2f q = make_vec2f(length(make_vec3f(p.x, p.z, 0.f)) - t.x, p.y);
    return length8(q) - t.y;
}

// -----------------------------------------------------------------------------
// Operations
// -----------------------------------------------------------------------------

inline float opS(const float d1, const float d2)
{
    return max(-d2, d1);
}

inline vec2f opU(const vec2f a, const vec2f b)
{
    return (a.x < b.x) ? a : b;
}

inline vec3f opRep(const vec3f& p, const vec3f& c)
{
    return mod(p, c) - 0.5f * c;
}

inline float smin(const float a, const float b, const float k)
{
    float res = exp(-k * a) + exp(-k * b);
    return -log(res) / k;
}

inline float opBlend(const float a, const float b)
{
    return smin(a, b, 5);
}

inline vec3f opTwist(const vec3f& p)
{
    const float c = cosf(p.y);
    const float s = sinf(p.y);
    const LinearSpace2f m =
        make_LinearSpace2f(make_vec2f(c, -s), make_vec2f(s, c));
    const vec2f a = m * make_vec2f(p.x, p.z);
    return make_vec3f(a.x, a.y, p.y);
}

inline float opDisplacement(const vec3f& p)
{
    return 0.1f * sin(5.f * p.x) * sin(5.f * p.y) * sin(5.f * p.z);
}

// -----------------------------------------------------------------------------
// Rendering
// -----------------------------------------------------------------------------

inline vec4f map(const uniform MengerSpongeRenderer* uniform self, vec3f& p)
{
    vec3f point = p - make_vec3f(0.5f);
    const vec3f radius = make_vec3f(0.05f, 0.1f, 0.1f);

    const vec3f centers[10] = {{1, 0, 0},     {0, 1, 1},      {0.5, 0, 0},
                               {0, -0.5, 0},  {0, 0.5, 0.5},  {0, 1, 0},
                               {1, 1, 0},     {0, 0.5, -0.5}, {0, 0.5, 0},
                               {-0.5, 0.5, 0}};
    float d = sdSphere(point + centers[0], radius);
    for (int i = 1; i < 9; ++i)
    {
        vec3f a = centers[i];
        vec3f b = centers[i + 1];
        d = opBlend(d, sdCapsule(point, a, b, radius.x));
    }
    vec4f res = make_vec4f(d);

    float s = 1.f;
    float ani = 0.f;
    float off = 0.f;
    for (int m = 0; m < MAP_NB_ITERATION; m++)
    {
        if (m == 0)
        {
            ani = smoothstep(-0.2f, 0.2f, -cos(0.5f * self->timer));
            off = 1.5f * sin(0.01f * self->timer);
        }

        const vec3f ma = self->ma * (point + off);
        point = make_vec3f(mix(point.x, ma.x, ani), mix(point.y, ma.y, ani),
                           mix(point.z, ma.z, ani));

        const vec3f a = mod(point * s, 2.f) - 1.f;
        s *= 3.f;
        const vec3f r = abs(1.f - 3.f * abs(a));
        const float da = max(r.x, r.y);
        const float db = max(r.y, r.z);
        const float dc = max(r.z, r.x);
        const float c = (min(da, min(db, dc)) - 1.f) / s;

        if (c > d)
        {
            d = c;
            res = make_vec4f(d, min(res.y, 0.2f * da * db * dc),
                             (1.f + (float)m) / 4.f, 0.f);
        }
    }

    return res;
}

inline vec4f intersect(const uniform MengerSpongeRenderer* uniform self,
                       const vec3f& ro, const vec3f& rd)
{
    float t = 0.f;
    vec4f res = make_vec4f(-1.f);
    vec4f h = make_vec4f(1.f);
    for (int i = 0; i < self->samplesPerRay; ++i)
    {
        if (h.x < 0.0001f || t > FAR_PLANE)
            break;
        h = map(self, ro + rd * t);
        res = make_vec4f(t, h.y, h.z, h.w);
        t += h.x;
    }
    if (t > FAR_PLANE)
        res = make_vec4f(-1.f);
    return res;
}

inline float softshadow(const uniform MengerSpongeRenderer* uniform self,
                        const vec3f& ro, const vec3f& rd, float mint, float k)
{
    float res = 1.f;
    float t = mint;
    float h = 1.f;
    for (int i = 0; i < 32; i++)
    {
        const vec4f a = map(self, ro + rd * t);
        h = a.x;
        res = min(res, k * h / t);
        t += clamp(h, self->softShadows, 0.1f);
    }
    return clamp(res, 0.f, 1.f);
}

inline vec3f calcNormal(const uniform MengerSpongeRenderer* uniform self,
                        const vec3f& pos)
{
    vec3f eps = make_vec3f(0.001f, 0.f, 0.f);

    const vec4f x0 = map(self, pos + make_vec3f(eps.x, eps.y, eps.y));
    const vec4f x1 = map(self, pos - make_vec3f(eps.x, eps.y, eps.y));
    const vec4f y0 = map(self, pos + make_vec3f(eps.y, eps.x, eps.y));
    const vec4f y1 = map(self, pos - make_vec3f(eps.y, eps.x, eps.y));
    const vec4f z0 = map(self, pos + make_vec3f(eps.y, eps.y, eps.x));
    const vec4f z1 = map(self, pos - make_vec3f(eps.y, eps.y, eps.x));

    return normalize(make_vec3f(x0.x - x1.x, y0.x - y1.x, z0.x - z1.x));
}

inline vec3f render(const uniform MengerSpongeRenderer* uniform self,
                    const vec3f& ro, const vec3f& rd)
{
    // background color
    vec3f col =
        make_vec3f(mix(self->bgColor.x * 0.5f, 0.7f, 0.5f + 0.5f * rd.y),
                   mix(self->bgColor.y * 0.5f, 0.9f, 0.5f + 0.5f * rd.y),
                   mix(self->bgColor.z * 0.5f, 1.0f, 0.5f + 0.5f * rd.y));

    vec4f tmat = intersect(self, ro, rd);
    if (tmat.x > 0.f)
    {
        // Shading
        const uniform Light* uniform light = self->lights[0];
        const vec2f s = make_vec2f(0.5f);
        DifferentialGeometry dg;
        const Light_SampleRes lightSample = light->sample(light, dg, s);
        const vec3f radiance = lightSample.weight;
        const vec3f lightDirection = lightSample.dir;

        const vec3f pos = ro + tmat.x * rd;
        const vec3f normal = calcNormal(self, pos);

        const float occ = tmat.y;
        const float sha =
            self->shadows > 0.f
                ? softshadow(self, pos, lightDirection, 0.01f, 64.f)
                : 1.f;

        const float dif = max(0.1f + 0.9f * dot(normal, lightDirection), 0.f);
        const float sky = 0.5f + 0.5f * normal.y;
        const float bac =
            max(0.4f + 0.6f * dot(normal, neg(lightDirection)), 0.f);

        vec3f lin = make_vec3f(0.f);
        lin = lin + 1.f * dif * make_vec3f(1.1f, 0.85f, 0.6f) * sha;
        lin = lin + 0.5f * sky * make_vec3f(0.1f, 0.2f, 0.4f) * occ;
        lin = lin + 0.1f * bac * make_vec3f(1.f) * (0.5f + 0.5f * occ);
        lin = lin + 0.25f * occ * make_vec3f(0.15f, 0.17f, 0.2f);

        const vec3f matcol = make_vec3f(0.5f + 0.5f * cos(0.f + 2.f * tmat.z),
                                        0.5f + 0.5f * cos(1.f + 2.f * tmat.z),
                                        0.5f + 0.5f * cos(2.f + 2.f * tmat.z));
        col = matcol * lin;
    }

    const float e = 0.4545f;
    return make_vec3f(pow(col.x, e), pow(col.y, e), pow(col.z, e));
}

inline vec3f MengerSpongeRenderer_shadeRay(
    const uniform MengerSpongeRenderer* uniform self,
    varying ScreenSample& sample)
{
    sample.alpha = 1.f;
    sample.z = inf;

    return render(self, sample.ray.org, sample.ray.dir);
}

void MengerSpongeRenderer_renderSample(uniform Renderer* uniform _self,
                                       void* uniform perFrameData,
                                       varying ScreenSample& sample)
{
    uniform MengerSpongeRenderer* uniform self =
        (uniform MengerSpongeRenderer * uniform)_self;
    sample.rgb = MengerSpongeRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform MengerSpongeRenderer_create(void* uniform cppE)
{
    uniform MengerSpongeRenderer* uniform self =
        uniform new uniform MengerSpongeRenderer;
    Renderer_Constructor(&self->super, cppE);
    self->super.renderSample = MengerSpongeRenderer_renderSample;
    return self;
}

export void MengerSpongeRenderer_set(
    void* uniform _self, const uniform vec3f& bgColor,
    const uniform float& shadows, const uniform float& softShadows,
    const uniform int& spp, void** uniform lights,
    const uniform int32 numLights, const uniform int32& samplesPerRay,
    const uniform float& timestamp)
{
    uniform MengerSpongeRenderer* uniform self =
        (uniform MengerSpongeRenderer * uniform)_self;

    self->bgColor = bgColor;
    self->shadows = shadows;
    self->softShadows = softShadows;
    self->spp = spp;
    self->lights = (const uniform Light* uniform* uniform)lights;
    self->numLights = numLights;
    self->samplesPerRay = samplesPerRay;
    self->timer = timestamp;

    self->ma = make_LinearSpace3f(make_vec3f(0.6f, 0.f, 0.8f),
                                  make_vec3f(0.f, 1.f, 0.f),
                                  make_vec3f(-0.8f, 0.f, 0.6f));
}
