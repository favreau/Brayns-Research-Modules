/* Copyright (c) 2018-2019, EPFL/Blue Brain Project
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
 *
 * This file is part of the circuit explorer for Brayns
 * <https://github.com/favreau/Brayns-UC-ResearchModules>
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

#include "ResearchModulesParams.h"
#include <plugin/json.hpp>

#define FROM_JSON(PARAM, JSON, NAME) \
    PARAM.NAME = JSON[#NAME].get<decltype(PARAM.NAME)>()
#define TO_JSON(PARAM, JSON, NAME) JSON[#NAME] = PARAM.NAME;

bool from_json(Result& param, const std::string& payload)
{
    try
    {
        auto js = nlohmann::json::parse(payload);

        FROM_JSON(param, js, success);
        FROM_JSON(param, js, error);
    }
    catch (...)
    {
        return false;
    }
    return true;
}

std::string to_json(const Result& param)
{
    try
    {
        nlohmann::json js;

        TO_JSON(param, js, success);
        TO_JSON(param, js, error);
        return js.dump();
    }
    catch (...)
    {
        return "";
    }
    return "";
}

bool from_json(AttachEEGFile& param, const std::string& payload)
{
    try
    {
        auto js = nlohmann::json::parse(payload);
        FROM_JSON(param, js, modelId);
        FROM_JSON(param, js, path);
        FROM_JSON(param, js, scale);
        FROM_JSON(param, js, density);
    }
    catch (...)
    {
        return false;
    }
    return true;
}
