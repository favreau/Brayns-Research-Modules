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

#include "NanoliveRenderer.h"

// ospray
#include <ospray/SDK/common/Data.h>
#include <ospray/SDK/lights/Light.h>

// ispc exports
#include "NanoliveRenderer_ispc.h"

using namespace ospray;

namespace brayns
{
void NanoliveRenderer::commit()
{
    Renderer::commit();

    _bgColor = getParam3f("bgColor", ospray::vec3f(1.f));
    _timestamp = getParam1f("timestamp", 0.f);
    _spp = getParam1i("spp", 1);
    _maxBounces = getParam1i("maxBounces", 3);
    _exposure = getParam1f("exposure", 1.f);

    // Extra
    _pixelOpacity = getParam1f("pixelOpacity", 1.f);
    _density = getParam1f("density", 1.f);

    ispc::NanoliveRenderer_set(getIE(), (ispc::vec3f&)_bgColor, _timestamp,
                               _spp, _maxBounces, _exposure, _pixelOpacity,
                               _density);
}

NanoliveRenderer::NanoliveRenderer()
{
    ispcEquivalent = ispc::NanoliveRenderer_create(this);
}

OSP_REGISTER_RENDERER(NanoliveRenderer, research_nanolive);
} // namespace brayns
