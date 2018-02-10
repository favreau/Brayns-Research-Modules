# Copyright (c) 2018, EPFL/Blue Brain Project
# All rights reserved. Do not distribute without permission.
# Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
#
# This file is part of https://github.com/favreau/research-brayns-module

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake)
set(RESEARCH_BRAYNS_MODULE_DIR ${PROJECT_SOURCE_DIR})

# C++ 11
add_compile_options(-std=c++11)

# OSPRay
find_package(ospray REQUIRED SYSTEM)
include(ispc)

# Add modules
add_subdirectory(common)
add_subdirectory(simulation)
add_subdirectory(cartoon)
add_subdirectory(opendeck)
add_subdirectory(volume)