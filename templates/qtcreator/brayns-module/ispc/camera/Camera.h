%{Cpp:LicenseTemplate}\
#pragma once

#include <ospray/SDK/camera/Camera.h>

namespace ospray
{
struct %{ProjectName}Camera : public Camera
{
    %{ProjectName}Camera();
    virtual ~%{ProjectName}Camera() override = default;
    virtual std::string toString() const override;
    virtual void commit() override;

    float fovy;
    float aspect;
    float apertureRadius;
    float focusDistance;
    bool architectural;
    typedef enum {
        OSP_STEREO_NONE,
        OSP_STEREO_LEFT,
        OSP_STEREO_RIGHT,
        OSP_STEREO_SIDE_BY_SIDE
    } StereoMode;
    StereoMode stereoMode;
    float interpupillaryDistance;
};

} // ::ospray
