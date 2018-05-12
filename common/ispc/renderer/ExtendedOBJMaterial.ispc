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

#include "ExtendedOBJMaterial.ih"

export void *uniform ExtendedOBJMaterial_create(void *uniform cppE)
{
    uniform ExtendedOBJMaterial *uniform mat =
        uniform new uniform ExtendedOBJMaterial;
    mat->super.cppEquivalent = cppE;
    return mat;
}

export void ExtendedOBJMaterial_set(
    void *uniform _mat, const void *uniform map_opacity,
    const uniform affine2f &xform_opacity, const uniform float &opacity,
    const uniform float &refraction, const void *uniform map_reflection,
    const uniform affine2f &xform_reflection, const uniform float &reflection,
    const void *uniform map_emission, const uniform affine2f &xform_emission,
    const uniform float &emission, const uniform float &glossiness,
    const uniform bool &castSimulationData, const void *uniform map_diffuse,
    const uniform affine2f &xform_diffuse, const uniform vec3f &diffuse,
    const void *uniform map_specular, const uniform affine2f &xform_specular,
    const uniform vec3f &specular, const void *uniform map_shininess,
    const uniform affine2f &xform_shininess, const uniform float &shininess,
    const void *uniform map_normals, const uniform affine2f &xform_normals,
    const uniform linear2f &rot_normals, const void *uniform map_metal,
    const uniform affine2f &xform_metal,
    const uniform vec4f &pbrBaseColorFactor,
    const uniform float &pbrMetallicFactor,
    const uniform float &pbrRoughnessFactor)
{
    uniform ExtendedOBJMaterial *uniform self =
        (uniform ExtendedOBJMaterial * uniform)_mat;

    self->map_opacity =
        make_TextureParam((Texture2D *)map_opacity, xform_opacity);
    self->opacity = opacity;

    self->refraction = refraction;

    self->map_reflection =
        make_TextureParam((Texture2D *)map_reflection, xform_reflection);
    self->reflection = reflection;

    self->map_emission =
        make_TextureParam((Texture2D *)map_emission, xform_emission);
    self->emission = emission;

    self->map_diffuse =
        make_TextureParam((Texture2D *)map_diffuse, xform_diffuse);
    self->diffuse = diffuse;

    self->map_specular =
        make_TextureParam((Texture2D *)map_specular, xform_specular);
    self->specular = specular;

    self->map_shininess =
        make_TextureParam((Texture2D *)map_shininess, xform_shininess);
    self->shininess = shininess;

    self->map_normals =
        make_TextureParam((Texture2D *)map_normals, xform_normals);
    self->rot_normals = rot_normals;

    self->map_metal = make_TextureParam((Texture2D *)map_metal, xform_metal);

    self->glossiness = glossiness;

    self->castSimulationData = castSimulationData;

    // PBR attributes
    self->pbrBaseColorFactor = pbrBaseColorFactor;
    self->pbrMetallicFactor = pbrMetallicFactor;
    self->pbrRoughnessFactor = pbrRoughnessFactor;
}
