# Copyright (c) 2018, Cyrille Favreau
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
#
# This file is part of https://github.com/favreau/Brayns-Research-Modules

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
set(MODULE_NAME brayns_research_common)
project(${MODULE_NAME} VERSION 1.0.0)
set(${MODULE_NAME}_VERSION_ABI 1)

set(BRAYNS_RESEARCH_COMMON_SOURCES
    ispc/renderer/ExtendedOBJMaterial.cpp
    ispc/renderer/AbstractRenderer.cpp)

set(BRAYNS_RESEARCH_COMMON_ISPC_SOURCES
    ispc/renderer/SkyBox.ispc
    ispc/renderer/RandomGenerator.ispc
    ispc/renderer/ExtendedOBJMaterial.ispc
    ispc/renderer/AbstractRenderer.ispc)

# Compile ispc code
list(APPEND CMAKE_MODULE_PATH ${OSPRAY_CMAKE_ROOT})
list(APPEND ALL_ISPC_INCLUDES ${OSPRAY_INCLUDE_DIRS})
list(APPEND ALL_ISPC_INCLUDES ${BRAYNS_RESEARCH_MODULES_DIR})
include_directories_ispc(${ALL_ISPC_INCLUDES})
ospray_ispc_compile(${BRAYNS_RESEARCH_COMMON_ISPC_SOURCES})
list(APPEND BRAYNS_RESEARCH_COMMON_SOURCES ${ISPC_OBJECTS})

# Compile C++ code
include_directories(${OSPRAY_INCLUDE_DIRS} ${BRAYNS_RESEARCH_MODULES_DIR})
set(BRAYNS_RESEARCH_COMMON_LINK_LIBRARIES PUBLIC ${OSPRAY_LIBRARIES})
add_library(${MODULE_NAME} STATIC ${BRAYNS_RESEARCH_COMMON_SOURCES})
target_link_libraries(${MODULE_NAME} ${BRAYNS_RESEARCH_COMMON_LINK_LIBRARIES})

# Installation
install(TARGETS ${MODULE_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
