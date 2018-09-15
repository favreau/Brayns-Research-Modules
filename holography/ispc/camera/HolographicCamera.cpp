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

#include "HolographicCamera.h"
#include "HolographicCamera_ispc.h"

#include <ospray/SDK/common/Data.h>

namespace brayns
{
HolographicCamera::HolographicCamera()
{
    ispcEquivalent = ispc::HolographicCamera_create(this);
}

void HolographicCamera::commit()
{
    Camera::commit();

    fovy = getParamf("fovy", 60.f);

    dir = normalize(dir);
    ospray::vec3f dir_du = normalize(cross(dir, up));
    ospray::vec3f dir_dv;
    dir_dv = cross(dir_du, dir);

    ospray::vec3f org = pos;

    float imgPlane_size_y = 2.f * tanf(ospray::deg2rad(0.5f * fovy));
    float imgPlane_size_x = imgPlane_size_y;

    dir_du *= imgPlane_size_x;
    dir_dv *= imgPlane_size_y;

    ospray::vec3f dir_00 = dir - 0.5f * dir_du - 0.5f * dir_dv;

    ospcommon::affine3f rot{ospcommon::one};
    rot = ospcommon::affine3f::rotate({0, 1, 0}, M_PI / 2) * rot;

    ispc::HolographicCamera_set(getIE(), (const ispc::vec3f&)org,
                                (const ispc::vec3f&)dir_00,
                                (const ispc::vec3f&)dir_du,
                                (const ispc::vec3f&)dir_dv);
}

OSP_REGISTER_CAMERA(HolographicCamera, holographic);

} // namespace brayns
