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

#include "math/sampling.ih"
#include "ospray/SDK/camera/Camera.ih"

struct HolographicCamera
{
    Camera super;

    vec3f org;    //!< position of camera, already contains shift when
                  //! STEREO_{LEFT|RIGHT}
    vec3f dir_00; //!< direction of ray with screenSample=(0,0); scaled to
                  //! focusDistance
    vec3f dir_du; //!< delta of ray direction between two pixels in X; scaled to
                  //! focusDistance
    vec3f dir_dv; //!< delta of ray direction between two pixels in Y; scaled to
                  //! focusDistance
};

void HolographicCamera_initRay(uniform Camera* uniform _self, varying Ray& ray,
                               const varying CameraSample& sample)
{
    uniform HolographicCamera* uniform self =
        (uniform HolographicCamera * uniform) _self;

    vec2f screen = sample.screen;
    vec3f org = self->org;

    screen = Camera_subRegion(_self, screen);

    float nearClip = self->super.nearClip;
    float farClip = infinity;

    vec2f sc = screen;
    vec3f dir;
    if (screen.x > 0.33f && screen.x < 0.67f)
    {
        if (screen.y < 0.33f)
        {
            // Front
            sc = screen + make_vec2f(0.f, 0.33f);
            dir = (self->dir_00 + sc.x * self->dir_du +
                   (1.f - sc.y) * self->dir_dv);
        }
        else if (screen.y > 0.67f)
        {
            // Back
            sc = screen + make_vec2f(0.f, -0.33f);
            dir = (self->dir_00 + (1.f - sc.x) * self->dir_du +
                   sc.y * self->dir_dv);
        }
        else
            farClip = nearClip;
    }
    else if (screen.y > 0.33f && screen.y < 0.67f)
    {
        if (screen.x < 0.33f)
        {
            // Left
            sc = screen + make_vec2f(0.33f, 0.f);
            dir = (self->dir_00 + (1.f - sc.y) * self->dir_du +
                   (1.f - sc.x) * self->dir_dv);
        }
        else if (screen.x > 0.67f)
        {
            // Right
            sc = screen + make_vec2f(-0.33f, 0.f);
            dir = (self->dir_00 + sc.y * self->dir_du + sc.x * self->dir_dv);
        }
        else
            farClip = nearClip;
    }
    else
        farClip = nearClip;
    const varying vec3f direction = normalize(dir);
    setRay(ray, org, direction, nearClip, farClip);
}

/*! create a new ispc-side version of a ClippedPerspectiveCamera - with given
    pointer to the c-class version - and return both class pointer and
    pointer to internal data back via the supplied reference
    parameters */
export void* uniform HolographicCamera_create(void* uniform cppE)
{
    uniform HolographicCamera* uniform self =
        uniform new uniform HolographicCamera;
    self->super.cppEquivalent = cppE;
    self->super.initRay = HolographicCamera_initRay;
    self->super.doesDOF = false;
    return self;
}

export void HolographicCamera_set(void* uniform _self, const uniform vec3f& org,
                                  const uniform vec3f& dir_00,
                                  const uniform vec3f& dir_du,
                                  const uniform vec3f& dir_dv)
{
    uniform HolographicCamera* uniform self =
        (uniform HolographicCamera * uniform) _self;
    self->org = org;
    self->dir_00 = dir_00;
    self->dir_du = dir_du;
    self->dir_dv = dir_dv;
    self->super.doesDOF = false;
}
