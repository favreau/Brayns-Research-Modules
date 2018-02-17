The %{ProjectName} Module for Brayns
==================================

This project implements the %{ProjectName} module for Brayns

Usage
-----

- Point LD_LIBRARY_PATH to the folder which contains
  'libospray_module_%{ProjectName}.so'
- Run Brayns application either with command line '--module %{ProjectName}' or do
  'ospLoadModule("%{ProjectName}")' programmatically
