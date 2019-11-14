# Copyright (c) 2018, Cyrille Favreau
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
#
# This file is part of https://github.com/favreau/Brayns-Research-Modules

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
set(NAME BRAYNSRESEARCHMODULES)
set(LIBRARY_NAME braynsResearchModules)
project(${NAME} VERSION 1.0.0)
set(${NAME}_VERSION_ABI 1)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake)
set(BRAYNS_RESEARCH_MODULES_DIR ${PROJECT_SOURCE_DIR})

# C++ 14
set(CMAKE_CXX_STANDARD 14)

find_package(Brayns REQUIRED)
find_package(ospray REQUIRED SYSTEM)
include(ispc)

set(${NAME}_SOURCES
    common/ispc/renderer/ExtendedOBJMaterial.cpp
    common/ispc/renderer/AbstractRenderer.cpp
    common/ispc/renderer/SimulationRenderer.cpp
    holography/ispc/camera/HolographicCamera.cpp
    holography/holography.cpp
    pathtracing/ispc/renderer/PathTracingRenderer.cpp
    pathtracing/pathtracing.cpp
    volume/ispc/renderer/VolumeRenderer.cpp
    volume/volume.cpp
    raymarching/raymarching.cpp
    raymarching/ispc/renderer/DistanceEstimatorRenderer.cpp
    fractals/ispc/renderer/MengerSpongeRenderer.cpp
    fractals/ispc/renderer/VoxelizerRenderer.cpp
    fractals/ispc/renderer/FractalsRenderer.cpp
    fractals/fractals.cpp
    plugin/BraynsResearchModulesPlugin.cpp
#    pbr/ispc/renderer/PbrRenderer.cpp
#    pbr/pbr.cpp
    cartoon/ispc/renderer/ContoursRenderer.cpp
    cartoon/ispc/renderer/CartoonRenderer.cpp
    cartoon/cartoon.cpp
    simulation/simulation.cpp
    simulation/ispc/renderer/TransparencyRenderer.cpp
)

set(${NAME}_ISPC_SOURCES
    common/ispc/renderer/SkyBox.ispc
    common/ispc/renderer/ExtendedOBJMaterial.ispc
    common/ispc/renderer/Glsl.ispc
    common/ispc/renderer/RandomGenerator.ispc
    holography/ispc/camera/HolographicCamera.ispc
    pathtracing/ispc/renderer/PathTracingRenderer.ispc
    volume/ispc/renderer/VolumeRenderer.ispc
    raymarching/ispc/renderer/DistanceEstimatorRenderer.ispc
    fractals/ispc/renderer/FractalsRenderer.ispc
    fractals/ispc/renderer/VoxelizerRenderer.ispc
    fractals/ispc/renderer/MengerSpongeRenderer.ispc
#    pbr/ispc/renderer/PbrRenderer.ispc
    cartoon/ispc/renderer/CartoonRenderer.ispc
    cartoon/ispc/renderer/ContoursRenderer.ispc
    simulation/ispc/renderer/TransparencyRenderer.ispc
)

# Compile ispc code
list(APPEND CMAKE_MODULE_PATH ${OSPRAY_CMAKE_ROOT})
list(APPEND ALL_ISPC_INCLUDES ${BRAYNS_RESEARCH_MODULES_DIR})
list(APPEND ALL_ISPC_INCLUDES ${OSPRAY_INCLUDE_DIRS})
include_directories_ispc(${ALL_ISPC_INCLUDES})
ospray_ispc_compile(${${NAME}_ISPC_SOURCES})
list(APPEND ${NAME}_SOURCES ${ISPC_OBJECTS})

# Compile C++ code
include_directories(${BRAYNS_RESEARCH_MODULES_DIR} ${OSPRAY_INCLUDE_DIRS})
set(${NAME}_LINK_LIBRARIES
    PUBLIC ${OSPRAY_LIBRARIES}
    PRIVATE braynsOSPRayEngine braynsPluginAPI
)
add_library(${LIBRARY_NAME} SHARED ${${NAME}_SOURCES})
target_link_libraries(${LIBRARY_NAME} ${${NAME}_LINK_LIBRARIES})

# Installation
install(TARGETS ${LIBRARY_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
