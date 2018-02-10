# Copyright (c) 2018, EPFL/Blue Brain Project
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
#
# This file is part of https://github.com/favreau/research-brayns-module

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
set(MODULE_NAME research_brayns_module_common)
project(${MODULE_NAME} VERSION 1.0.0)
set(${MODULE_NAME}_VERSION_ABI 1)

set(RESEARCH_BRAYNS_MODULE_COMMON_SOURCES
    ispc/renderer/ExtendedOBJMaterial.cpp
    ispc/renderer/AbstractRenderer.cpp)

set(RESEARCH_BRAYNS_MODULE_COMMON_ISPC_SOURCES
    ispc/renderer/SkyBox.ispc
    ispc/renderer/RandomGenerator.ispc
    ispc/renderer/ExtendedOBJMaterial.ispc
    ispc/renderer/AbstractRenderer.ispc)

# Compile ispc code
list(APPEND CMAKE_MODULE_PATH ${OSPRAY_CMAKE_ROOT})
list(APPEND ALL_ISPC_INCLUDES ${OSPRAY_INCLUDE_DIRS})
include_directories_ispc(${ALL_ISPC_INCLUDES})
ospray_ispc_compile(${RESEARCH_BRAYNS_MODULE_COMMON_ISPC_SOURCES})
list(APPEND RESEARCH_BRAYNS_MODULE_COMMON_SOURCES ${ISPC_OBJECTS})

# Compile C++ code
add_compile_options(-std=c++11)
include_directories(${OSPRAY_INCLUDE_DIRS})
set(RESEARCH_BRAYNS_MODULE_COMMON_LINK_LIBRARIES PUBLIC ${OSPRAY_LIBRARIES})
add_library(${MODULE_NAME} STATIC ${RESEARCH_BRAYNS_MODULE_COMMON_SOURCES})
target_link_libraries(${MODULE_NAME} ${RESEARCH_BRAYNS_MODULE_COMMON_LINK_LIBRARIES})

# Installation
install(TARGETS ${MODULE_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
