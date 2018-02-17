%{Cpp:LicenseTemplate}\
#include <iostream>

namespace ospray
{
extern "C" void ospray_init_module_%{ProjectName}()
{
    std::cout << "[MODULE] initializing %{ProjectName} plugin" << std::endl;
}
}
