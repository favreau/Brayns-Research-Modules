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

#include <common/ispc/renderer/AbstractRenderer.ih>
#include <ospray/SDK/common/Ray.ih>

struct FractalsRenderer
{
    Renderer super;

    // Rendering attributes
    const uniform Light* uniform* uniform lights;
    uint32 numLights;
    vec3f bgColor;
    float shadows;
    float softShadows;
    int randomNumber;
    float timestamp;
    int spp;

    // Fractals
    uint32 maxIterations;
    bool julia;
    float threshold;
    float re;
    float im;

    // Transfer function attributes
    const uniform TransferFunction* uniform transferFunction;
    uint32 samplesPerRay;
};

export void FractalsRenderer_setTransferFunction(void* uniform _self,
                                                 void* uniform value)
{
    uniform FractalsRenderer* uniform self =
        (uniform FractalsRenderer * uniform) _self;
    self->transferFunction = (TransferFunction * uniform) value;
}

inline uint8 getMandelBulbContribution(
    const uniform FractalsRenderer* uniform self, const vec3f& point,
    const unsigned int iterations)
{
    const float power = 8.f;
    const vec3f P = 6.f * point - make_vec3f(0.125f);
    vec3f w = P;
    float m = dot(w, w);

    vec4f trap = make_vec4f(abs(w), m);
    float dz = 1.f;

    int i = 0;
    for (i = 0; i < 4; i++)
    {
        dz = power * pow(sqrt(m), 7.f) * dz + 1.f;

        float r = length(w);
        float b = power * acos(w.y / r);
        float a = power * atan2(w.x, w.z);
        w = P + pow(r, power) *
                    make_vec3f(sin(b) * sin(a), cos(b), sin(b) * cos(a));

        trap = min(trap, make_vec4f(abs(w), m));

        m = dot(w, w);
        if (m > 256.f)
            break;
    }

    const float value = clamp(512.f * log(m) * sqrt(m) / dz, 0.f, 255.f);
    return (uint8)(value);
}

inline varying uint8
    getJuliaContribution(const uniform FractalsRenderer* uniform self,
                         const vec3f& point, const unsigned int iterations)
{
    const float cRe = self->re;                 // -0.7f
    const float cIm = 3.f * point.z + self->im; // 0.27015f

    float newRe = 1.5f * point.x / 0.5f;
    float newIm = point.y / 0.5f;

    uint8 n = 0;
    for (n = 0;
         n < max(self->maxIterations, min(self->maxIterations, iterations));
         ++n)
    {
        float oldRe = newRe;
        float oldIm = newIm;
        newRe = oldRe * oldRe - oldIm * oldIm + cRe;
        newIm = 2.f * oldRe * oldIm + cIm;
        if ((newRe * newRe + newIm * newIm) > 4.f)
            break;
    }
    return n;
}

inline varying vec4f getVoxelColor(const uniform FractalsRenderer* uniform self,
                                   const vec3f& point,
                                   const unsigned int iterations)
{
    const uint8 voxelValue =
        self->julia ? getJuliaContribution(self, point, iterations)
                    : getMandelBulbContribution(self, point, iterations);
#if 0
    const uniform TransferFunction* uniform tf = self->transferFunction;
    if (tf)
        return make_vec4f(tf->getColorForValue(tf, voxelValue),
                          tf->getOpacityForValue(tf, voxelValue));
    else
        return make_vec4f(1.f, 0.f, 0.f, 1.f);
#else
    float v = (float)voxelValue / (float)self->maxIterations;
    if (v > self->threshold)
        return make_vec4f(1.f, v, 1.f - v, v);
    else
        return make_vec4f(0.f);

#endif
}

inline float getShadowContribution(const uniform FractalsRenderer* uniform self,
                                   varying ScreenSample& sample,
                                   const vec3f point, const float epsilon)
{
#if 0
    Volume* uniform volume = self->super.model->volumes[0];
    if (!volume)
        return 0.f;
#endif

    float pathOpacity = 0.f;
    for (uniform int i = 0;
         pathOpacity < 1.f && self->lights && i < self->numLights; ++i)
    {
        const uniform Light* uniform light = self->lights[i];
        const varying vec2f s = make_vec2f(0.5f);
        DifferentialGeometry dg;
        dg.P = point;
        const varying Light_SampleRes lightSample = light->sample(light, dg, s);

        Ray ray;
        ray.dir = neg(lightSample.dir);
        ray.org = point;
        float t0, t1;
#if 0
        const vec3f aabbmin = make_vec3f(-0.5f);
        const vec3f aabbmax = make_vec3f(0.5f);
        intersectBox(ray, volume->boundingBox, t0, t1);
        if (t0 == t1)
            continue;
#else
        t0 = 0.f;
        t1 = 1.f;
#endif

        for (float t = t0; pathOpacity < 1.f && t < t1; t += epsilon)
        {
            const vec3f p = ray.org + t * ray.dir;
            const vec4f voxelColor =
                getVoxelColor(self, p, self->maxIterations);
            pathOpacity += voxelColor.w;
        }
    }
    return pathOpacity;
}

inline vec3f FractalsRenderer_shadeRay(
    const uniform FractalsRenderer* uniform self, varying ScreenSample& sample)
{
    vec4f pathColor = make_vec4f(0.f);
    float pathOpacity = 0.f;

    float t0, t1;
#if 0
    Volume* uniform volume = self->super.model->volumes[0];
    if (!volume)
        return make_vec3f(1.f, 0.f, 0.f);

    intersectBox(sample.ray, volume->boundingBox, t0, t1);
    if (t0 == t1)
        return make_vec3f(self->bgColor);

    t0 = max(0.f, t0);
    t0 -= getRandomValue(sample, self->randomNumber) * ((t1 - t0) * 0.01f);
#else
    t0 = 0.f;
    t1 = 1.f;
#endif

    const float epsilon = max(0.001f, 1.f / (float)(self->samplesPerRay));

    bool shadowDone = false;

    for (float t = t0; pathOpacity < 1.f && t < t1; t += epsilon)
    {
        const vec3f point = (sample.ray.org + t * sample.ray.dir) - 0.5f;
        vec4f voxelColor = getVoxelColor(self, point, self->maxIterations);

        pathOpacity += voxelColor.w;

        // Shadow
        if (!shadowDone && voxelColor.w > 0.99f)
        {
            const float shadowContribution =
                getShadowContribution(self, sample, point, epsilon);
            voxelColor.x *= 1.f - shadowContribution;
            voxelColor.y *= 1.f - shadowContribution;
            voxelColor.z *= 1.f - shadowContribution;
            shadowDone = true;
        }

        composite(voxelColor, pathColor, 1.f);
    }

    // Combine with background color
    const vec4f bgColor = make_vec4f(self->bgColor, 1.f);
    composite(bgColor, pathColor, 1.f);

    sample.alpha = pathOpacity;
    sample.z = t0;

    return make_vec3f(pathColor);
}

void FractalsRenderer_renderSample(uniform Renderer* uniform _self,
                                   void* uniform perFrameData,
                                   varying ScreenSample& sample)
{
    uniform FractalsRenderer* uniform self =
        (uniform FractalsRenderer * uniform) _self;
    sample.ray.time = self->timestamp;
    sample.rgb = FractalsRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform FractalsRenderer_create(void* uniform cppE)
{
    uniform FractalsRenderer* uniform self =
        uniform new uniform FractalsRenderer;
    Renderer_Constructor(&self->super, cppE);
    self->super.renderSample = FractalsRenderer_renderSample;
    return self;
}

export void FractalsRenderer_set(
    void* uniform _self, const uniform vec3f& bgColor,
    const uniform float& shadows, const uniform float& softShadows,
    const uniform int& randomNumber, const uniform float& timestamp,
    const uniform int& spp, void** uniform lights,
    const uniform int32 numLights, const uniform int32& samplesPerRay,
    const uniform int32& maxIterations, const uniform bool& julia,
    const uniform float& threshold, const uniform float& re,
    const uniform float& im)
{
    uniform FractalsRenderer* uniform self =
        (uniform FractalsRenderer * uniform) _self;

    self->bgColor = bgColor;
    self->shadows = shadows;
    self->softShadows = softShadows;
    self->randomNumber = randomNumber;
    self->timestamp = timestamp;
    self->spp = spp;

    self->lights = (const uniform Light* uniform* uniform)lights;
    self->numLights = numLights;

    self->samplesPerRay = samplesPerRay;
    self->maxIterations = maxIterations;
    self->julia = julia;
    self->threshold = threshold;
    self->re = re;
    self->im = im;
}
