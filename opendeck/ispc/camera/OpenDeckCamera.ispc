/* Copyright (c) 2018, Cyrille Favreau
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille_favreau@hotmail.com>
 *
 * This file is part of the reseach Brayns module
 * <https://github.com/favreau/research-brayns-module>
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

#include "OpenDeckCamera.ih"
#include "math/sampling.ih"

void OpenDeckCamera_initRay(uniform Camera *uniform _self, varying Ray &ray,
                            const varying CameraSample &sample)
{
    uniform OpenDeckCamera *uniform self =
        (uniform OpenDeckCamera * uniform)_self;

    vec2f screen = sample.screen;
    vec3f org = self->org;

    if (self->side_by_side)
    {
        screen.x *= 2.f;
        if (screen.x < 1.f)
            org = org - self->ipd_offset;
        else
        {
            org = org + self->ipd_offset;
            screen.x -= 1.f;
        }
    }

    screen = Camera_subRegion(_self, screen);

    vec3f dir =
        self->dir_00 + screen.x * self->dir_du + screen.y * self->dir_dv;

    if (self->super.doesDOF)
    {
        const vec3f llp = uniformSampleDisk(self->scaledAperture, sample.lens);
        // transform local lens point to focal plane (dir_XX are prescaled in
        // this case)
        const vec3f lp =
            (llp.x * self->dir_du) + ((llp.y * self->aspect) * self->dir_dv);
        org = org + lp;
        dir = dir - lp;
    }

    const float time = Camera_shutterTime(_self, sample.time);
    setRay(ray, org, normalize(dir), self->super.nearClip, infinity, time);
}

/*! create a new ispc-side version of a OpenDeckcamera - with given
    pointer to the c-class version - and return both class pointer and
    pointer to internal data back via the supplied reference
    parameters */
export void *uniform OpenDeckCamera_create(void *uniform cppE)
{
    uniform OpenDeckCamera *uniform self = uniform new uniform OpenDeckCamera;
    self->super.cppEquivalent = cppE;
    self->super.initRay = OpenDeckCamera_initRay;
    self->super.doesDOF = false;
    return self;
}

export void OpenDeckCamera_set(
    void *uniform _self, const uniform vec3f &org, const uniform vec3f &dir_00,
    const uniform vec3f &dir_du, const uniform vec3f &dir_dv,
    const uniform float scaledAperture, const uniform float aspect,
    const uniform bool side_by_side, const uniform vec3f &ipd_offset)
{
    uniform OpenDeckCamera *uniform self =
        (uniform OpenDeckCamera * uniform)_self;
    self->org = org;
    self->dir_00 = dir_00;
    self->dir_du = dir_du;
    self->dir_dv = dir_dv;
    self->scaledAperture = scaledAperture;
    self->super.doesDOF = scaledAperture > 0.f;
    self->aspect = aspect;
    self->side_by_side = side_by_side;
    self->ipd_offset = ipd_offset;
}
