```@meta
CurrentModule = HostCPUFeatures
```

# HostCPUFeatures

Documentation for [HostCPUFeatures](https://github.com/JuliaSIMD/HostCPUFeatures.jl).

```@index
```

```@autodocs
Modules = [HostCPUFeatures]
```

## Supported Preferences

  - `cpu_target`: if provided, use this string as your CPU target for feature detection instead of `JULIA_CPU_TARGET`
  - `freeze_cpu_target`: if `true`, "freeze" the features detected based on your precompile-time CPU target and do not perform runtime feature detection
  - `allow_runtime_invalidation`: if `false`, warn when performing runtime feature detection (instead of invalidating) when CPU features don't match precompile-time
