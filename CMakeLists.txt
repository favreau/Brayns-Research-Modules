# Copyright (c) 2018, Cyrille Favreau
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
#
# This file is part of https://github.com/favreau/Brayns-Research-Modules

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake)
set(BRAYNS_RESEARCH_MODULES_DIR ${PROJECT_SOURCE_DIR})

# C++ 11
add_compile_options(-std=c++11 -fPIC)

# OSPRay
find_package(ospray REQUIRED SYSTEM)
include(ispc)

# Add modules
add_subdirectory(plugin)
add_subdirectory(common)
add_subdirectory(cartoon)
add_subdirectory(clipping)
add_subdirectory(fractals)
add_subdirectory(simulation)
add_subdirectory(volume)
add_subdirectory(raymarching)
add_subdirectory(pathtracing)
#add_subdirectory(pbr)
add_subdirectory(holography)
add_subdirectory(subsurfacescattering)
