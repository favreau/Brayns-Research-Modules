/* Copyright (c) 2015-2016, EPFL/Blue Brain Project
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@epfl.ch>
 *
 * Based on OSPRay implementation
 *
 * This file is part of Brayns <https://github.com/BlueBrain/Brayns>
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

#pragma once

#include <ospray/SDK/common/Material.h>
#include <ospray/SDK/texture/Texture2D.h>

namespace brayns
{
namespace obj
{
typedef ospray::vec3f Color;

struct ExtendedOBJMaterial : public ospray::Material
{
    // Opacity
    ospray::Texture2D *map_opacity;
    ospray::affine2f xform_opacity;
    float opacity;

    /*! refraction index */
    float refraction;

    /*! reflection index */
    ospray::Texture2D *map_reflection;
    ospray::affine2f xform_reflection;
    float reflection;

    // Ambient
    ospray::Texture2D *map_ambient;
    ospray::affine2f xform_ambient;
    float ambient;

    // Diffuse (Kd)
    ospray::Texture2D *map_diffuse;
    ospray::affine2f xform_diffuse;
    Color diffuse;

    // Specular (Ks)
    ospray::Texture2D *map_specular;
    ospray::affine2f xform_specular;
    Color specular;

    // Shininess (specular exponent) Ns
    ospray::Texture2D *map_shininess;
    ospray::affine2f xform_shininess;
    float shininess;

    // Emission
    ospray::Texture2D *map_emission;
    ospray::affine2f xform_emission;
    float emission;

    // Glossiness
    float glossiness;

    // Normals
    ospray::Texture2D *map_normals;
    ospray::affine2f xform_normals;
    ospray::linear2f rot_normals;

    // Metallic roughness
    ospray::Texture2D *map_metal;
    ospray::affine2f xform_metal;
    ospray::linear2f rot_metal;

    // Casts simulation data
    bool castSimulationData;

    // PBR attributes
    ospray::vec4f pbrBaseColorFactor;
    float pbrMetallicFactor;
    float pbrRoughnessFactor;

    std::string toString() const final
    {
        return "brayns::extendedobjrenderer::ExtendedOBJMaterial";
    }

    void commit() final;
};

} // ::brayns::obj
} // ::brayns
