/* Copyright (c) 2018, Cyrille Favreau
This file is part of the reseach Brayns module
<https://github.com/favreau/Brayns-Research-Modules>

Translated from :

Copyright © 2013 Inigo Quilez
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: The above copyright notice and this
permission notice shall be included in all copies or substantial portions of the
Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
http://www.iquilezles.org/www/articles/menger/menger.htm
*/

#include <common/ispc/renderer/AbstractRenderer.ih>
#include <common/ispc/renderer/Glsl.ih>
#include <ospray/SDK/math/math.ih>

uniform float freqs[16];
uniform const float maxd = 8.0;

struct DistanceEstimatorRenderer
{
    AbstractRenderer abstract;

    // Transfer function / Color map attributes
    uniform vec4f* uniform colorMap;
    uniform vec3f* uniform emissionIntensitiesMap;
    uint32 colorMapSize;
    float colorMapMinValue;
    float colorMapRange;
    float threshold;

    // Volume dimension
    vec3f volumeDimensions;
    uint32 volumeSamplesPerRay;
};

inline float fbm(vec3f& p, const vec3f& n)
{
#if 1
    const float x = 0.5f;
    const float y = 0.5f;
    const float z = 0.5f;
#else
    p *= 0.15;
    const float x = texture(iChannel3, p.yz).x;
    const float y = texture(iChannel3, p.zx).x;
    const float z = texture(iChannel3, p.xy).x;
#endif
    return x * abs(n.x) + y * abs(n.y) + z * abs(n.z);
}

inline vec2f sdSegment(const vec3f& a, const vec3f& b, const vec3f& p)
{
    const vec3f pa = p - a;
    const vec3f ba = b - a;
    const float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return make_vec2f(length(pa - ba * h), h);
}

inline vec3f hash3(const float n)
{
    return frac(make_vec3f(sinf(n), sinf(n + 1.0), sinf(n + 2.0))) *
           make_vec3f(43758.5453123, 22578.1459123, 19642.3490423);
}

inline vec3f snoise3(const float x)
{
#if 1
    return make_vec3f(-1.0 + 2.0 * x);
#else
    return -1.0 + 2.0 * textureLod(iChannel2, vec2(x, 4.5) / 256.0, 0.0).xyz;
#endif
}

inline vec4f map(const uniform DistanceEstimatorRenderer* uniform self,
                 vec3f& pos)
{
    pos = pos + make_vec3f(0.04 * sin(10.0 * pos.y), 0.04 * sin(10.0 * pos.z),
                           0.04 * sin(10.0 * pos.x));

    vec3f qpos = mod(1000.0 + pos + 1.0, 2.0) - 1.0;
    const vec3f off3 = floor(1000.0 + (pos + 1.0) / 2.0);

    const a = 0.5 * 3.1415927;
    qpos = qpos *
           sign(make_vec3f(cosf(a * pos.y), cosf(a * pos.z), cosf(a * pos.x)));

    const float off = abs(dot(off3, make_vec3f(1.0, 13.0, 7.0)));
    float mindist = 10000.0;
    vec3f p = make_vec3f(0.0);
    float h = 0.0;
    float rad = 0.04 + 0.15 * freqs[0];
    float mint = 0.0;
    for (int i = 0; i < 16; i++)
    {
        vec3f op = p;
        p = 0.9 * normalize(snoise3(8.0 * h));

        const float orad = rad;
        rad = (0.04 + 0.15 * freqs[i]) * 1.5 * 1.1;

        vec2f disl = sdSegment(op, p, qpos);
        const float t = h + disl.y / 16.0;
        const float dis = disl.x - mix(orad, rad, disl.y);

        if (dis < mindist)
        {
            mindist = dis;
            mint = t;
        }
        h += (1.0 / 16.0);
    }

    float dsp = sin(50.0 * pos.x) * sin(50.0 * pos.y) * sin(50.0 * pos.z);
    dsp = dsp * dsp * dsp;
    mindist += -0.02 * dsp;
    mindist += 0.01 * sin(180.0 * mint + self->abstract.randomNumber);
    return make_vec4f(mindist, 1.0, dsp, mint);
}

inline vec3f calcNormal(const vec3f& pos)
{
    const vec3f eps = make_vec3f(0.05, 0.0, 0.0);
#if 1
    const vec3f nor = make_vec3f(0, 1, 0);
#else
    const vec3f nor = make_vec3f(map(pos + eps.xyy).x - map(pos - eps.xyy).x,
                                 map(pos + eps.yxy).x - map(pos - eps.yxy).x,
                                 map(pos + eps.yyx).x - map(pos - eps.yyx).x);
#endif
    return normalize(nor);
}

inline vec3f doBumpMap(const vec3f& pos, const vec3f& nor, float amount)
{
    const float e = 0.0015;
    const float b = 0.01;

    const float ref = fbm(48.0 * pos, nor);
    const vec3f gra =
        -b *
        make_vec3f(fbm(48.0 * make_vec3f(pos.x + e, pos.y, pos.z), nor) - ref,
                   fbm(48.0 * make_vec3f(pos.x, pos.y + e, pos.z), nor) - ref,
                   fbm(48.0 * make_vec3f(pos.x, pos.y, pos.z + e), nor) - ref) /
        e;

    const vec3f tgrad = gra - nor * dot(nor, gra);
    return normalize(nor - amount * tgrad);
}

inline float calcAO(const uniform DistanceEstimatorRenderer* uniform self,
                    const vec3f& pos, const vec3f& nor)
{
    float totao = 0.0;
    for (int aoi = 0; aoi < 5; aoi++)
    {
        vec3f aopos =
            0.1 * (nor + 0.7 * (-1.0 + 2.0 * hash3(143.13 * (float)aoi)));
        const vec4f m = map(self, pos + aopos);
        float dd = m.x;
        totao += clamp(5.0 * dd, 0.0, 1.0);
    }
    return pow(clamp(1.5 * totao / 5.0, 0.0, 1.0), 1.0);
}

inline float calcSSS(const uniform DistanceEstimatorRenderer* uniform self,
                     const vec3f& pos, const vec3f& nor)
{
    float ao = 1.0;
    float totao = 0.0;
    float sca = 1.0;
    for (int aoi = 0; aoi < 5; aoi++)
    {
        float hr = 0.01 + 0.4 * (float)aoi / 4.0;
        vec3f aopos = nor * hr + pos;
        const vec4f m = map(self, aopos);
        float dd = m.x;
        totao += (hr - min(dd, 0.0)) * sca;
        sca *= 0.9;
    }
    return pow(clamp(1.2 - 0.25 * totao, 0.0, 1.0), 16.0);
}

inline vec3f reflect(const vec3f& v, const vec3f& n)
{
    return v - 2.f * dot(v, n) * n;
}

inline vec4f castRay(const uniform DistanceEstimatorRenderer* uniform self,
                     const vec3f& ro, const vec3f& rd)
{
    const float precis = 0.001f;
    float h = 1.0;

    float t = 0.1;
    float sid = -1.0;
    float dsp = 0.0;
    float ttt = 0.0;
    for (int i = 0; i < 50; i++)
    {
        if (abs(h) < (precis * t) || t > maxd)
            break;
        t += min(h, 0.2);
        vec4f res = map(self, ro + rd * t);
        h = res.x;
        sid = res.y;
        dsp = res.z;
        ttt = res.w;
    }

    return make_vec4f(t, sid, dsp, ttt);
}

inline vec3f render(const uniform DistanceEstimatorRenderer* uniform self,
                    const vec3f& ro, const vec3f& rd)
{
    vec3f col = make_vec3f(0.0);

    vec4f res = castRay(self, ro, rd);
    float t = res.x;
    if (t < maxd)
    {
        vec3f pos = ro + t * rd;
        vec3f nor = calcNormal(pos);
        vec3f snor = nor;
        nor =
            doBumpMap(0.5 * pos, nor, 0.2 * clamp(1.0 - 1.0 * res.z, 0.0, 1.0));

        vec3f ref = reflect(rd, nor);
        vec3f sref = reflect(rd, snor);

        col = make_vec3f(1.0);
        float pao = calcAO(self, pos, nor);
        float ao = 0.4 + 0.6 * pao;
        ao *= 1.0 + 0.3 * max(res.z, 0.0);
        float ss = calcSSS(self, pos - nor * 0.01, rd);

        float kr = clamp(1.0 + dot(rd, nor), 0.0, 1.0);

        const b = kr * ss * ss;
        col = make_vec3f(mix(0.6, 1.4 * 1.0, b), mix(0.3, 1.4 * 0.8, b),
                         mix(0.1, 1.4 * 1.6, b));

        col = col * (0.7 + 0.3 * ss);

        const float a = 4.0 * 6.2831 * res.w;
        col = col +
              (0.1 * make_vec3f(cosf(a + 1.0), cosf(a + 0.5), cosf(a + 0.7)));
        col = col * (0.6 + 0.6 * fbm(pos, nor));
        col = col * ao;
#if 1
        col = col + (0.15 * (0.5 + 0.5 * kr));
#else
        col += 0.15 * (0.5 + 0.5 * kr) *
               pow(texture(iChannel1, normalize(sref + ref)).xyz, vec3(1.0));
#endif
        col = col * exp(-0.0125 * t * t * t);
    }

    return make_vec3f(col);
}

inline vec3f DistanceEstimatorRenderer_shadeRay(
    const uniform DistanceEstimatorRenderer* uniform self,
    varying ScreenSample& sample)
{
    for (int i = 0; i < 16; ++i)
#if 1
        freqs[i] = getRandomValue(sample, i);
#else
        freqs[i] =
            clamp(1.9 * pow(texture(iChannel0,
                                    vec2(0.02 + 0.5 * float(i) / 16.0, 0.25))
                                .x,
                            3.0),
                  0.0, 1.0);
#endif
    return render(self, sample.ray.org, sample.ray.dir);
}

void DistanceEstimatorRenderer_renderSample(uniform Renderer* uniform _self,
                                            void* uniform perFrameData,
                                            varying ScreenSample& sample)
{
    uniform DistanceEstimatorRenderer* uniform self =
        (uniform DistanceEstimatorRenderer * uniform)_self;
    sample.ray.time = self->abstract.timestamp;
    sample.rgb = DistanceEstimatorRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform DistanceEstimatorRenderer_create(void* uniform cppE)
{
    uniform DistanceEstimatorRenderer* uniform self =
        uniform new uniform DistanceEstimatorRenderer;
    Renderer_Constructor(&self->abstract.super, cppE);
    self->abstract.super.renderSample = DistanceEstimatorRenderer_renderSample;
    return self;
}

export void DistanceEstimatorRenderer_set(
    void* uniform _self, void* uniform bgMaterial, const uniform float& shadows,
    const uniform float& softShadows,
    const uniform float& ambientOcclusionStrength,
    const uniform float& ambientOcclusionDistance,
    const uniform bool& shadingEnabled, const uniform int& randomNumber,
    const uniform float& timestamp, const uniform int& spp,
    const uniform bool& electronShadingEnabled, void** uniform lights,
    const uniform int32 numLights, const uniform int32& volumeSamplesPerRay,
    uniform vec4f* uniform colormap,
    uniform vec3f* uniform emissionIntensitiesMap,
    const uniform int32 colorMapSize, const uniform float& colorMapMinValue,
    const uniform float& colorMapRange, const uniform float& threshold)
{
    uniform DistanceEstimatorRenderer* uniform self =
        (uniform DistanceEstimatorRenderer * uniform)_self;

    self->abstract.bgMaterial =
        (uniform ExtendedOBJMaterial * uniform)bgMaterial;

    self->abstract.shadows = shadows;
    self->abstract.softShadows = softShadows;
    self->abstract.ambientOcclusionStrength = ambientOcclusionStrength;
    self->abstract.ambientOcclusionDistance = ambientOcclusionDistance;
    self->abstract.shadingEnabled = shadingEnabled;
    self->abstract.randomNumber = randomNumber;
    self->abstract.timestamp = timestamp;
    self->abstract.spp = spp;
    self->abstract.electronShadingEnabled = electronShadingEnabled;

    self->abstract.lights = (const uniform Light* uniform* uniform)lights;
    self->abstract.numLights = numLights;

    self->colorMap = (uniform vec4f * uniform)colormap;
    self->emissionIntensitiesMap =
        (uniform vec3f * uniform)emissionIntensitiesMap;
    self->colorMapSize = colorMapSize;
    self->colorMapMinValue = colorMapMinValue;
    self->colorMapRange = colorMapRange;

    self->threshold = threshold;

    self->volumeSamplesPerRay = volumeSamplesPerRay;
    self->volumeDimensions = make_vec3f(1.f);
}
