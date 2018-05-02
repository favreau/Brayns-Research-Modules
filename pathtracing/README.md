# Path Tracing Module for Brayns

## Description
This module implements path tracing renderers for Brayns

## Usage
- Point LD_LIBRARY_PATH to the folder which contains
  'libospray_module_pathtracing.so'
- Run Brayns application either with command line '--module pathtracing --renderer pathtracing' or do
  'ospLoadModule("pathtracing")' programmatically
```
OSPRenderer renderer = ospNewRenderer("pathtracing");
```

## Screenshots
![PathTracing](doc/pathtracing.png)

