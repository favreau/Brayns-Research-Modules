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

#include "TransparencyRenderer.h"

// ospray
#include <ospray/SDK/common/Data.h>

// ispc exports
#include "TransparencyRenderer_ispc.h"

using namespace ospray;

namespace brayns
{
void TransparencyRenderer::commit()
{
    AbstractRenderer::commit();

    _simulationData = getParamData("simulationData");
    _simulationDataSize = getParam1i("simulationDataSize", 0);
    _transferFunctionDiffuseData = getParamData("transferFunctionDiffuseData");
    _transferFunctionEmissionData =
        getParamData("transferFunctionEmissionData");
    _transferFunctionSize = getParam1i("transferFunctionSize", 0);
    _transferFunctionMinValue = getParam1f("transferFunctionMinValue", 0.f);
    _transferFunctionRange = getParam1f("transferFunctionRange", 0.f);
    _threshold = getParam1f("threshold", _transferFunctionMinValue);

    ispc::TransparencyRenderer_set(
        getIE(), (_bgMaterial ? _bgMaterial->getIE() : nullptr), _randomNumber,
        _timestamp, _spp,
        _simulationData ? (float*)_simulationData->data : NULL,
        _simulationDataSize,
        _transferFunctionDiffuseData
            ? (ispc::vec4f*)_transferFunctionDiffuseData->data
            : NULL,
        _transferFunctionEmissionData
            ? (ispc::vec3f*)_transferFunctionEmissionData->data
            : NULL,
        _transferFunctionSize, _transferFunctionMinValue,
        _transferFunctionRange, _threshold);
}

TransparencyRenderer::TransparencyRenderer()
{
    ispcEquivalent = ispc::TransparencyRenderer_create(this);
}

OSP_REGISTER_RENDERER(TransparencyRenderer, TRANSPARENCY);
OSP_REGISTER_RENDERER(TransparencyRenderer, transparency);
} // ::brayns
