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

struct TransparencyRenderer
{
    AbstractRenderer abstract;

    uniform float* uniform simulationData;
    int64 simulationDataSize;
    float threshold;
};

inline varying vec4f
    getSimulationValue(const uniform TransparencyRenderer* uniform self,
                       DifferentialGeometry& dg, const int32 index)
{
    // needs to be the same in MorphologyLoader.cpp
    const float OFFSET_MAGIC = 1e6;

    vec4f color = make_vec4f(1.f, 0.f, 0.f, 0.5f);
    if (!self->simulationData || !self->abstract.colorMap)
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
    const float normalizedValue = (value - self->abstract.colorMapMinValue) /
                                  self->abstract.colorMapRange;

    const uint32 lookupIndex =
        max(0.f, min(normalizedValue, 1.f)) * (self->abstract.colorMapSize - 1);

    return self->abstract.colorMap[lookupIndex];
}

inline vec3f TransparencyRenderer_shadeRay(
    const uniform TransparencyRenderer* uniform self,
    varying ScreenSample& sample)
{
    Ray ray = sample.ray;
    ray.time = inf;

    float zDepth = 0.f;
    sample.z = 1.f;
    sample.alpha = 0.f;
    int depth = 0;
    float path_opacity = 0.f;
    float opacity = 0.f;

    vec4f intersectionColor =
        skyboxMapping((Renderer*)self, ray, self->abstract.numMaterials,
                      self->abstract.materials);

    while (path_opacity < 1.f && depth < NB_MAX_REBOUNDS)
    {
        traceRay(self->abstract.super.model, ray);

        if (ray.geomID < 0)
        {
            // No intersection
            sample.z = 1.f - log(zDepth) / 10.f;
            break;
        }
        else
        {
            // Intersection found
            if (depth == 0)
                sample.alpha = 1.f;

            // Retreive information about the geometry, typically geometry ID,
            // normal to the surface, material ID, texture coordinates, etc.
            DifferentialGeometry dg;
            postIntersect(self->abstract.super.model, dg, ray,
                          DG_NG | DG_NS | DG_NORMALIZE | DG_FACEFORWARD |
                              DG_MATERIALID | DG_COLOR | DG_TEXCOORD);

            if (depth == 0)
                sample.z = ray.primID;

            const uniform Material* material = dg.material;
            const uniform ExtendedOBJMaterial* objMaterial =
                (const uniform ExtendedOBJMaterial*)material;
            vec3f Kd;
            if (!objMaterial)
            {
                Kd = make_vec3f(dg.color);
                opacity = dg.color.w;
            }
            else
                foreach_unique(mat in objMaterial)
                {
                    Kd = mat->Kd;
                    opacity = mat->d;
                }

            //            if (objMaterial->castSimulationData)
            {
                if (opacity > 0.f)
                {
                    // Get simulation value from geometry
                    const vec4f simulationValue =
                        getSimulationValue(self, dg, ray.primID);

                    // Color contribution
                    vec4f colorContribution =
                        make_vec4f(Kd * opacity +
                                       make_vec3f(simulationValue) *
                                           (1.f - opacity),
                                   opacity);

                    // Head-light shading
                    const vec3f intersection =
                        dg.P + self->abstract.super.epsilon * dg.Ns;
                    const vec3f headLight = normalize(ray.org - intersection);
                    colorContribution =
                        colorContribution * max(0.f, dot(headLight, dg.Ns));

                    composite(colorContribution, intersectionColor);
                }
            }
            //            else
            //                composite(make_vec4f(Kd, opacity),
            //                intersectionColor);

            path_opacity += opacity;

            // Z-Depth
            zDepth += opacity * ray.t;
            sample.z = log(zDepth) / 10.f;

            // Next ray
            ray.t0 = ray.t + self->abstract.super.epsilon;
            ray.t = infinity;
            ray.primID = -1;
            ray.geomID = -1;
            ray.instID = -1;
        }
        ++depth;
    }

    // Z-Depth
    if (depth >= NB_MAX_REBOUNDS)
        sample.z = 1.f - log(zDepth) / 10.f;

    return make_vec3f(intersectionColor);
}

void TransparencyRenderer_renderSample(uniform Renderer* uniform _self,
                                       void* uniform perFrameData,
                                       varying ScreenSample& sample)
{
    uniform TransparencyRenderer* uniform self =
        (uniform TransparencyRenderer * uniform)_self;
    sample.ray.time = self->abstract.timestamp;
    sample.rgb = TransparencyRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform TransparencyRenderer_create(void* uniform cppE)
{
    uniform TransparencyRenderer* uniform self =
        uniform new uniform TransparencyRenderer;
    Renderer_Constructor(&self->abstract.super, cppE);
    self->abstract.super.renderSample = TransparencyRenderer_renderSample;
    return self;
}

export void TransparencyRenderer_set(
    void* uniform _self, const uniform vec3f& bgColor,
    const uniform int& randomNumber, const uniform float& timestamp,
    const uniform int& spp, void** uniform materials,
    const uniform int32 numMaterials, uniform float* uniform simulationData,
    const uniform int64 simulationDataSize, uniform vec4f* uniform colormap,
    uniform vec3f* uniform emissionIntensitiesMap,
    const uniform int32 colorMapSize, const uniform float& colorMapMinValue,
    const uniform float& colorMapRange, const uniform float& threshold)
{
    uniform TransparencyRenderer* uniform self =
        (uniform TransparencyRenderer * uniform)_self;

    self->abstract.bgColor = bgColor;
    self->abstract.randomNumber = randomNumber;
    self->abstract.timestamp = timestamp;
    self->abstract.spp = spp;

    self->abstract.materials =
        (const uniform ExtendedOBJMaterial* uniform* uniform)materials;
    self->abstract.numMaterials = numMaterials;

    self->abstract.volumeData = 0;

    self->abstract.colorMap = (uniform vec4f * uniform)colormap;
    self->abstract.emissionIntensitiesMap =
        (uniform vec3f * uniform)emissionIntensitiesMap;
    self->abstract.colorMapSize = colorMapSize;
    self->abstract.colorMapMinValue = colorMapMinValue;
    self->abstract.colorMapRange = colorMapRange;
    self->threshold = threshold;

    self->simulationData = (uniform float* uniform)simulationData;
    self->simulationDataSize = simulationDataSize;
}
