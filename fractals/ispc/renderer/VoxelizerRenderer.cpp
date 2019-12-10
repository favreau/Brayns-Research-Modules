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

#include "VoxelizerRenderer.h"

// ospray
#include <ospray/SDK/common/Data.h>
#include <ospray/SDK/lights/Light.h>

// ispc exports
#include "VoxelizerRenderer_ispc.h"

using namespace ospray;

namespace brayns
{
void VoxelizerRenderer::commit()
{
    Renderer::commit();

    _lightData = (ospray::Data*)getParamData("lights");
    _lightArray.clear();

    if (_lightData)
        for (size_t i = 0; i < _lightData->size(); ++i)
            _lightArray.push_back(
                ((ospray::Light**)_lightData->data)[i]->getIE());

    _lightPtr = _lightArray.empty() ? nullptr : &_lightArray[0];

    _bgColor = getParam3f("bgColor", ospray::vec3f(1.f));
    _shadows = getParam1f("shadows", 0.f);
    _softShadows = getParam1f("softShadows", 0.f);
    _shadingEnabled = bool(getParam1i("shadingEnabled", 1));
    _softnessEnabled = bool(getParam1i("softnessEnabled", 0));
    _randomNumber = getParam1i("randomNumber", 0);
    _timestamp = getParam1f("timestamp", 0.f);
    _spp = getParam1i("spp", 1);
    _exposure = getParam1f("exposure", 1.f);

    // Those materials are used for simulation mapping only
    _materialData = (ospray::Data*)getParamData("materials");
    _materialArray.clear();
    if (_materialData)
        for (size_t i = 0; i < _materialData->size(); ++i)
            _materialArray.push_back(
                ((ospray::Material**)_materialData->data)[i]->getIE());
    _materialPtr = _materialArray.empty() ? nullptr : &_materialArray[0];

    // Sampling
    _samplesPerRay = getParam1i("samplesPerRay", 32);
    _samplesPerShadowRay = getParam1i("samplesPerShadowRay", 32);

    // Extra
    _divider = getParam1f("divider", 4096.f);
    _pixelOpacity = getParam1f("pixelOpacity", 0.2f);

    // Events
    _events = getParamData("simulationData");
    _nbEvents = _events ? _events->size() : 0;

    ispc::VoxelizerRenderer_set(
        getIE(), (_events ? (float*)_events->data : nullptr), _nbEvents,
        (ispc::vec3f&)_bgColor, _shadows, _softShadows, _shadingEnabled,
        _randomNumber, _timestamp, _spp, _softnessEnabled, _lightPtr,
        _lightArray.size(), _materialPtr, _materialArray.size(), _samplesPerRay,
        _samplesPerShadowRay, _exposure, _divider, _pixelOpacity);
}

VoxelizerRenderer::VoxelizerRenderer()
{
    ispcEquivalent = ispc::VoxelizerRenderer_create(this);
}

OSP_REGISTER_RENDERER(VoxelizerRenderer, research_voxelizer);
} // namespace brayns
