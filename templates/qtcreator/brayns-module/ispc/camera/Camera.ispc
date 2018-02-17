%{Cpp:LicenseTemplate}\
#include "%{ProjectName}Camera.ih"
#include "math/sampling.ih"

void %{ProjectName}Camera_initRay(uniform Camera *uniform _self, varying Ray &ray,
                            const varying CameraSample &sample)
{
    uniform %{ProjectName}Camera *uniform self =
        (uniform %{ProjectName}Camera * uniform)_self;

    vec2f screen = sample.screen;
    vec3f org = self->org;

    if (self->side_by_side)
    {
        screen.x *= 2.f;
        if (screen.x < 1.f)
            org = org - self->ipd_offset;
        else
        {
            org = org + self->ipd_offset;
            screen.x -= 1.f;
        }
    }

    screen = Camera_subRegion(_self, screen);

    vec3f dir =
        self->dir_00 + screen.x * self->dir_du + screen.y * self->dir_dv;

    if (self->super.doesDOF)
    {
        const vec3f llp = uniformSampleDisk(self->scaledAperture, sample.lens);
        // transform local lens point to focal plane (dir_XX are prescaled in
        // this case)
        const vec3f lp =
            (llp.x * self->dir_du) + ((llp.y * self->aspect) * self->dir_dv);
        org = org + lp;
        dir = dir - lp;
    }

    const float time = Camera_shutterTime(_self, sample.time);
    setRay(ray, org, normalize(dir), self->super.nearClip, infinity, time);
}

/*! create a new ispc-side version of a %{ProjectName}camera - with given
    pointer to the c-class version - and return both class pointer and
    pointer to internal data back via the supplied reference
    parameters */
export void *uniform %{ProjectName}Camera_create(void *uniform cppE)
{
    uniform %{ProjectName}Camera *uniform self = uniform new uniform %{ProjectName}Camera;
    self->super.cppEquivalent = cppE;
    self->super.initRay = %{ProjectName}Camera_initRay;
    self->super.doesDOF = false;
    return self;
}

export void %{ProjectName}Camera_set(
    void *uniform _self, const uniform vec3f &org, const uniform vec3f &dir_00,
    const uniform vec3f &dir_du, const uniform vec3f &dir_dv,
    const uniform float scaledAperture, const uniform float aspect,
    const uniform bool side_by_side, const uniform vec3f &ipd_offset)
{
    uniform %{ProjectName}Camera *uniform self =
        (uniform %{ProjectName}Camera * uniform)_self;
    self->org = org;
    self->dir_00 = dir_00;
    self->dir_du = dir_du;
    self->dir_dv = dir_dv;
    self->scaledAperture = scaledAperture;
    self->super.doesDOF = scaledAperture > 0.f;
    self->aspect = aspect;
    self->side_by_side = side_by_side;
    self->ipd_offset = ipd_offset;
}
