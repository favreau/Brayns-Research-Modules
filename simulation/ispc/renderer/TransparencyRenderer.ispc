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

#include <common/ispc/renderer/SimulationRenderer.ih>

struct TransparencyRenderer
{
    SimulationRenderer super;

    uniform float* uniform simulationData;
    int64 simulationDataSize;
    float threshold;
    float timestamp;
    int32 randomNumber;
};

inline vec4f getSimulationValue(const uniform TransparencyRenderer* uniform
                                    self,
                                DifferentialGeometry& dg, const int32 index)
{
    vec4f color = make_vec4f(1.f, 0.f, 0.f, 0.5f);
    if (!self->simulationData || !self->super.colorMap)
        return color;

    float value = 0.f;
    const uint64 index = (uint64)(dg.st.x * OFFSET_MAGIC) << 32 |
                         (uint32)(dg.st.y * OFFSET_MAGIC);

    if (index < self->simulationDataSize)
        value = self->simulationData[index];
    else
        // Value offset is out of range, return error color
        return color;

    if (value < self->threshold)
        return color;

    // Normalize the value according colormap size
    const float normalizedValue =
        (value - self->super.colorMapMinValue) / self->super.colorMapRange;

    const uint32 lookupIndex =
        max(0.f, min(normalizedValue, 1.f)) * (self->super.colorMapSize - 1);

    return self->super.colorMap[lookupIndex];
}

inline vec3f TransparencyRenderer_shadeRay(
    const uniform TransparencyRenderer* uniform self,
    varying ScreenSample& sample)
{
    Ray ray = sample.ray;
    ray.time = inf;
    sample.z = inf;

    float zDepth = 0.f;
    int depth = 0;
    float opacity = 0.f;
    float pathOpacity = 0.f;

    vec4f intersectionColor = make_vec4f(0.f);
    vec4f colorContribution = make_vec4f(0.f);

    while (pathOpacity < 1.f)
    {
        traceRay(self->super.super.super.model, ray);

        if (ray.geomID < 0)
        {
            // No intersection
            colorContribution = skyboxMapping((Renderer*)self, ray,
                                              self->super.super.bgMaterial);
            colorContribution.w = 1.f;
            composite(colorContribution, intersectionColor, 1.f);
            break;
        }

        // Intersection found
        // Retreive information about the geometry, typically geometry ID,
        // normal to the surface, material ID, texture coordinates, etc.
        DifferentialGeometry dg;
        postIntersect(self->super.super.super.model, dg, ray,
                      DG_NG | DG_NS | DG_NORMALIZE | DG_FACEFORWARD |
                          DG_MATERIALID | DG_COLOR | DG_TEXCOORD);

        const uniform Material* material = dg.material;
        const uniform ExtendedOBJMaterial* objMaterial =
            (const uniform ExtendedOBJMaterial*)material;
        vec3f Kd;
        MaterialShadingMode shadingMode = diffuse;
        if (!objMaterial)
        {
            Kd = make_vec3f(dg.color);
            opacity = dg.color.w;
        }
        else
            foreach_unique(mat in objMaterial)
            {
                Kd = make_vec3f(dg.color) * mat->Kd;
                opacity = dg.color.w * mat->d;
                shadingMode = mat->shadingMode;
            }

        if (shadingMode == electron)
            opacity = 0.2f;

        if (depth == 0)
        {
            pathOpacity = opacity;
            sample.z = ray.t;
        }
        pathOpacity *= 1.f + opacity;

        // Head-light shading
        const float cosNL = max(0.f, dot(neg(ray.dir), dg.Ns));
        colorContribution = make_vec4f(Kd * cosNL, pathOpacity);

        if (objMaterial->castSimulationData)
            // Get simulation value from geometry
            colorContribution = getSimulationValue(self, dg, ray.primID);

        composite(colorContribution, intersectionColor, 1.f);

        // Next ray
        ray.t0 = ray.t + dg.epsilon;
        ray.t = infinity;
        ray.primID = -1;
        ray.geomID = -1;
        ray.instID = -1;
        ++depth;
    }

    // Alpha
    sample.alpha = pathOpacity;

    return make_vec3f(intersectionColor);
}

void TransparencyRenderer_renderSample(uniform Renderer* uniform _self,
                                       void* uniform perFrameData,
                                       varying ScreenSample& sample)
{
    uniform TransparencyRenderer* uniform self =
        (uniform TransparencyRenderer * uniform) _self;
    sample.ray.time = self->timestamp;
    sample.rgb = TransparencyRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform TransparencyRenderer_create(void* uniform cppE)
{
    uniform TransparencyRenderer* uniform self =
        uniform new uniform TransparencyRenderer;
    Renderer_Constructor(&self->super.super.super, cppE);
    self->super.super.super.renderSample = TransparencyRenderer_renderSample;
    return self;
}

export void TransparencyRenderer_set(
    void* uniform _self, void* uniform bgMaterial,
    const uniform int& randomNumber, const uniform float& timestamp,
    const uniform int& spp, uniform float* uniform simulationData,
    const uniform int64 simulationDataSize, uniform vec4f* uniform colormap,
    uniform vec3f* uniform emissionIntensitiesMap,
    const uniform int32 colorMapSize, const uniform float& colorMapMinValue,
    const uniform float& colorMapRange, const uniform float& threshold)
{
    uniform TransparencyRenderer* uniform self =
        (uniform TransparencyRenderer * uniform) _self;

    self->super.super.bgMaterial =
        (uniform ExtendedOBJMaterial * uniform) bgMaterial;

    self->timestamp = timestamp;
    self->super.super.super.spp = spp;

    self->super.colorMap = (uniform vec4f * uniform) colormap;
    self->super.emissionIntensitiesMap =
        (uniform vec3f * uniform) emissionIntensitiesMap;
    self->super.colorMapSize = colorMapSize;
    self->super.colorMapMinValue = colorMapMinValue;
    self->super.colorMapRange = colorMapRange;
    self->threshold = threshold;

    self->simulationData = (uniform float* uniform)simulationData;
    self->simulationDataSize = simulationDataSize;
    self->randomNumber = randomNumber;
}
