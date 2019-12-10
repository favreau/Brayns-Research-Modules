/* Copyright (c) 2018-2019, EPFL/Blue Brain Project
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
 *
 * This file is part of the circuit explorer for Brayns
 * <https://github.com/favreau/Brayns-UC-CircuitExplorer>
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

#include "EEGHandler.h"

#include <plugin/log.h>

#include <algorithm>
#include <fstream>
#include <sstream>

EEGHandler::EEGHandler(const std::string& filename, const float scale,
                       const float density)
    : brayns::AbstractSimulationHandler()
{
    std::ifstream file(filename);
    if (!file.good())
        PLUGIN_THROW("Could not open file " + filename)

    std::stringstream stream({std::istreambuf_iterator<char>(file),
                              std::istreambuf_iterator<char>()});
    size_t numlines = 0;
    {
        numlines = std::count(std::istreambuf_iterator<char>(stream),
                              std::istreambuf_iterator<char>(), '\n');
    }
    stream.seekg(0);
    size_t i = 0;
    std::string line;
    while (std::getline(stream, line))
    {
        std::vector<float> lineData;
        std::stringstream lineStream(line);

        float value;
        while (lineStream >> value)
            lineData.push_back(value);

        switch (lineData.size())
        {
        case 3:
        {
            if ((i * density) == static_cast<uint32_t>(i * density))
            {
                _frameData.push_back(lineData[0] * scale);
                _frameData.push_back(lineData[1] * scale);
                _frameData.push_back(lineData[2] * scale);
            }
            break;
        }
        default:
            PLUGIN_THROW("Invalid content in line " + std::to_string(i + 1) +
                         ": " + line);
        }
        ++i;
    }
    _nbFrames = 0;
    _dt = 0.f;
    _unit = "None";
    _frameSize = _frameData.size();
    PLUGIN_INFO << filename << " was successfully loaded (" << _frameSize / 3
                << " events, scale=" << scale << ")" << std::endl;
}

EEGHandler::EEGHandler(const EEGHandler& rhs)
    : brayns::AbstractSimulationHandler(rhs)
{
}

EEGHandler::~EEGHandler() {}

void* EEGHandler::getFrameData(const uint32_t frame)
{
    if (!_initialized)
    {
        _initialized = true;
        return _frameData.data();
    }
    return nullptr;
}

brayns::AbstractSimulationHandlerPtr EEGHandler::clone() const
{
    return std::make_shared<EEGHandler>(*this);
}
