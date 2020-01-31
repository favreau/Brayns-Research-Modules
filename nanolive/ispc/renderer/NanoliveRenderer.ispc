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

struct NanoliveRenderer
{
    Renderer super;

    // Rendering attributes
    vec3f bgColor;
    float timestamp;
    int spp;
    int maxBounces;

    float pixelOpacity;
    float density;
    float exposure;
};

inline vec3f NanoliveRenderer_shadeRay(
    const uniform NanoliveRenderer* uniform self, varying ScreenSample& sample)
{
    Ray ray = sample.ray;
    ray.time = inf;
    sample.z = inf;

    float zDepth = 0.f;
    int depth = 0;

    const uniform Material* preMaterial = 0;
    vec3f pathColor = make_vec3f(0.f);
    float pathOpacity = 0.f;

    float t = 0.f;
    float d = 1.f;
    int counter = 0;
    while (pathOpacity < 1.f && depth < self->maxBounces)
    {
        vec4f colorContribution;
        traceRay(self->super.model, ray);

        if (ray.geomID < 0)
        {
            // No intersection
#if 0
            colorContribution = make_vec4f(self->bgColor, 1.f);
            composite(colorContribution, pathColor, self->pixelOpacity);
#else
            pathColor =
                self->bgColor * pathOpacity + pathColor * (1.f - pathOpacity);
#endif
            break;
        }

        // Intersection found.
        // Retreive information about the geometry, typically geometry ID,
        // normal to the surface, material ID, texture coordinates, etc.
        DifferentialGeometry dg;
        postIntersect(self->super.model, dg, ray,
                      DG_NG | DG_NS | DG_NORMALIZE | DG_FACEFORWARD |
                          DG_MATERIALID | DG_COLOR | DG_TEXCOORD);

        const vec3f intersection = ray.org + ray.t * ray.dir;

        // Material management
        const uniform Material* material = dg.material;

        const float angle = dot(ray.dir, dg.Ns);
        if (angle < 0.f)
        {
            // Enter geometry
            counter--;
            if (counter == -1)
            {
                d = 0.f;
                t = ray.t;
            }
        }
        else
        {
            // Exit geometry
            if (depth == 0)
                counter = 0;
            else
                counter++;
        }

        if (counter == 0)
        {
            // Material attributes
            uniform ExtendedOBJMaterial* objMaterial =
                (uniform ExtendedOBJMaterial*)material;

            vec3f Kd;
            float opacity = self->pixelOpacity;

            if (!objMaterial)
                Kd = make_vec3f(dg.color);
            else
                foreach_unique(mat in objMaterial)
                {
                    Kd = make_vec3f(dg.color) * mat->Kd;
                }

#if 1
            const vec3f color = make_vec3f(d * self->density);
            pathOpacity = pathOpacity + opacity;
            pathColor = color * opacity + pathColor * (1.f - opacity);
#else
            // Head-light electron shading
            Kd = make_vec3f(1.f);
            const float cosNL = self->density + 1.f -
                                max(0.f, pow(dot(neg(ray.dir), dg.Ns), 0.2f));
            const vec3f color = cosNL * Kd * (1.f / (d * d));

            colorContribution = make_vec4f(color, opacity);

            // Compositing according to alpha correction
            composite(colorContribution, pathColor, opacity);
#endif
        }

        // Next ray
        preMaterial = material;
        ray.t0 = ray.t + dg.epsilon;
        ray.t = inf;

        ray.primID = -1;
        ray.geomID = -1;
        ray.instID = -1;

        // Depth
        if (depth == 0)
            sample.z = ray.t;

        ++depth;
    }

    // Alpha
    sample.alpha = pathOpacity;

    return pathColor * self->exposure;
}

void NanoliveRenderer_renderSample(uniform Renderer* uniform _self,
                                   void* uniform perFrameData,
                                   varying ScreenSample& sample)
{
    uniform NanoliveRenderer* uniform self =
        (uniform NanoliveRenderer * uniform) _self;
    sample.ray.time = self->timestamp;
    sample.rgb = NanoliveRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform NanoliveRenderer_create(void* uniform cppE)
{
    uniform NanoliveRenderer* uniform self =
        uniform new uniform NanoliveRenderer;
    Renderer_Constructor(&self->super, cppE);
    self->super.renderSample = NanoliveRenderer_renderSample;
    return self;
}

export void NanoliveRenderer_set(
    void* uniform _self, const uniform vec3f& bgColor,
    const uniform float& timestamp, const uniform int& spp,
    const uniform int& maxBounces, const uniform float& exposure,
    const uniform float& pixelOpacity, const uniform float& density)
{
    uniform NanoliveRenderer* uniform self =
        (uniform NanoliveRenderer * uniform) _self;

    self->bgColor = bgColor;
    self->timestamp = timestamp;
    self->spp = spp;
    self->maxBounces = maxBounces;
    self->exposure = exposure;

    self->density = density;
    self->pixelOpacity = pixelOpacity;
}
