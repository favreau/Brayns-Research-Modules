cmake_minimum_required(VERSION 3.1 FATAL_ERROR)
set(PLUGIN_NAME braynsResearchModulesPlugin)
project(${PLUGIN_NAME} VERSION 1.0.0)
set(${PLUGIN_NAME}_VERSION_ABI 1)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(${PLUGIN_NAME}_SOURCES
  api/ResearchModulesParams.cpp
  oi/EEGHandler.cpp
  BraynsResearchModulesPlugin.cpp
)

set(${PLUGIN_NAME}_PUBLIC_HEADERS
  BraynsResearchModulesPlugin.h
)

set(${PLUGIN_NAME}_LINK_LIBRARIES braynsPluginAPI)

# Compile C++ code
include_directories(${${PLUGIN_NAME}_DIR} ${OSPRAY_INCLUDE_DIRS})
set(PLUGIN_LINK_LIBRARIES PUBLIC ${OSPRAY_LIBRARIES})
add_library(${PLUGIN_NAME} SHARED ${${PLUGIN_NAME}_SOURCES})
target_link_libraries(${PLUGIN_NAME} ${PLUGIN_LINK_LIBRARIES})

# Installation
install(TARGETS ${PLUGIN_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
