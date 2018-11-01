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

struct ContoursRenderer
{
    AbstractRenderer abstract;

    bool wireframe;
    float detectionDistance;
};

/**
    Launch a ray parallel to the camera ray
    @param self Pointer to current renderer
    @param ray The initial camera ray
    @param org Origin of the parallel ray
    @param material Material of the intersected surface
    @return True if the parallel ray identifies a geometry contour, false
   otherwise
  */
inline bool parallelRayHitGeometry(const uniform ContoursRenderer* uniform self,
                                   varying Ray& ray, const vec3f& org,
                                   uniform Material* material)
{
    Ray r = ray;
    r.org = org;
    r.geomID = -1;
    r.primID = -1;
    r.t = inf;
    traceRay(self->abstract.super.model, r);

    if (r.geomID < 0)
        return true;
    else if (r.primID != ray.primID)
    {
        if (self->wireframe)
            return true;
        else
        {
            DifferentialGeometry dg2;
            postIntersect(self->abstract.super.model, dg2, r, DG_MATERIALID);
            if (material != dg2.material)
                return true;
        }
    }
    return false;
}

/**
    Renderer a pixel color according to a given location in the screen space.
    @param self Pointer to current renderer
    @param sample Screen sample containing information about the ray, and the
   location in the screen space.
*/
inline vec3f ContoursRenderer_shadeRay(
    const uniform ContoursRenderer* uniform self, varying ScreenSample& sample)
{
    Ray ray = sample.ray;
    varying vec3f color = make_vec3f(0.f);
    Ray r = ray;

    sample.z = inf;
    sample.alpha = 0.f;

    traceRay(self->abstract.super.model, ray);

    if (ray.geomID < 0)
    {
        // No intersection. Return skybox color
        color = make_vec3f(
            skyboxMapping((Renderer*)self, ray, self->abstract.bgMaterial));
        sample.alpha = 0.f;
        return color;
    }

    // Z-Depth
    sample.z = ray.t;
    sample.alpha = 1.f;

    DifferentialGeometry dg;
    postIntersect(self->abstract.super.model, dg, ray,
                  DG_NS | DG_NG | DG_NORMALIZE | DG_FACEFORWARD |
                      DG_MATERIALID | DG_COLOR);

    uniform Material* material = dg.material;
    uniform ExtendedOBJMaterial* objMaterial =
        (uniform ExtendedOBJMaterial*)material;

    vec3f Kd = make_vec3f(0.f);
    if (!objMaterial)
        Kd = make_vec3f(dg.color);
    else
        foreach_unique(mat in objMaterial) Kd = mat->Kd * make_vec3f(dg.color);

    // Launch a ray parallel to the camera ray, shifted in the direction of
    // the intersected surface normal
    vec3f org = sample.ray.org + self->detectionDistance * dg.Ng;
    if (parallelRayHitGeometry(self, ray, org, material))
        return make_vec3f(0.f);

    // Launch a ray parallel to the camera ray, shifted in the opposite
    // direction of the intersected surface normal
    org = sample.ray.org - self->detectionDistance * dg.Ng;
    if (parallelRayHitGeometry(self, ray, org, material))
        return make_vec3f(0.f);

    return Kd;
}

void ContoursRenderer_renderSample(uniform Renderer* uniform _self,
                                   void* uniform perFrameData,
                                   varying ScreenSample& sample)
{
    uniform ContoursRenderer* uniform self =
        (uniform ContoursRenderer * uniform)_self;
    sample.ray.time = self->abstract.timestamp;
    sample.rgb = ContoursRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform ContoursRenderer_create(void* uniform cppE)
{
    uniform ContoursRenderer* uniform self =
        uniform new uniform ContoursRenderer;
    Renderer_Constructor(&self->abstract.super, cppE);
    self->abstract.super.renderSample = ContoursRenderer_renderSample;
    return self;
}

export void ContoursRenderer_set(void* uniform _self, void* uniform bgMaterial,
                                 const uniform float& timestamp,
                                 const uniform int& spp, void** uniform lights,
                                 uniform int32 numLights,
                                 const uniform bool wireframe,
                                 const uniform float& detectionDistance)
{
    uniform ContoursRenderer* uniform self =
        (uniform ContoursRenderer * uniform)_self;

    self->abstract.bgMaterial =
        (uniform ExtendedOBJMaterial * uniform)bgMaterial;

    self->abstract.timestamp = timestamp;
    self->abstract.super.spp = spp;

    self->abstract.lights = (const uniform Light* uniform* uniform)lights;
    self->abstract.numLights = numLights;

    self->wireframe = wireframe;
    self->detectionDistance = detectionDistance;
}
