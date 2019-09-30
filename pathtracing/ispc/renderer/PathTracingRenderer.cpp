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

#include "PathTracingRenderer.h"

// ospray
#include <ospray/SDK/common/Data.h>

// ispc exports
#include "PathTracingRenderer_ispc.h"

using namespace ospray;

namespace brayns
{
void PathTracingRenderer::commit()
{
    AbstractRenderer::commit();

    ispc::PathTracingRenderer_set(
        getIE(), (_bgMaterial ? _bgMaterial->getIE() : nullptr), _timestamp,
        _lightPtr, _lightArray.size(), _aoStrength, _aoDistance);
}

PathTracingRenderer::PathTracingRenderer()
{
    ispcEquivalent = ispc::PathTracingRenderer_create(this);
}

OSP_REGISTER_RENDERER(PathTracingRenderer, research_path_tracing);
} // namespace brayns
