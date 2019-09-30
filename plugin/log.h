/* Copyright (c) 2018-2019, EPFL/Blue Brain Project
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
 *
 * This file is part of the Brayns research modules
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

#ifndef BRAYNS_RESEARCH_MODULES_PLUGIN_LOG_H
#define BRAYNS_RESEARCH_MODULES_PLUGIN_LOG_H

#include <ctime>
#include <iostream>

#define PLUGIN_ERROR std::cerr << "[ERROR] [RESEARCH] "
#define PLUGIN_WARN std::cerr << "[WARN ] [RESEARCH] "
#define PLUGIN_INFO std::cout << "[INFO ] [RESEARCH] "
#define PLUGIN_TIMER(__time, __msg) \
    std::cout << "[TIMER] [RESEARCH] [" << __time << "] " << __msg << std::endl;
#ifdef NDEBUG
#define PLUGIN_DEBUG \
    if (false)       \
    std::cout
#else
#define PLUGIN_DEBUG std::cout << "[DEBUG] [RESEARCH] "
#endif

#define PLUGIN_THROW(__message)                 \
    {                                           \
        PLUGIN_ERROR << __message << std::endl; \
        throw std::runtime_error(__message);    \
    }

#endif // BRAYNS_RESEARCH_MODULES_PLUGIN_LOG_H
