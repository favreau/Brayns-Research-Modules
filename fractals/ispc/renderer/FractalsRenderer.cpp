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

#include "FractalsRenderer.h"

// ospray
#include <ospray/SDK/common/Data.h>
#include <ospray/SDK/lights/Light.h>

// ispc exports
#include "FractalsRenderer_ispc.h"

// ospray
#include <ospray/SDK/transferFunction/TransferFunction.h>

using namespace ospray;

namespace brayns
{
void FractalsRenderer::commit()
{
    Renderer::commit();

    _lightData = (ospray::Data*)getParamData("lights");
    _lightArray.clear();

    if (_lightData)
        for (size_t i = 0; i < _lightData->size(); ++i)
            _lightArray.push_back(
                ((ospray::Light**)_lightData->data)[i]->getIE());

    _lightPtr = _lightArray.empty() ? nullptr : &_lightArray[0];

    _bgColor = getParam3f("bgColor", ospray::vec3f(0.f));
    _shadows = getParam1f("shadows", 0.f);
    _softShadows = getParam1f("softShadows", 0.f);
    _randomNumber = getParam1i("randomNumber", 0);
    _timestamp = getParam1f("timestamp", 0.f);
    _spp = getParam1i("spp", 1);

    // Transfer function
    ospray::TransferFunction* transferFunction =
        (ospray::TransferFunction*)getParamObject("transferFunction", nullptr);
    if (transferFunction)
        ispc::FractalsRenderer_setTransferFunction(getIE(),
                                                   transferFunction->getIE());
    else
        ispc::FractalsRenderer_setTransferFunction(getIE(), nullptr);

    _samplesPerRay = getParam1i("samplesPerRay", 64);
    _maxIterations = getParam1i("maxIterations", 64);
    _julia = getParam("julia", 0);
    _threshold = getParam1f("threshold", 0.f);
    _re = getParam1f("re", -0.7f);
    _im = getParam1f("im", 0.27015f);

    ispc::FractalsRenderer_set(getIE(), (ispc::vec3f&)_bgColor, _shadows,
                               _softShadows, _randomNumber, _timestamp, _spp,
                               _lightPtr, _lightArray.size(), _samplesPerRay,
                               _maxIterations, _julia, _threshold, _re, _im);
}

FractalsRenderer::FractalsRenderer()
{
    ispcEquivalent = ispc::FractalsRenderer_create(this);
}

OSP_REGISTER_RENDERER(FractalsRenderer, research_fractals);
} // namespace brayns
