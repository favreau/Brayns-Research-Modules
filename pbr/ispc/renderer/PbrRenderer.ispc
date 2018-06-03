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
#include <common/ispc/renderer/Glsl.ih>

struct PbrRenderer
{
    AbstractRenderer abstract;
};

inline vec3f mix(const vec3f& x, const vec3f& y, const vec3f& a)
{
    return x * (1.f - a) + y * a;
}

#if 1
inline vec3f step(const vec3f& edge, const vec3f& x)
{
    return make_vec3f(x.x < edge.x ? 0.f : 1.f, x.y < edge.y ? 0.f : 1.f,
                      x.z < edge.z ? 0.f : 1.f);
}

inline vec4f SRGBtoLINEAR(const vec4f& srgbIn)
{
    const vec3f srgb = make_vec3f(srgbIn);
    const vec3f a = make_vec3f(0.04045f);
    vec3f bLess = step(a, srgb);
    const vec3f b = (srgb + make_vec3f(0.055f)) / make_vec3f(1.055f);
    const vec3f c = srgb / make_vec3f(12.92f);
    const vec3f d = make_vec3f(pow(b.x, 2.4f), pow(b.y, 2.4f), pow(b.z, 2.4f));
    vec3f linOut = mix(c, d, bLess);
    return make_vec4f(linOut, srgbIn.w);
}
#endif

// This G term is used in glTF-WebGL-PBR Microfacet Models for Refraction
// through Rough Surfaces
inline float G1_GGX(const float alphaSq, const float NoX)
{
    float tanSq = (1.f - NoX * NoX) / max((NoX * NoX), 0.00001f);
    return 2.f / (1.f + sqrt(1.f + alphaSq * tanSq));
}

// 1 / (1 + delta(l)) * 1 / (1 + delta(v))
inline float Smith_G(const float alphaSq, const float NoL, const float NoV)
{
    return G1_GGX(alphaSq, NoL) * G1_GGX(alphaSq, NoV);
}

// Height-Correlated Masking and Shadowing
// Smith Joint Masking-Shadowing Function
inline float GGX_Delta(const float alphaSq, const float NoX)
{
    return (-1.f + sqrt(1.f + alphaSq * (1.f / (NoX * NoX) - 1.f))) / 2.f;
}

inline float SmithJoint_G(const float alphaSq, const float NoL, const float NoV)
{
    return 1.f / (1.f + GGX_Delta(alphaSq, NoL) + GGX_Delta(alphaSq, NoV));
}

inline float GGX_D(const float alphaSq, const float NoH)
{
    float c = (NoH * NoH * (alphaSq - 1.f) + 1.f);
    return alphaSq / (c * c) / PI;
}

inline void BRDF(const vec3f L, const vec3f V, const vec3f N,
                 const vec3f& baseColor, const float metallic,
                 const float roughness, vec3f& diffuse, vec3f& specular)
{
    const vec3f dielectricSpecular = make_vec3f(0.04f);
    const vec3f BLACK = make_vec3f(0.f);

    const vec3f H = normalize(L + V);

    float NoH = dot(N, H);
    float VoH = dot(V, H);
    float NoL = dot(N, L);
    float NoV = dot(N, V);

    const vec3f F0 = mix(dielectricSpecular, baseColor, make_vec3f(metallic));
    const vec3f cDiff = mix(baseColor * (1.f - dielectricSpecular.x), BLACK,
                            make_vec3f(metallic));
    float alpha = roughness * roughness;
    float alphaSq = alpha * alpha;

    // Schlick's approximation
    const vec3f F = F0 + (make_vec3f(1.f) - F0) * pow((1.f - VoH), 5.f);

    diffuse = clamp((make_vec3f(1.f) - F) * (cDiff / PI), make_vec3f(0.f),
                    make_vec3f(1.f));

    const float G = SmithJoint_G(alphaSq, NoL, NoV);
    const float D = GGX_D(alphaSq, NoH);

    specular = clamp((F * G * D) / (4.f * NoL * NoV), make_vec3f(0.f),
                     make_vec3f(1.f));
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
    vec3f color = make_vec3f(0.f);

    sample.z = inf;
    sample.alpha = 0.f;
    int depth = 0;
    float pathOpacity = 1.f;
    float oldRefraction = 1.f;

    while (depth < NB_MAX_REBOUNDS && pathOpacity > 0.f)
    {
        traceRay(self->abstract.super.model, ray);

        if (ray.geomID < 0)
        {
            // No intersection. Return skybox color
            color = color * (1.f - pathOpacity) +
                    pathOpacity *
                        make_vec3f(skyboxMapping((Renderer*)self, ray,
                                                 self->abstract.bgMaterial));

            sample.z = inf;
            sample.alpha = 0.f;
            break;
        }
        if (depth == 0)
            sample.z = ray.t;

        DifferentialGeometry dg;
        postIntersect(self->abstract.super.model, dg, ray,
                      DG_NG | DG_NS | DG_NORMALIZE | DG_FACEFORWARD |
                          DG_TANGENTS | DG_MATERIALID | DG_COLOR | DG_TEXCOORD);

        uniform Material* material = dg.material;
        uniform ExtendedOBJMaterial* objMaterial =
            (uniform ExtendedOBJMaterial*)material;

        const vec3f intersection = dg.P;
        const vec3f headLight = normalize(intersection - ray.org);
        const vec3f normal = dg.Ns;
        vec3f diffuseColor = make_vec3f(0.f);
        vec3f specularColor = make_vec3f(0.f);
        float shininess = 0.f;

        float refraction = 1.f;
        float reflection = 0.f;
        float opacity = 1.f;
        float cosNL = 1.f;

        if (!objMaterial)
        {
            diffuseColor = make_vec3f(dg.color);
            opacity = dg.color.w;
        }
        else
            foreach_unique(mat in objMaterial)
            {
                // Diffuse color and opacity
                diffuseColor = make_vec3f(dg.color) * mat->diffuse;
                opacity *= mat->opacity;
                if (valid(mat->map_diffuse))
                {
                    const vec4f diffuseFromMap = get4f(mat->map_diffuse, dg.st);
                    diffuseColor = diffuseColor * make_vec3f(diffuseFromMap);
                    opacity *= diffuseFromMap.w;
                }
                // Shininess
                shininess = mat->shininess;
                if (valid(mat->map_shininess))
                    shininess *= get1f(mat->map_shininess, dg.st);

                // Specular color
                if (shininess > 0.f)
                {
                    specularColor = mat->specular;
                    if (valid(mat->map_specular))
                        specularColor =
                            specularColor * get3f(mat->map_specular, dg.st);
                }

                // Reflection index
                reflection = mat->reflection;
                if (valid(mat->map_reflection))
                    reflection *= get1f(mat->map_reflection, dg.st);

                // Refraction
                refraction = mat->refraction;

                // Metallic roughness
                if (valid(mat->map_metal))
                {
                    const vec4f value = get4f(mat->map_metal, dg.st);
                    const float roughnessFactor =
                        value.y * mat->pbrRoughnessFactor;
                    const float metallicFactor =
                        value.z * mat->pbrMetallicFactor;

                    const vec3f eyeToSurface =
                        normalize(intersection - sample.ray.org);

                    const vec3f baseColor =
                        make_vec3f(get4f(mat->map_diffuse, dg.st) *
                                   mat->pbrBaseColorFactor);

                    BRDF(headLight, eyeToSurface, normal, baseColor,
                         metallicFactor, roughnessFactor, diffuseColor,
                         specularColor);

                    reflection = max(max(specularColor.x, specularColor.y),
                                     specularColor.z);
                }
                else
                    cosNL = max(0.f, dot(headLight, normal));

                // Light emission intensity
                if (valid(mat->map_emission))
                {
                    const vec4f value = get4f(mat->map_emission, dg.st);
                    diffuseColor = diffuseColor + make_vec3f(value) * value.w;
                }
            }

        const vec3f reflectedVector =
            ray.dir - 2.f * dot(ray.dir, normal) * normal;

        // Specular color
        if (shininess > 0.f)
        {
            const float cosLR = dot(headLight, reflectedVector);
            specularColor = specularColor * powf(cosLR, shininess);
        }

        // Shading
        diffuseColor = cosNL * diffuseColor + specularColor;

        // Compute color contribution
        color = diffuseColor * pathOpacity + color * (1.f - pathOpacity);

        // Prepare for next ray iteration
        if (opacity < 1.f)
        {
            const vec3f refracted =
                refractedVector(ray.dir, normal, oldRefraction, refraction);
            setRay(ray, intersection, refracted);

            pathOpacity *= 1.f - opacity;
            oldRefraction = refraction;
        }
        else if (reflection > 0.f)
        {
            setRay(ray, intersection, reflectedVector);
            pathOpacity *= reflection;
        }
        else
            break;

        ray.t0 = self->abstract.super.epsilon;
        ray.t = inf;
        ray.primID = -1;
        ray.geomID = -1;
        ray.instID = -1;

        ++depth;
    }

    // Alpha
    sample.alpha = pathOpacity;

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
                            void** uniform lights, uniform int32 numLights)
{
    uniform PbrRenderer* uniform self = (uniform PbrRenderer * uniform)_self;

    self->abstract.bgMaterial =
        (uniform ExtendedOBJMaterial * uniform)bgMaterial;

    self->abstract.timestamp = timestamp;

    self->abstract.lights = (const uniform Light* uniform* uniform)lights;
    self->abstract.numLights = numLights;
}
