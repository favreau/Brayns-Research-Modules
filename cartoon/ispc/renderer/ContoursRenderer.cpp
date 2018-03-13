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

#include "ContoursRenderer.h"

// ospray
#include <ospray/SDK/common/Data.h>

// ispc exports
#include "ContoursRenderer_ispc.h"

using namespace ospray;

namespace brayns
{
void ContoursRenderer::commit()
{
    AbstractRenderer::commit();

    _detectionDistance = getParam1f("detectionDistance", 1.f);
    _wireframe = bool(getParam1i("electronShading", 0));

    ispc::ContoursRenderer_set(getIE(), (ispc::vec3f&)_bgColor, _timestamp,
                               _spp, _lightPtr, _lightArray.size(),
                               _materialPtr, _materialArray.size(), _wireframe,
                               _detectionDistance);
}

ContoursRenderer::ContoursRenderer()
{
    ispcEquivalent = ispc::ContoursRenderer_create(this);
}

OSP_REGISTER_RENDERER(ContoursRenderer, contours);
}
