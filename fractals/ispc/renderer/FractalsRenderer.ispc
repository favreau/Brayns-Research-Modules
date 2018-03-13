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

struct FractalsRenderer
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
    float ambientOcclusionStrength;
    float ambientOcclusionDistance;
    bool electronShadingEnabled;
    int randomNumber;
    float timestamp;
    int spp;

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

inline varying uint8
    getJuliaContribution(const uniform FractalsRenderer* uniform self,
                         const vec3f& point, const unsigned int iterations)
{
    const float cRe = -0.7f;
    const float cIm = 0.27015f + point.z;

    float newRe = 1.5f * point.x / 0.5f;
    float newIm = point.y / 0.5f;

    uint8 n = 0;
    for (n = 0; n < max(255, min(255, iterations)); ++n)
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
    uint8 voxelValue = getJuliaContribution(self, point, iterations);
    const float normalizedValue =
        (voxelValue - self->colorMapMinValue) / self->colorMapRange;

    // Voxel color according to colormap value
    return self->colorMap[self->colorMapSize * normalizedValue];
}

inline float getShadowContribution(const uniform FractalsRenderer* uniform self,
                                   varying ScreenSample& sample,
                                   const vec3f point)
{
    uniform int i = 0;
    float pathOpacity = 0.f;
    // for (uniform int i = 0; self->lights && i < self->numLights; ++i)
    {
        const uniform Light* uniform light = self->lights[i];
        const varying vec2f s = make_vec2f(1.f / self->randomNumber);
        DifferentialGeometry dg;
        dg.P = point;
        const varying Light_SampleRes lightSample = light->sample(light, dg, s);

        vec3f dir;
        if (self->softShadows > 0.f)
            dir = normalize(
                self->softShadows *
                getRandomVector(sample, lightSample.dir, self->randomNumber));
        else
            dir = lightSample.dir;

        const float samplesPerPixel = self->volumeSamplesPerRay;
        const float epsilon = self->volumeDimensions.z / samplesPerPixel;

        for (float t = epsilon;
             pathOpacity < 1.f && t < self->volumeDimensions.z; t += epsilon)
        {
            const vec3f p = point + t * dir;
            const vec4f voxelColor = getVoxelColor(self, p, 255);
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

    float epsilon = self->volumeDimensions.z / self->volumeSamplesPerRay;
    float t = 0.f;

    // Fractal volume
    vec3f point;
    for (t = epsilon; pathOpacity < 1.f && t < self->volumeDimensions.z;
         t += epsilon)
    {
        point = (sample.ray.org + t * sample.ray.dir) - 0.5f;
        vec4f voxelColor = getVoxelColor(self, point, sample.sampleID.z);
        pathOpacity += voxelColor.w;
        composite(voxelColor, pathColor, 1.f);
    }

    // Shadow
    if (pathOpacity > 0.5f && self->shadows > 0.f)
    {
        const float shadowContribution =
            pathOpacity *
            (1.f - self->shadows * getShadowContribution(self, sample, point));
        pathColor.x *= shadowContribution;
        pathColor.y *= shadowContribution;
        pathColor.z *= shadowContribution;
    }

    // Combine with background color
    const vec4f bgColor = make_vec4f(self->bgColor, 1.f);
    composite(bgColor, pathColor, 1.f);

    sample.alpha = pathOpacity;
    sample.z = t;

    return make_vec3f(pathColor);
}

void FractalsRenderer_renderSample(uniform Renderer* uniform _self,
                                   void* uniform perFrameData,
                                   varying ScreenSample& sample)
{
    uniform FractalsRenderer* uniform self =
        (uniform FractalsRenderer * uniform)_self;
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
    const uniform float& ambientOcclusionStrength,
    const uniform float& ambientOcclusionDistance,
    const uniform bool& shadingEnabled, const uniform int& randomNumber,
    const uniform float& timestamp, const uniform int& spp,
    const uniform bool& electronShadingEnabled, void** uniform lights,
    const uniform int32 numLights, void** uniform materials,
    const uniform int32 numMaterials, const uniform int32& volumeSamplesPerRay,
    uniform vec4f* uniform colormap,
    uniform vec3f* uniform emissionIntensitiesMap,
    const uniform int32 colorMapSize, const uniform float& colorMapMinValue,
    const uniform float& colorMapRange, const uniform float& threshold)
{
    uniform FractalsRenderer* uniform self =
        (uniform FractalsRenderer * uniform)_self;

    self->bgColor = bgColor;
    self->shadows = shadows;
    self->softShadows = softShadows;
    self->ambientOcclusionStrength = ambientOcclusionStrength;
    self->ambientOcclusionDistance = ambientOcclusionDistance;
    self->shadingEnabled = shadingEnabled;
    self->randomNumber = randomNumber;
    self->timestamp = timestamp;
    self->spp = spp;
    self->electronShadingEnabled = electronShadingEnabled;

    self->lights = (const uniform Light* uniform* uniform)lights;
    self->numLights = numLights;

    self->materials =
        (const uniform ExtendedOBJMaterial* uniform* uniform)materials;
    self->numMaterials = numMaterials;

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
