/* Copyright (c) 2018, Cyrille Favreau
 * All rights reserved. Do not distribute without permission.
 * Responsible Authors: Cyrille Favreau <cyrille.favreau@gmail.com>
 *                      Samuel Lapere <samuel.lapere@epfl.ch>
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
#include <ospray/SDK/fb/FrameBuffer.ih>
#include <ospray/SDK/math/random.ih>
#include <ospray/SDK/render/util.ih>

struct PathTracingRenderer
{
    AbstractRenderer abstract;
};

inline float rotate(float x, float dx)
{
    x += dx;
    if (x >= 1.f) // keep x always between [0.0-1.0]
        x -= 1.f;
    return x;
}

// gets a random direction from a rotated frame
inline vec3f getRandomDir(varying RandomTEA* uniform rng, const vec3f biNorm0,
                          const vec3f biNorm1, const vec3f gNormal,
                          const float rot_x, const float rot_y,
                          const uniform float epsilon)
{
    const vec2f rn = RandomTEA__getFloats(rng);
    const float r0 = rotate(rn.x, rot_x);
    const float r1 = rotate(rn.y, rot_y);

    const float w = sqrt(1.f - r1);
    const float x = cos((2.f * M_PI) * r0) * w;
    const float y = sin((2.f * M_PI) * r0) * w;
    const float z = sqrt(r1) + epsilon;
    return x * biNorm0 + y * biNorm1 + z * gNormal;
}

inline void getBinormals(vec3f& biNorm0, vec3f& biNorm1, const vec3f& gNormal)
{
    biNorm0 = make_vec3f(1.f, 0.f, 0.f);
    if (abs(dot(biNorm0, gNormal)) > .95f)
        biNorm0 = make_vec3f(0.f, 1.f, 0.f);
    biNorm1 = normalize(cross(biNorm0, gNormal));
    biNorm0 = normalize(cross(biNorm1, gNormal));
}

/**
    Renderer a pixel color according to a given location in the screen space.
    @param self Pointer to current renderer
    @param sample Screen sample containing information about the ray, and the
           location in the screen space.
*/
inline vec3f PathTracingRenderer_shadeRay(
    const uniform PathTracingRenderer* uniform self,
    varying ScreenSample& sample)
{
    Ray ray = sample.ray;
    varying vec3f color = make_vec3f(0.f);

    const vec3f constantskycolor = make_vec3f(0.4f, 0.45f, 0.5f) * 2.5f;
    const float skypower = 6.0f;
    const float skypower_zerobounce = 3.0f;

    sample.z = inf;
    sample.alpha = 0.f;

    traceRay(self->abstract.super.model, ray);

    if (ray.geomID < 0)
    {
        // No intersection. Return skybox color
        color = make_vec3f(skyboxMapping((Renderer*)self, ray,
                                         self->abstract.bgMaterial)) *
                skypower_zerobounce;

        sample.alpha = 0.f;
        return color;
    }

    // else, we've got a hit!
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

    // Head-light shading
    // const vec3f intersection = dg.P + self->abstract.super.epsilon * dg.Ns;
    // const vec3f sunDirection = normalize(ray.org - intersection);
    const vec3f sunDirection = make_vec3f(1.0f, 1.0f, -1.0f);

    if (true && self->abstract.ambientOcclusionStrength > 0.f)
    {
        const vec3f sunColor = make_vec3f(1.0f, 0.8f, 0.5f) * 2.0f;
        const uniform int accumID =
            reduce_max(sample.sampleID.z) * self->abstract.spp;
        const uniform float rot_x = 1.f - precomputedHalton3(accumID);
        const uniform float rot_y = 1.f - precomputedHalton5(accumID);

        Ray localray = ray;
        vec3f accucolor = make_vec3f(0.f);
        vec3f mask = make_vec3f(1.f);

        // random number generation (RNG)
        uniform FrameBuffer* uniform fb = self->abstract.super.fb;
        RandomTEA rng_state;
        varying RandomTEA* const uniform rng = &rng_state;
        RandomTEA__Constructor(rng, (fb->size.x * sample.sampleID.y) +
                                        sample.sampleID.x,
                               accumID);

        // path tracing loop
        for (int bounces = 0; bounces < 3; bounces++)
        {
            traceRay(self->abstract.super.model, localray);

            // if ray misses scene (no hit occurs), return background colour
            if (localray.geomID < 0)
            {
                //  const vec3f bgcol = make_vec3f(0.3f, 0.6f, 1.0f);
                const vec3f bgcol =
                    make_vec3f(skyboxMapping((Renderer*)self, localray,
                                             self->abstract.bgMaterial)) *
                    skypower;
                //	const vec3f bgcol = constantskycolor;
                accucolor = accucolor + mask * bgcol;
                break;
            }
            DifferentialGeometry dg;
            postIntersect(self->abstract.super.model, dg, localray,
                          DG_NG | DG_NS | DG_NORMALIZE | DG_FACEFORWARD |
                              DG_MATERIALID | DG_COLOR | DG_TEXCOORD);

            uniform Material* material = dg.material;
            uniform ExtendedOBJMaterial* objMaterial =
                (uniform ExtendedOBJMaterial*)material;
            if (!objMaterial)
                Kd = make_vec3f(dg.color);
            else
                foreach_unique(mat in objMaterial) Kd =
                    mat->Kd * make_vec3f(dg.color);

            // compute local orthornormal base at hitpoint
            const vec3f N = dg.Ns;
            vec3f biNormU, biNormV;
            getBinormals(biNormU, biNormV, N);

            // compute ray direction of uniformly random diffuse ray
            const vec3f raydir =
                getRandomDir(rng, biNormU, biNormV, N, rot_x, rot_y,
                             self->abstract.super.epsilon);

            // origin of new ray in path is hitpoint of previous ray in path
            const vec3f hitpoint = dg.P + (self->abstract.super.epsilon * N);
            setRay(localray, hitpoint, raydir);
            localray.t0 = self->abstract.super.epsilon;
            localray.t = 1000.0f; // self->abstract.ambientOcclusionDistance;

            //***************************************
            //           direct lighting
            //***************************************

            // cosine weighted contribution
            const float sunLight = dot(dg.Ns, sunDirection);

            if (sunLight > 0.f) // if surface is facing light
            {
                // create and trace a shadowray towards the sun
                Ray sunRay;
                setRay(sunRay, hitpoint, sunDirection);
                //                traceRay(self->abstract.super.model, sunRay);
                //                 if nothing hit, then point is in direct
                //                 sunlight
                //                if (sunRay.geomID < 0)
                //                    accucolor = accucolor + mask * sunColor *
                //                    sunLight;
            }

            // take surface color at this bounce's hitpoint into account
            mask = mask * Kd;

        } // end bounces

        // CHECK THIS!!! WITH OR WITHOUT * MASK
        color = accucolor; // * mask;
    }
    else
        color = Kd * max(0.f, dot(dg.Ns, sunDirection));

    // Z-Depth
    sample.z = ray.t;
    sample.alpha = 1.f;

    return color;
}

void PathTracingRenderer_renderSample(uniform Renderer* uniform _self,
                                      void* uniform perFrameData,
                                      varying ScreenSample& sample)
{
    uniform PathTracingRenderer* uniform self =
        (uniform PathTracingRenderer * uniform)_self;
    sample.ray.time = self->abstract.timestamp;
    sample.rgb = PathTracingRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform PathTracingRenderer_create(void* uniform cppE)
{
    uniform PathTracingRenderer* uniform self =
        uniform new uniform PathTracingRenderer;
    Renderer_Constructor(&self->abstract.super, cppE);
    self->abstract.super.renderSample = PathTracingRenderer_renderSample;
    return self;
}

export void PathTracingRenderer_set(
    void* uniform _self, void* uniform bgMaterial,
    const uniform float& timestamp, const uniform int& spp,
    void** uniform lights, uniform int32 numLights,
    const uniform float& ambientOcclusionStrength,
    const uniform float& ambientOcclusionDistance)
{
    uniform PathTracingRenderer* uniform self =
        (uniform PathTracingRenderer * uniform)_self;

    self->abstract.bgMaterial =
        (uniform ExtendedOBJMaterial * uniform)bgMaterial;

    self->abstract.ambientOcclusionStrength = ambientOcclusionStrength;
    self->abstract.ambientOcclusionDistance = ambientOcclusionDistance;
    self->abstract.timestamp = timestamp;
    self->abstract.spp = spp;

    self->abstract.lights = (const uniform Light* uniform* uniform)lights;
    self->abstract.numLights = numLights;
}
