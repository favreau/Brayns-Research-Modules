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

#pragma once

#include <common/ispc/renderer/AbstractRenderer.h>

namespace brayns
{
class VoxelizerRenderer : public ospray::Renderer
{
public:
    VoxelizerRenderer();

    /**
       Returns the class name as a string
       @return string containing the full name of the class
    */
    std::string toString() const final { return "VoxelizerRenderer"; }
    void commit() final;

private:
    std::vector<void*> _lightArray;
    void** _lightPtr;
    std::vector<void*> _materialArray;
    void** _materialPtr;

    ospray::Model* _world;
    ospray::Data* _materialData;
    ospray::Data* _lightData;

    ospray::vec3f _bgColor;
    float _shadows;
    float _softShadows;
    float _ambientOcclusionStrength;
    float _ambientOcclusionDistance;
    bool _shadingEnabled;
    bool _electronShadingEnabled;
    bool _gradientBackgroundEnabled;
    int _randomNumber;
    float _timestamp;
    int _spp;

    // Transfer function
    ospray::Ref<ospray::Data> _transferFunctionDiffuseData;
    ospray::Ref<ospray::Data> _transferFunctionEmissionData;
    ospray::int32 _transferFunctionSize;
    float _transferFunctionMinValue;
    float _transferFunctionRange;
    float _threshold;

    // Voxelizer
    ospray::int32 _volumeSamplesPerRay;
};
}
