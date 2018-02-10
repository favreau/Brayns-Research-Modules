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

#include "OpenDeckCamera.h"
#include "OpenDeckCamera_ispc.h"

namespace ospray
{
OpenDeckCamera::OpenDeckCamera()
{
    ispcEquivalent = ispc::OpenDeckCamera_create(this);
}

std::string OpenDeckCamera::toString() const
{
    return "ospray::OpenDeckCamera";
}

void OpenDeckCamera::commit()
{
    Camera::commit();

    // ------------------------------------------------------------------
    // update the local precomputed values: the camera coordinate frame
    // ------------------------------------------------------------------
    linear3f frame;
    frame.vx = normalize(dir);
    frame.vy = normalize(cross(frame.vx, up));
    frame.vz = cross(frame.vx, frame.vy);

    ispc::OpenDeckCamera_set(getIE(), (const ispc::vec3f&)pos,
                             (const ispc::LinearSpace3f&)frame);
}

OSP_REGISTER_CAMERA(OpenDeckCamera, opendeck);

} // ::ospray
