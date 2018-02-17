%{Cpp:LicenseTemplate}\
#include "Camera.h"
#include "Camera_ispc.h"

namespace ospray
{
%{ProjectName}Camera::%{ProjectName}Camera()
{
    ispcEquivalent = ispc::%{ProjectName}Camera_create(this);
}

std::string %{ProjectName}Camera::toString() const
{
    return "ospray::%{ProjectName}Camera";
}

void %{ProjectName}Camera::commit()
{
    Camera::commit();

    fovy = getParamf("fovy", 60.f);
    aspect = getParamf("aspect", 1.f);
    apertureRadius = getParamf("apertureRadius", 0.f);
    focusDistance = getParamf("focusDistance", 1.f);
    architectural = getParam1i("architectural", false);
    stereoMode = (StereoMode)getParam1i("stereoMode", OSP_STEREO_NONE);
    interpupillaryDistance = getParamf("interpupillaryDistance", 0.0635f);

    dir = normalize(dir);
    vec3f dir_du = normalize(cross(dir, up));
    vec3f dir_dv;
    if (architectural)
        dir_dv = normalize(up);
    else
        dir_dv = cross(dir_du, dir);

    vec3f org = pos;
    const vec3f ipd_offset = 0.5f * interpupillaryDistance * dir_du;

    switch (stereoMode)
    {
    case OSP_STEREO_LEFT:
        org -= ipd_offset;
        break;
    case OSP_STEREO_RIGHT:
        org += ipd_offset;
        break;
    case OSP_STEREO_SIDE_BY_SIDE:
        aspect *= 0.5f;
        break;
    case OSP_STEREO_NONE:
        break;
    }

    float imgPlane_size_y = 2.f * tanf(deg2rad(0.5f * fovy));
    float imgPlane_size_x = imgPlane_size_y * aspect;

    dir_du *= imgPlane_size_x;
    dir_dv *= imgPlane_size_y;

    vec3f dir_00 = dir - .5f * dir_du - .5f * dir_dv;

    float scaledAperture = 0.f;
    if (apertureRadius > 0.f)
    {
        dir_du *= focusDistance;
        dir_dv *= focusDistance;
        dir_00 *= focusDistance;
        scaledAperture = apertureRadius / (imgPlane_size_x * focusDistance);
    }

    dir_du.x = imgPlane_size_x;
    ispc::%{ProjectName}Camera_set(getIE(), (const ispc::vec3f&)org,
                             (const ispc::vec3f&)dir_00,
                             (const ispc::vec3f&)dir_du,
                             (const ispc::vec3f&)dir_dv, scaledAperture, aspect,
                             stereoMode == OSP_STEREO_SIDE_BY_SIDE,
                             (const ispc::vec3f&)ipd_offset);
}

OSP_REGISTER_CAMERA(%{ProjectName}Camera, %{ProjectName}camera);

} // ::ospray
