# Copyright (c) 2018, Cyrille Favreau
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
#
# This file is part of https://github.com/favreau/Brayns-Research-Modules

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
set(MODULE_NAME ospray_module_simulation)
project(${MODULE_NAME} VERSION 1.0.0)
set(${MODULE_NAME}_VERSION_ABI 1)

set(MODULE_SOURCES
    simulation.cpp
    ispc/renderer/TransparencyRenderer.cpp)

set(MODULE_ISPC_SOURCES
    ispc/renderer/TransparencyRenderer.ispc)

# Compile ispc code
list(APPEND CMAKE_MODULE_PATH ${OSPRAY_CMAKE_ROOT})
list(APPEND ALL_ISPC_INCLUDES ${BRAYNS_RESEARCH_MODULES_DIR})
list(APPEND ALL_ISPC_INCLUDES ${OSPRAY_INCLUDE_DIRS})
include_directories_ispc(${ALL_ISPC_INCLUDES})
ospray_ispc_compile(${MODULE_ISPC_SOURCES})
list(APPEND MODULE_SOURCES ${ISPC_OBJECTS})

# Compile C++ code
include_directories(${BRAYNS_RESEARCH_MODULES_DIR} ${OSPRAY_INCLUDE_DIRS})
set(MODULE_LINK_LIBRARIES PUBLIC ${OSPRAY_LIBRARIES})
add_library(${MODULE_NAME} SHARED ${MODULE_SOURCES})
target_link_libraries(${MODULE_NAME} ${MODULE_LINK_LIBRARIES} brayns_research_common)

# Installation
install(TARGETS ${MODULE_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
