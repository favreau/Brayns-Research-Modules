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

    const vec2f screen = Camera_subRegion(_self, sample.screen);

    const vec3f org = self->pos;

    const float phi = two_pi * screen.x;
    const float theta = -M_PI * screen.y;

    float sinTheta, cosTheta;
    sincos(theta, &sinTheta, &cosTheta);
    const vec3f localDir = cartesian(phi, sinTheta, cosTheta);

    // transform into camera frame
    const vec3f dir = self->frame * localDir;

    const float time = Camera_shutterTime(_self, sample.time);
    setRay(ray, org, dir, self->super.nearClip, infinity, time);
}

export void *uniform OpenDeckCamera_create(void *uniform cppE)
{
    uniform OpenDeckCamera *uniform self = uniform new uniform OpenDeckCamera;
    self->super.cppEquivalent = cppE;
    self->super.initRay = OpenDeckCamera_initRay;
    self->super.doesDOF = false;
    return self;
}

export void OpenDeckCamera_set(void *uniform _self, const uniform vec3f &pos,
                               const uniform linear3f &frame)
{
    uniform OpenDeckCamera *uniform self =
        (uniform OpenDeckCamera * uniform)_self;
    self->pos = pos;
    self->frame = frame;
}
