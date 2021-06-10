using HostCPUFeatures
using Documenter

DocMeta.setdocmeta!(HostCPUFeatures, :DocTestSetup, :(using HostCPUFeatures); recursive=true)

makedocs(;
    modules=[HostCPUFeatures],
    authors="Chris Elrod <elrodc@gmail.com> and contributors",
    repo="https://github.com/JuliaSIMD/HostCPUFeatures.jl/blob/{commit}{path}#{line}",
    sitename="HostCPUFeatures.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaSIMD.github.io/HostCPUFeatures.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaSIMD/HostCPUFeatures.jl",
)
