# Copyright (c) 2018, EPFL/Blue Brain Project
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
#
# This file is part of https://github.com/favreau/Brayns-Research-Modules

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
set(MODULE_NAME ospray_module_cartoon)
project(${MODULE_NAME} VERSION 1.0.0)
set(${MODULE_NAME}_VERSION_ABI 1)

set(MODULE_SOURCES
    cartoon.cpp
    ispc/renderer/ContoursRenderer.cpp
    ispc/renderer/CartoonRenderer.cpp)

set(MODULE_ISPC_SOURCES
    ispc/renderer/ContoursRenderer.ispc
    ispc/renderer/CartoonRenderer.ispc)

# Compile ispc code
list(APPEND CMAKE_MODULE_PATH ${OSPRAY_CMAKE_ROOT})
include(ispc)
list(APPEND ALL_ISPC_INCLUDES ${BRAYNS_RESEARCH_MODULES_DIR})
list(APPEND ALL_ISPC_INCLUDES ${OSPRAY_INCLUDE_DIRS})
include_directories_ispc(${ALL_ISPC_INCLUDES})
ospray_ispc_compile(${MODULE_ISPC_SOURCES})
list(APPEND MODULE_SOURCES ${ISPC_OBJECTS})

# Compile C++ code
include_directories(${BRAYNS_RESEARCH_MODULES_DIR} ${OSPRAY_INCLUDE_DIRS})
set(MODULE_LINK_LIBRARIES PUBLIC ${OSPRAY_LIBRARIES} brayns_research_common)
add_library(${MODULE_NAME} SHARED ${MODULE_SOURCES})
target_link_libraries(${MODULE_NAME} ${MODULE_LINK_LIBRARIES})

# Installation
install(TARGETS ${MODULE_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
