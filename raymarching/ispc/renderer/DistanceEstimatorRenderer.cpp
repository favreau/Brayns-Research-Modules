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

#include "DistanceEstimatorRenderer.h"

// ospray
#include <ospray/SDK/common/Data.h>
#include <ospray/SDK/lights/Light.h>

// ispc exports
#include "DistanceEstimatorRenderer_ispc.h"

using namespace ospray;

namespace brayns
{
void DistanceEstimatorRenderer::commit()
{
    AbstractRenderer::commit();

    // Transfer function
    _transferFunctionDiffuseData = getParamData("transferFunctionDiffuseData");
    _transferFunctionEmissionData =
        getParamData("transferFunctionEmissionData");
    _transferFunctionSize = getParam1i("transferFunctionSize", 0);
    _transferFunctionMinValue = getParam1f("transferFunctionMinValue", 0.f);
    _transferFunctionRange = getParam1f("transferFunctionRange", 0.f);
    _threshold = getParam1f("threshold", _transferFunctionMinValue);

    // Volume
    _volumeSamplesPerRay = getParam1i("volumeSamplesPerRay", 32);

    ispc::DistanceEstimatorRenderer_set(
        getIE(), (_bgMaterial ? _bgMaterial->getIE() : nullptr), _shadows,
        _softShadows, _ambientOcclusionStrength, _ambientOcclusionDistance,
        _shadingEnabled, _randomNumber, _timestamp, _spp,
        _electronShadingEnabled, _lightPtr, _lightArray.size(),
        _volumeSamplesPerRay,
        _transferFunctionDiffuseData
            ? (ispc::vec4f*)_transferFunctionDiffuseData->data
            : NULL,
        _transferFunctionEmissionData
            ? (ispc::vec3f*)_transferFunctionEmissionData->data
            : NULL,
        _transferFunctionSize, _transferFunctionMinValue,
        _transferFunctionRange, _threshold);
}

DistanceEstimatorRenderer::DistanceEstimatorRenderer()
{
    ispcEquivalent = ispc::DistanceEstimatorRenderer_create(this);
}

OSP_REGISTER_RENDERER(DistanceEstimatorRenderer, distanceestimator);
}
