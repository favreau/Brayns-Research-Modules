# Simulation Module for Brayns

## Description
This module implements simulation renderers for Brayns

## Usage
- Point LD_LIBRARY_PATH to the folder which contains
  'libospray_module_simulation.so'
- Run Brayns application either with command line '--module simulation --renderer transparency' or do
  'ospLoadModule("simulation")' programmatically
```
OSPRenderer renderer = ospNewRenderer("transparency");
```

## Screenshots
![Transparency](doc/transparency.png)
