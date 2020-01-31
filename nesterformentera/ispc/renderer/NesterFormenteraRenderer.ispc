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

struct NesterFormenteraRenderer
{
    Renderer super;

    // Rendering attributes
    int spp;
    int interval;
    int thickness;
};

inline vec3f NesterFormenteraRenderer_shadeRay(
    const uniform NesterFormenteraRenderer* uniform self,
    varying ScreenSample& sample)
{
    Ray ray = sample.ray;
    sample.z = inf;
    sample.alpha = 0.f;

    while (true)
    {
        traceRay(self->super.model, ray);

        if (ray.geomID < 0)
            return make_vec3f(1.f);

        const vec3f intersection = ray.org + ray.dir * ray.t;

        sample.z = ray.t;
        sample.alpha = 1.f;

        if ((int)(intersection.z + 1e6) % self->interval <= self->thickness)
            return make_vec3f(0.f);
        else // remove for transparency
            return make_vec3f(1.f);

        DifferentialGeometry dg;
        postIntersect(self->super.model, dg, ray, DG_NG);

        ray.primID = -1;
        ray.geomID = -1;
        ray.instID = -1;
        ray.t0 = ray.t + dg.epsilon;
        ray.t = inf;
    }
    return make_vec3f(1.f, 0.f, 0.f);
}

void NesterFormenteraRenderer_renderSample(uniform Renderer* uniform _self,
                                           void* uniform perFrameData,
                                           varying ScreenSample& sample)
{
    uniform NesterFormenteraRenderer* uniform self =
        (uniform NesterFormenteraRenderer * uniform) _self;
    sample.rgb = NesterFormenteraRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform NesterFormenteraRenderer_create(void* uniform cppE)
{
    uniform NesterFormenteraRenderer* uniform self =
        uniform new uniform NesterFormenteraRenderer;
    Renderer_Constructor(&self->super, cppE);
    self->super.renderSample = NesterFormenteraRenderer_renderSample;
    return self;
}

export void NesterFormenteraRenderer_set(void* uniform _self,
                                         const uniform int& spp,
                                         const uniform int& interval,
                                         const uniform int& thickness)
{
    uniform NesterFormenteraRenderer* uniform self =
        (uniform NesterFormenteraRenderer * uniform) _self;

    self->spp = spp;
    self->interval = interval;
    self->thickness = thickness;
}
