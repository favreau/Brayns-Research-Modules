/* Copyright (c) 2018, Cyrille Favreau
 * All rights reserved. Do not distribute without permission.
 * Responsible Author: Cyrille Favreau <cyrille.favreau@gmail.com>
 *
 * This file is part of the reseach Brayns module
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

#include <common/ispc/renderer/AbstractRenderer.ih>

const unsigned int GRADIENT_SIZE = 4;

/**
 * @brief Encapsulate the various inputs used by the various functions in the
 * shading equation. We store values in this struct to simplify the integration
 * of alternative implementations of the shading terms.
 */
struct PBRInfo
{
    float NdotL; // cos angle between normal and light direction
    float NdotV; // cos angle between normal and view direction
    float NdotH; // cos angle between normal and half vector
    float LdotH; // cos angle between light direction and half vector
    float VdotH; // cos angle between view direction and half vector
    float perceptualRoughness; // roughness value, as authored by the model
                               // creator (input to shader)
    float metalness;           // metallic value at the surface
    vec3f reflectance0;   // full reflectance color (normal incidence angle)
    vec3f reflectance90;  // reflectance color at grazing angle
    float alphaRoughness; // roughness mapped to a more linear change in the
                          // roughness (proposed by [2])
    vec3f diffuseColor;   // color contribution from diffuse lighting
    vec3f specularColor;  // color contribution from specular lighting
};

struct PbrRenderer
{
    AbstractRenderer abstract;
};

inline vec3f mix(const vec3f x, const vec3f y, const float a)
{
    return x * (1.f - a) + y * a;
}

inline vec3f diffuse(const PBRInfo& pbrInputs)
{
    return pbrInputs.diffuseColor / M_PI;
}

inline vec3f specularReflection(const PBRInfo& pbrInputs)
{
    return pbrInputs.reflectance0 +
           (pbrInputs.reflectance90 - pbrInputs.reflectance0) *
               pow(clamp(1.0 - pbrInputs.VdotH, 0.0, 1.0), 5.0);
}

inline float geometricOcclusion(const PBRInfo& pbrInputs)
{
    float NdotL = pbrInputs.NdotL;
    float NdotV = pbrInputs.NdotV;
    float r = pbrInputs.alphaRoughness;

    float attenuationL =
        2.f * NdotL / (NdotL + sqrt(r * r + (1.f - r * r) * (NdotL * NdotL)));
    float attenuationV =
        2.f * NdotV / (NdotV + sqrt(r * r + (1.f - r * r) * (NdotV * NdotV)));
    return attenuationL * attenuationV;
}

inline float microfacetDistribution(const PBRInfo& pbrInputs)
{
    float roughnessSq = pbrInputs.alphaRoughness * pbrInputs.alphaRoughness;
    float f =
        (pbrInputs.NdotH * roughnessSq - pbrInputs.NdotH) * pbrInputs.NdotH +
        1.f;
    return roughnessSq / (M_PI * f * f);
}

void processMetallicRoughness(const float metallic, vec3f& diffuseColor,
                              vec3f& specularColor, float& specularExponent,
                              float& reflection)
{
    vec3f f0 = make_vec3f(0.04f);
    diffuseColor = diffuseColor * (make_vec3f(1.f) - f0);
    diffuseColor = diffuseColor * (1.f - metallic);

    specularColor = mix(f0, diffuseColor, metallic);
    specularExponent = 10.f;

    reflection = max(max(specularColor.x, specularColor.y), specularColor.z);
}

vec3f reflectedVector(const vec3f& incident, const vec3f& normal)
{
    return incident - 2.f * dot(incident, normal) * normal;
}

void processMetallicRoughness(const vec3f& normal, const vec3f& surfaceToCamera,
                              const vec3f& surfaceToLight,
                              const vec4f& baseColor, const float roughness,
                              const float metallic, vec3f& diffuseColor,
                              vec3f& specularColor, float& specularExponent,
                              float& reflection, vec3f& reflected)
{
    // Uniforms
    const vec4f u_ScaleDiffBaseMR = make_vec4f(0.f);
    const vec4f u_ScaleFGDSpec = make_vec4f(0.f);
    const vec3f u_LightColor = make_vec3f(1.0f, 0.8f, 0.5f) * 2.0f;
    const float u_exponent = 1.f / 2.2f;

    // For typical incident reflectance range (between 4% to 100%) set the
    // grazing reflectance to 100% for typical fresnel effect. For very low
    // reflectance range on highly diffuse objects (below 4%), incrementally
    // reduce grazing reflecance to 0%.

    vec3f f0 = make_vec3f(0.04f);
    diffuseColor = make_vec3f(baseColor) * (make_vec3f(1.f) - f0);
    diffuseColor = diffuseColor * (1.f - metallic);
    specularColor = mix(f0, make_vec3f(baseColor), metallic);

    specularExponent = 10.f;

    // Compute reflectance
    const float reflectance =
        max(max(specularColor.x, specularColor.y), specularColor.z);

    const float alphaRoughness = roughness * roughness;
    const float reflectance90 = clamp(reflectance * 25.f, 0.f, 1.f);

    const vec3f specularEnvironmentR0 = specularColor;
    const vec3f specularEnvironmentR90 = make_vec3f(1.f) * reflectance90;

    const vec3f h = normalize(surfaceToLight + surfaceToCamera);
    const float NdotL = clamp(dot(normal, surfaceToLight), 0.001f, 1.f);
    const float NdotV = abs(dot(normal, surfaceToCamera)) + 0.001f;
    const float NdotH = clamp(dot(normal, h), 0.f, 1.f);
    const float LdotH = clamp(dot(surfaceToLight, h), 0.f, 1.f);
    const float VdotH = clamp(dot(surfaceToCamera, h), 0.f, 1.f);

    reflected = neg(normalize(reflectedVector(surfaceToCamera, normal)));

    PBRInfo pbrInputs = {NdotL,
                         NdotV,
                         NdotH,
                         LdotH,
                         VdotH,
                         roughness,
                         metallic,
                         specularEnvironmentR0,
                         specularEnvironmentR90,
                         alphaRoughness,
                         diffuseColor,
                         specularColor};

    // Calculate the shading terms for the microfacet specular shading model
    const vec3f F = specularReflection(pbrInputs);
    const float G = geometricOcclusion(pbrInputs);
    const float D = microfacetDistribution(pbrInputs);

    // Calculation of analytical lighting contribution
    const vec3f diffuseContrib = (1.f - F) * diffuse(pbrInputs);
    const vec3f specContrib = F * G * D / (4.f * NdotL * NdotV);

    // Obtain final intensity as reflectance (BRDF) scaled by the energy of the
    // light (cosine law)
    vec3f color = NdotL * u_LightColor * (diffuseContrib + specContrib);

    // This section uses mix to override final color for reference app
    // visualization of various parameters in the lighting equation.
    color = mix(color, F, u_ScaleFGDSpec.x);
    color = mix(color, make_vec3f(G), u_ScaleFGDSpec.y);
    color = mix(color, make_vec3f(D), u_ScaleFGDSpec.z);
    color = mix(color, specContrib, u_ScaleFGDSpec.w);

    color = mix(color, diffuseContrib, u_ScaleDiffBaseMR.x);
    color = mix(color, make_vec3f(baseColor), u_ScaleDiffBaseMR.y);
    color = mix(color, make_vec3f(metallic), u_ScaleDiffBaseMR.z);
    color = mix(color, make_vec3f(roughness), u_ScaleDiffBaseMR.w);

    diffuseColor =
        make_vec3f(pow(color.x, u_exponent), pow(color.y, u_exponent),
                   pow(color.z, u_exponent));
}

/**
    Renderer a pixel color according to a given location in the screen space.
    @param self Pointer to current renderer
    @param sample Screen sample containing information about the ray, and the
           location in the screen space.
*/
inline vec3f PbrRenderer_shadeRay(const uniform PbrRenderer* uniform self,
                                  varying ScreenSample& sample)
{
    Ray ray = sample.ray;
    varying vec3f color = make_vec3f(0.f);

    sample.z = inf;
    sample.alpha = 0.f;

    traceRay(self->abstract.super.model, ray);

    RTCScene data = (RTCScene)self->abstract.super.model->embreeSceneHandle;
    void* d = rtcGetUserData(data, 0);

    if (ray.geomID < 0)
    {
        // No intersection. Return skybox color
        color = make_vec3f(
            skyboxMapping((Renderer*)self, ray, self->abstract.bgMaterial));
        sample.alpha = 0.f;
        return color;
    }

    DifferentialGeometry dg;
    postIntersect(self->abstract.super.model, dg, ray,
                  DG_NS | DG_NG | DG_NORMALIZE | DG_FACEFORWARD |
                      DG_MATERIALID | DG_COLOR);

    uniform Material* material = dg.material;
    uniform ExtendedOBJMaterial* objMaterial =
        (uniform ExtendedOBJMaterial*)material;

    // Light direction
    const vec3f intersection = dg.P + self->abstract.super.epsilon * dg.Ns;
    const vec3f headLight = normalize(ray.org - intersection);
    const vec3f normal = dg.Ns;
    vec3f diffuseColor = make_vec3f(0.f);

    if (!objMaterial)
        diffuseColor = make_vec3f(dg.color);
    else
        foreach_unique(mat in objMaterial)
        {
            // Diffuse color and opacity
            diffuseColor = mat->diffuse * make_vec3f(dg.color);
            float opacity = mat->opacity;
            if (valid(mat->map_diffuse))
            {
                const vec4f diffuseFromMap = get4f(mat->map_diffuse, dg.st);
                diffuseColor = diffuseColor * make_vec3f(diffuseFromMap);
                opacity *= diffuseFromMap.w;
            }

            // Shininess
            float shininess = 0.f;
            if (valid(mat->map_shininess))
                shininess = mat->shininess * get1f(mat->map_shininess, dg.st);

            // Specular color
            vec3f specularColor = make_vec3f(0.f);
            if (shininess > 0.f)
            {
                specularColor = mat->specular;
                if (valid(mat->map_specular))
                    specularColor =
                        mat->specular * get3f(mat->map_specular, dg.st);
            }

            // Reflection index
            float reflection = mat->refraction;
            if (valid(mat->map_reflection))
                reflection =
                    mat->reflection * get1f(mat->map_reflection, dg.st);

            // Metallic roughness
            if (valid(mat->map_metal) && self->abstract.shadingEnabled)
            {
                const vec4f value = get4f(mat->map_metal, dg.st);
                const float roughness = value.y * mat->pbrRoughnessFactor;
                const float metallic = value.z * mat->pbrMetallicFactor;

                if (self->abstract.shadows == 0.f)
                    processMetallicRoughness(metallic, diffuseColor,
                                             specularColor, shininess,
                                             reflection);
                else
                {
                    const vec3f surfaceToCamera =
                        normalize(intersection - ray.org);

                    // TODO: Fix vector to light
                    const vec3f surfaceToLight =
                        normalize(ray.org - intersection);

                    const vec4f baseColor = make_vec4f(diffuseColor, opacity) *
                                            mat->pbrBaseColorFactor;

                    vec3f reflectedNormal;
                    processMetallicRoughness(normal, surfaceToCamera, headLight,
                                             baseColor, roughness, metallic,
                                             diffuseColor, specularColor,
                                             shininess, reflection,
                                             reflectedNormal);
                }
            }
        }

    // Head-light Pbr shading
    const float angle = max(0.f, dot(headLight, normal));
    color = diffuseColor * angle;
    sample.alpha = 1.f;

    // Z-Depth
    sample.z = ray.t;
    sample.alpha = 1.f;

    return color;
}

void PbrRenderer_renderSample(uniform Renderer* uniform _self,
                              void* uniform perFrameData,
                              varying ScreenSample& sample)
{
    uniform PbrRenderer* uniform self = (uniform PbrRenderer * uniform)_self;
    sample.ray.time = self->abstract.timestamp;
    sample.rgb = PbrRenderer_shadeRay(self, sample);
}

// Exports (called from C++)
export void* uniform PbrRenderer_create(void* uniform cppE)
{
    uniform PbrRenderer* uniform self = uniform new uniform PbrRenderer;
    Renderer_Constructor(&self->abstract.super, cppE);
    self->abstract.super.renderSample = PbrRenderer_renderSample;
    return self;
}

export void PbrRenderer_set(void* uniform _self, void* uniform bgMaterial,
                            const uniform float& timestamp,
                            const uniform int& spp, void** uniform lights,
                            uniform int32 numLights)
{
    uniform PbrRenderer* uniform self = (uniform PbrRenderer * uniform)_self;

    self->abstract.bgMaterial =
        (uniform ExtendedOBJMaterial * uniform)bgMaterial;

    self->abstract.timestamp = timestamp;
    self->abstract.spp = spp;

    self->abstract.lights = (const uniform Light* uniform* uniform)lights;
    self->abstract.numLights = numLights;
}
