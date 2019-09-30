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

#include "SSSRenderer.h"

// ospray
#include <ospray/SDK/common/Data.h>

// ispc exports
#include "SSSRenderer_ispc.h"

using namespace ospray;

namespace brayns
{
void SSSRenderer::commit()
{
    AbstractRenderer::commit();

    ispc::SSSRenderer_set(getIE(),
                          (_bgMaterial ? _bgMaterial->getIE() : nullptr),
                          _timestamp, spp, _lightPtr, _lightArray.size());
}

SSSRenderer::SSSRenderer()
{
    ispcEquivalent = ispc::SSSRenderer_create(this);
}

OSP_REGISTER_RENDERER(SSSRenderer, research_subsurface_scattering);
} // namespace brayns
