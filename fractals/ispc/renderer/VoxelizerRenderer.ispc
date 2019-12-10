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

struct VoxelizerRenderer
{
    Renderer super;

    // Rendering attributes
    const uniform Light* uniform* uniform lights;
    uint32 numLights;
    const uniform ExtendedOBJMaterial* uniform* uniform materials;
    uint32 numMaterials;
    vec3f bgColor;
    float shadows;
    bool shadingEnabled;
    float softShadows;
    int randomNumber;
    float timestamp;
    int spp;

    float pixelOpacity;
    float exposure;

    vec3f volumeDimensions;
    uint32 samplesPerRay;
    uint32 samplesPerShadowRay;
    bool softnessEnabled;

    // Divider
    float divider;

    // Events
    uniform float* uniform events;
    uint64 nbEvents;
};

inline varying bool intersectBox(const varying Ray& ray, const vec3f& aabbMin,
                                 const vec3f& aabbMax, varying float& t0,
                                 varying float& t1)
{
    Ray r = ray;
    vec3f invR = 1.f / r.dir;
    vec3f tbot = invR * (aabbMin - r.org);
    vec3f ttop = invR * (aabbMax - r.org);
    vec3f tmin = min(ttop, tbot);
    vec3f tmax = max(ttop, tbot);
    vec2f t = make_vec2f(max(tmin.x, tmin.y), max(tmin.x, tmin.z));
    t0 = max(t.x, t.y);
    t = make_vec2f(min(tmax.x, tmax.y), min(tmax.x, tmax.z));
    t1 = min(t.x, t.y);
    return (t0 <= t1);
}

inline varying vec4f getVoxelColor(
    const uniform VoxelizerRenderer* uniform self, const vec3f& point)
{
    double value = 0.0;
    for (uint64 i = 0; i < self->nbEvents; i += 3)
    {
        const vec3f p = make_vec3f(self->events[i], self->events[i + 1],
                                   self->events[i + 2]);
        const double len = length(p - point);
        const double field = 1.0 / len;
        value += field;
    }

    value = clamp(value / self->divider, 0.0, 1.0);
    return make_vec4f(1.f, value, 0.f,
                      (value < 0.2f ? 0.f : self->pixelOpacity));
}

inline float getEpsilon(const uniform VoxelizerRenderer* uniform self,
                        const float dist, const uint32 spr)
{
    return max(0.1f, dist / spr);
}

inline float getShadowContribution(
    const uniform VoxelizerRenderer* uniform self, varying ScreenSample& sample,
    const vec3f point)
{
    float pathOpacity = 0.f;

    const vec3f aabbmin = make_vec3f(-0.5f) * self->volumeDimensions;
    const vec3f aabbmax = make_vec3f(0.5f) * self->volumeDimensions;

    for (uniform int i = 0; self->lights && i < self->numLights; ++i)
    {
        const uniform Light* uniform light = self->lights[i];
        const varying vec2f s = make_vec2f(0.5f);
        DifferentialGeometry dg;
        const varying Light_SampleRes lightSample = light->sample(light, dg, s);

        vec3f dir;
        if (self->softShadows > 0.f)
            dir =
                normalize(self->softShadows *
                          getRandomVector(self->super.fb->size.x, sample,
                                          lightSample.dir, self->randomNumber));
        else
            dir = lightSample.dir;

        Ray shadowRay = sample.ray;
        shadowRay.org = point;
        shadowRay.dir = dir;
        shadowRay.t0 = 0;
        shadowRay.t = inf;

        float t0, t1;
        if (intersectBox(shadowRay, aabbmin, aabbmax, t0, t1))
        {
            t0 = max(0.f, t0);
            t1 = max(0.f, t1);

            const float epsilon =
                getEpsilon(self, t1 - t0, self->samplesPerShadowRay);

            for (float t = t1 + epsilon; pathOpacity < 1.f && t > t0;
                 t -= epsilon)
            {
                const vec3f p = point + t * dir;
                const vec4f voxelColor = getVoxelColor(self, p);
                pathOpacity += (voxelColor.w > 0.f ? 1.f : 0.f);
            }
        }
    }
    return pathOpacity;
}

inline vec4f shadeVoxel(const uniform VoxelizerRenderer* uniform self,
                        varying ScreenSample& sample, const vec4f& color,
                        const vec3f& normal)
{
    vec4f result = color;
    for (uniform int i = 0; self->lights && i < self->numLights; ++i)
    {
        const uniform Light* uniform light = self->lights[i];
        const varying vec2f s = make_vec2f(0.5f);
        DifferentialGeometry dg;
        const varying Light_SampleRes lightSample = light->sample(light, dg, s);

        vec3f dir = lightSample.dir;
        if (self->softShadows > 0.f)
            dir =
                normalize(self->softShadows *
                          getRandomVector(self->super.fb->size.x, sample,
                                          lightSample.dir, self->randomNumber));

        const float cosNL = abs(dot(normal, dir));
        result.x *= cosNL;
        result.y *= cosNL;
        result.z *= cosNL;
    }
    return result;
}

inline vec3f VoxelizerRenderer_shadeRay(
    const uniform VoxelizerRenderer* uniform self, varying ScreenSample& sample)
{
    const uint32 nbPositions = 14;
    const vec3f positions[14] = {{0, -1, 0},   {0, 1, 0},   {-1, 0, 0},
                                 {1, 0, 0},    {0, 0, 1},   {0, 0, -1},
                                 {-1, -1, -1}, {1, -1, -1}, {-1, 1, -1},
                                 {1, 1, -1},   {-1, -1, 1}, {1, -1, 1},
                                 {-1, 1, 1},   {1, 1, 1}};

    vec4f pathColor = make_vec4f(0.f);
    float pathOpacity = 0.f;

    float t0, t1;
    const vec3f aabbmin = make_vec3f(-0.5f) * self->volumeDimensions;
    const vec3f aabbmax = make_vec3f(0.5f) * self->volumeDimensions;

    if (intersectBox(sample.ray, aabbmin, aabbmax, t0, t1))
    {
        const float epsilon = getEpsilon(self, t1 - t0, self->samplesPerRay);

        if (self->softnessEnabled)
        {
            const float offset = (sample.sampleID.z % 16) * (epsilon / 16.f);
            t0 += offset;
            t1 += offset;
        }

        float t = t0;
        vec3f point;
        bool hit = false;
        for (t = t0; pathOpacity < 1.f && t < t1 && !hit; t += epsilon)
        {
            vec4f color = make_vec4f(0.f);

            point = sample.ray.org + t * sample.ray.dir;
            color = getVoxelColor(self, point);
            pathOpacity += color.w;

            if (color.w > 0.f && self->shadingEnabled)
            {
                vec3f normal = make_vec3f(0.f);
                uint32 hits = 0;
                for (int i = 0; i < nbPositions; ++i)
                {
                    point = positions[i] * epsilon + sample.ray.org +
                            t * sample.ray.dir;
                    const vec4f voxelColor = getVoxelColor(self, point);
                    if (voxelColor.w > 0.f)
                    {
                        ++hits;
                        normal = normal + positions[i];
                    }
                }
                if (hits > 0)
                {
                    normal = make_vec3f(0.5f) + (normal / (float)hits);
                    normal = normalize(normal);
#if 0
                    color = make_vec4f(normal, 1.f);
#else
                    color = shadeVoxel(self, sample, color, normal);
#endif
                }
            }

            if (color.w > 0.f)
            {
                if (self->shadows > 0.f)
                {
                    const float shadowContribution =
                        self->shadows *
                        getShadowContribution(self, sample, point);
                    color.x *= shadowContribution;
                    color.y *= shadowContribution;
                    color.z *= shadowContribution;
                }
                composite(color, pathColor, 1.f);
            }
        }

        sample.alpha = pathOpacity;
        sample.z = t;
    }

    return clamp(make_vec3f(pathColor) * self->exposure, make_vec3f(0.f),
                 make_vec3f(1.f));
}

void VoxelizerRenderer_renderSample(uniform Renderer* uniform _self,
                                    void* uniform perFrameData,
                                    varying ScreenSample& sample)
{
    uniform VoxelizerRenderer* uniform self =
        (uniform VoxelizerRenderer * uniform) _self;
    sample.ray.time = self->timestamp;
    sample.rgb = VoxelizerRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform VoxelizerRenderer_create(void* uniform cppE)
{
    uniform VoxelizerRenderer* uniform self =
        uniform new uniform VoxelizerRenderer;
    Renderer_Constructor(&self->super, cppE);
    self->super.renderSample = VoxelizerRenderer_renderSample;
    return self;
}

export void VoxelizerRenderer_set(
    void* uniform _self, uniform float* uniform events,
    const uniform uint64 nbEvents, const uniform vec3f& bgColor,
    const uniform float& shadows, const uniform float& softShadows,
    const uniform bool& shadingEnabled, const uniform int& randomNumber,
    const uniform float& timestamp, const uniform int& spp,
    const uniform bool& softnessEnabled, void** uniform lights,
    const uniform int32 numLights, void** uniform materials,
    const uniform int32 numMaterials, const uniform int32& samplesPerRay,
    const uniform int32& samplesPerShadowRay, const uniform float& exposure,
    const uniform float& divider, const uniform float& pixelOpacity)
{
    uniform VoxelizerRenderer* uniform self =
        (uniform VoxelizerRenderer * uniform) _self;

    self->bgColor = bgColor;
    self->shadows = shadows;
    self->softShadows = softShadows;
    self->shadingEnabled = shadingEnabled;
    self->randomNumber = randomNumber;
    self->timestamp = timestamp;
    self->spp = spp;
    self->exposure = exposure;

    self->lights = (const uniform Light* uniform* uniform)lights;
    self->numLights = numLights;

    self->materials =
        (const uniform ExtendedOBJMaterial* uniform* uniform)materials;
    self->numMaterials = numMaterials;

    self->samplesPerRay = samplesPerRay;
    self->samplesPerShadowRay = samplesPerShadowRay;
    self->volumeDimensions = make_vec3f(1.f); // Todo: Get it from the model!!

    self->divider = divider;
    self->pixelOpacity = pixelOpacity;
    self->softnessEnabled = softnessEnabled;

    self->events = events;
    self->nbEvents = nbEvents;
}
