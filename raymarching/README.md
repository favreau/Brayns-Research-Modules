# Ray-Marching Module for Brayns

## Description
This module implements a ray-marching renderer for Brayns

## Usage
- Point LD_LIBRARY_PATH to the folder which contains
  'libospray_module_raymarching.so'
- Run Brayns application either with command line '--module raymarching --renderer distanceestimator' or do
  'ospLoadModule("raymarching")' programmatically
```
OSPRenderer renderer = ospNewRenderer("distanceestimator");
```

## Screenshots
![Raymarching](doc/raymarching.png)
