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

#include "ExtendedOBJMaterial.h"
#include "ExtendedOBJMaterial_ispc.h"
#include <ospray/SDK/common/Data.h>

#define OSP_REGISTER_EXMATERIAL(InternalClassName, external_name)          \
    extern "C" ospray::Material *ospray_create_material__##external_name() \
    {                                                                      \
        return new InternalClassName;                                      \
    }

namespace brayns
{
namespace obj
{
void ExtendedOBJMaterial::commit()
{
    if (ispcEquivalent == nullptr)
        ispcEquivalent = ispc::ExtendedOBJMaterial_create(this);

    // Opacity
    map_opacity = (ospray::Texture2D *)getParamObject("opacity", nullptr);
    xform_opacity = getTextureTransform("opacity");
    opacity = getParam1f("opacity", 1.f);

    // Diffuse color
    diffuse = getParam3f("diffuse", ospray::vec3f(.8f));
    map_diffuse = (ospray::Texture2D *)getParamObject("map_diffuse", nullptr);
    xform_diffuse = getTextureTransform("map_diffuse");

    // Specular color
    specular = getParam3f("specular", ospray::vec3f(0.f));
    map_specular = (ospray::Texture2D *)getParamObject("map_ks", nullptr);
    xform_specular = getTextureTransform("map_ks");

    // Light emission
    emission = getParam1f("emission", 0.f);
    xform_emission = getTextureTransform("map_emission");
    map_emission = (ospray::Texture2D *)getParamObject("map_emission", nullptr);

    // Shininess
    shininess = getParam1f("shininess", 10.f);
    map_shininess =
        (ospray::Texture2D *)getParamObject("map_shininess", nullptr);
    xform_shininess = getTextureTransform("map_shininess");

    // Normals
    map_normals = (ospray::Texture2D *)getParamObject("map_normals", nullptr);
    xform_normals = getTextureTransform("map_normals");
    rot_normals = xform_normals.l.orthogonal().transposed();

    // Reflection
    reflection = getParam1f("reflection", 0.f);
    xform_reflection = getTextureTransform("map_reflection");
    map_reflection =
        (ospray::Texture2D *)getParamObject("map_reflection", nullptr);

    // Metallic roughness
    map_metal =
        (ospray::Texture2D *)getParamObject("map_metallic_roughness", nullptr);
    xform_metal = getTextureTransform("map_metallic_roughness");

    // Refraction
    refraction = getParam1f("refraction", 0.f);

    // Glossiness
    glossiness = getParam1f("glossiness", 1.f);

    // Cast simulation data
    castSimulationData = getParam1i("cast_simulation_data", true);

    // PBR attributes
    pbrBaseColorFactor =
        getParam4f("pbr_base_color_factor", ospray::vec4f(0.f));
    pbrMetallicFactor = getParam1f("pbr_metallic_factor", 0.f);
    pbrRoughnessFactor = getParam1f("pbr_roughness_factor", 0.f);

    ispc::ExtendedOBJMaterial_set(
        getIE(), map_opacity ? map_opacity->getIE() : nullptr,
        (const ispc::AffineSpace2f &)xform_opacity, opacity, refraction,
        map_reflection ? map_reflection->getIE() : nullptr,
        (const ispc::AffineSpace2f &)xform_reflection, reflection,
        map_emission ? map_emission->getIE() : nullptr,
        (const ispc::AffineSpace2f &)xform_emission, emission, glossiness,
        castSimulationData, map_diffuse ? map_diffuse->getIE() : nullptr,
        (const ispc::AffineSpace2f &)xform_diffuse, (ispc::vec3f &)diffuse,
        map_specular ? map_specular->getIE() : nullptr,
        (const ispc::AffineSpace2f &)xform_specular, (ispc::vec3f &)specular,
        map_shininess ? map_shininess->getIE() : nullptr,
        (const ispc::AffineSpace2f &)xform_shininess, shininess,
        map_normals ? map_normals->getIE() : nullptr,
        (const ispc::AffineSpace2f &)xform_normals,
        (const ispc::LinearSpace2f &)rot_normals,
        map_metal ? map_metal->getIE() : nullptr,
        (const ispc::AffineSpace2f &)xform_metal,
        (ispc::vec4f &)pbrBaseColorFactor, pbrMetallicFactor,
        pbrRoughnessFactor);
}

OSP_REGISTER_EXMATERIAL(ExtendedOBJMaterial, ExtendedOBJMaterial);
} // ::brayns::obj
} // ::brayns
