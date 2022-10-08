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

#ifndef RESEARCHMODULESPARAMS_H
#define RESEARCHMODULESPARAMS_H

#include <brayns/common/types.h>

struct Result
{
    bool success{false};
    std::string error;
};
std::string to_json(const Result& param);

struct AttachEEGFile
{
    int32_t modelId;
    std::string path;
    double scale;
    double density;
};
bool from_json(AttachEEGFile& attachEEGFile, const std::string& payload);

#endif // RESEARCHMODULESPARAMS_H