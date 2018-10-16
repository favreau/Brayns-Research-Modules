# Sub-surface Scattering Module for Brayns

## Description
This module implements sub-surface scattering renderers for Brayns

## Usage
- Point LD_LIBRARY_PATH to the folder which contains
  'libospray_module_sss.so'
- Run Brayns application either with command line '--module sss --renderer sss' or do
  'ospLoadModule("sss")' programmatically
```
OSPRenderer renderer = ospNewRenderer("sss");
```

## Screenshots
![SSS](doc/sss.png)
