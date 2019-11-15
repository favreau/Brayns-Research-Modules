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

#include "BraynsResearchModulesPlugin.h"
#include "log.h"

#include <brayns/engine/Engine.h>
#include <brayns/pluginapi/PluginAPI.h>

void _addClippingCamera(brayns::Engine& engine)
{
    PLUGIN_INFO << "Registering sphere clipping perspective camera"
                << std::endl;

    brayns::PropertyMap properties;
    properties.setProperty({"fovy", 45., .1, 360., {"Field of view"}});
    properties.setProperty({"aspect", 1., {"Aspect ratio"}});
    properties.setProperty({"apertureRadius", 0., {"Aperture radius"}});
    properties.setProperty({"focusDistance", 1., {"Focus Distance"}});
    properties.setProperty({"enableClippingPlanes", true, {"Clipping"}});
    engine.addCameraType("circuit_explorer_sphere_clipping", properties);
}

void _addFractalsRenderer(brayns::Engine& engine)
{
    PLUGIN_INFO << "Registering fratals renderer" << std::endl;
    brayns::PropertyMap properties;
    properties.setProperty({"shadows", 0., 0., 1., {"Shadow intensity"}});
    properties.setProperty({"softShadows", 0., 0., 1., {"Shadow softness"}});
    properties.setProperty({"samplesPerRay", 64, 0, 128, {"Samples per ray"}});
    properties.setProperty(
        {"maxIterations", 64, 1, 128, {"Number of iterations"}});
    properties.setProperty({"julia", true, {"Mandelbrot vs Julia"}});
    properties.setProperty({"threshold", 0.1, 0., 1., {"Threshold"}});
    properties.setProperty({"re", -0.7, -2., 2., {"re"}});
    properties.setProperty({"im", 0.27015, -2., 2., {"im"}});
    engine.addRendererType("research_fractals", properties);
}

void _addMergerSpongeRenderer(brayns::Engine& engine)
{
    PLUGIN_INFO << "Registering Menger Sponge renderer" << std::endl;
    brayns::PropertyMap properties;
    properties.setProperty({"samplesPerRay", 64, 0, 128, {"Samples per ray"}});
    properties.setProperty({"shadows", 0., 0., 1., {"Shadow intensity"}});
    properties.setProperty({"softShadows", 0., 0., 1., {"Shadow softness"}});
    properties.setProperty(
        {"nbIterations", 4, 1, 10, {"Number of iterations"}});
    engine.addRendererType("research_menger_sponge", properties);
}

void _addVoxelizerRenderer(brayns::Engine& engine)
{
    PLUGIN_INFO << "Registering Voxelizer renderer" << std::endl;
    brayns::PropertyMap properties;
    properties.setProperty({"softnessEnabled", false, {"Softness"}});
    properties.setProperty({"shadingEnabled", false, {"Shading"}});
    properties.setProperty({"exposure", 1., 1., 10., {"Exposure"}});
    properties.setProperty({"shadows", 0., 0., 1., {"Shadow intensity"}});
    properties.setProperty({"softShadows", 0., 0., 1., {"Shadow softness"}});
    properties.setProperty({"samplesPerRay", 16, 4, 1024, {"Samples per ray"}});
    properties.setProperty(
        {"samplesPerShadowRay", 4, 4, 1024, {"Samples per shadow ray"}});
    properties.setProperty({"pixelOpacity", 1.0, 0.01, 1.0, {"Pixel opacity"}});
    properties.setProperty({"divider", 20000.0, 1.0, 50000.0, {"Divider"}});
    engine.addRendererType("research_voxelizer", properties);
}

void _addCartoonRenderer(brayns::Engine& engine)
{
    PLUGIN_INFO << "Registering Cartoon renderer" << std::endl;
    brayns::PropertyMap properties;
    engine.addRendererType("research_cartoon", properties);
}

void _addContoursRenderer(brayns::Engine& engine)
{
    PLUGIN_INFO << "Registering Contours renderer" << std::endl;
    brayns::PropertyMap properties;
    engine.addRendererType("research_contours", properties);
}

void _addPathTracingRenderer(brayns::Engine& engine)
{
    PLUGIN_INFO << "Registering Path Tracing renderer" << std::endl;
    brayns::PropertyMap properties;
    engine.addRendererType("research_path_tracing", properties);
}

void _addPBRRenderer(brayns::Engine& engine)
{
    PLUGIN_INFO << "Registering PBR renderer" << std::endl;
    brayns::PropertyMap properties;
    engine.addRendererType("research_pbr", properties);
}

BraynsResearchModulesPlugin::BraynsResearchModulesPlugin()
    : ExtensionPlugin()
{
}

void BraynsResearchModulesPlugin::init()
{
    auto& engine = _api->getEngine();
    _addFractalsRenderer(engine);
    _addMergerSpongeRenderer(engine);
    _addVoxelizerRenderer(engine);
    _addCartoonRenderer(engine);
    _addContoursRenderer(engine);
    _addPathTracingRenderer(engine);
    //    _addPBRRenderer(engine);
    _addClippingCamera(engine);
}

extern "C" brayns::ExtensionPlugin* brayns_plugin_create(int /*argc*/,
                                                         char** /*argv*/)
{
    PLUGIN_INFO << "Initializing Brayns research modules plugin" << std::endl;
    return new BraynsResearchModulesPlugin();
}
