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

const unsigned int GRADIENT_SIZE = 4;

struct SSSRenderer
{
    AbstractRenderer abstract;
};

/**
    Renderer a pixel color according to a given location in the screen space.
    @param self Pointer to current renderer
    @param sample Screen sample containing information about the ray, and the
           location in the screen space.
*/
inline vec3f SSSRenderer_shadeRay(const uniform SSSRenderer* uniform self,
                                  varying ScreenSample& sample)
{
    Ray ray = sample.ray;
    vec4f intersectionColor = make_vec4f(0.f);

    sample.z = inf;
    sample.alpha = 0.f;

    float pathOpacity = 0.f;
    unsigned int depth = 0;

    while (pathOpacity < 1.f)
    {
        traceRay(self->abstract.super.model, ray);
        if (ray.geomID < 0)
        {
            // No intersection. Return skybox color
            vec4f color =
                skyboxMapping((Renderer*)self, ray, self->abstract.bgMaterial);
            color.w = 1.f;
            composite(color, intersectionColor);
            break;
        }

        DifferentialGeometry dg;
        postIntersect(self->abstract.super.model, dg, ray,
                      DG_NS | DG_NG | DG_NORMALIZE | DG_FACEFORWARD |
                          DG_MATERIALID | DG_COLOR);

        uniform Material* material = dg.material;
        uniform ExtendedOBJMaterial* objMaterial =
            (uniform ExtendedOBJMaterial*)material;

        vec3f Kd = make_vec3f(0.f);
        float opacity = 0.f;
        if (!objMaterial)
        {
            Kd = make_vec3f(dg.color);
            opacity = dg.color.w;
        }
        else
            foreach_unique(mat in objMaterial)
            {
                Kd = mat->Kd * make_vec3f(dg.color);
                opacity = mat->d;
            }

        if (depth == 0)
        {
            pathOpacity = opacity;
            sample.z = ray.t;
        }
        pathOpacity *= 1.f + opacity;

        // Head-light SSS shading
        const vec3f intersection = dg.P + dg.epsilon * dg.Ns;
        const vec3f headLight = normalize(ray.org - intersection);
        const vec3f light = make_vec3f(1.f);

        float p = 0.f;
        float a = dot(light, headLight);
        if (a < 0.f)
        {
            Ray lightRay;
            lightRay.dir = neg(headLight);
            lightRay.org = dg.P + dg.epsilon * lightRay.dir;
            lightRay.t0 = dg.epsilon;
            lightRay.t = inf;
            lightRay.primID = -1;
            lightRay.geomID = -1;
            lightRay.instID = -1;

            traceRay(self->abstract.super.model, lightRay);
            if (lightRay.geomID >= 0)
                p = -1.f * a / lightRay.t * max(0.f, -dot(lightRay.dir, dg.Ns));
        }

        const float g = max(0.f, dot(light, dg.Ns));
        const float angle = clamp(p + g, 0.f, 1.f);
        const vec4f color = make_vec4f(Kd * angle, opacity);
        composite(color, intersectionColor);

        // Next ray
        ray.t0 = ray.t + dg.epsilon;
        ray.t = infinity;
        ray.primID = -1;
        ray.geomID = -1;
        ray.instID = -1;
        ++depth;
    }
    sample.alpha = pathOpacity;

    return make_vec3f(intersectionColor);
}

void SSSRenderer_renderSample(uniform Renderer* uniform _self,
                              void* uniform perFrameData,
                              varying ScreenSample& sample)
{
    uniform SSSRenderer* uniform self = (uniform SSSRenderer * uniform) _self;
    sample.ray.time = self->abstract.timestamp;
    sample.rgb = SSSRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform SSSRenderer_create(void* uniform cppE)
{
    uniform SSSRenderer* uniform self = uniform new uniform SSSRenderer;
    Renderer_Constructor(&self->abstract.super, cppE);
    self->abstract.super.renderSample = SSSRenderer_renderSample;
    return self;
}

export void SSSRenderer_set(void* uniform _self, void* uniform bgMaterial,
                            const uniform float& timestamp,
                            const uniform int& spp, void** uniform lights,
                            uniform int32 numLights)
{
    uniform SSSRenderer* uniform self = (uniform SSSRenderer * uniform) _self;

    self->abstract.bgMaterial =
        (uniform ExtendedOBJMaterial * uniform) bgMaterial;

    self->abstract.timestamp = timestamp;
    self->abstract.spp = spp;

    self->abstract.lights = (const uniform Light* uniform* uniform)lights;
    self->abstract.numLights = numLights;
}
