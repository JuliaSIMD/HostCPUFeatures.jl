
fma_fast() = has_feature(Val(:x86_64_fma)) | has_feature(Val(:x86_64_fma4))
register_size() = ifelse(
    has_feature(Val(:x86_64_avx512f)),
    StaticInt{64}(),
    ifelse(
        has_feature(Val(:x86_64_avx)),
        StaticInt{32}(),
        StaticInt{16}()
    )
)
const simd_integer_register_size = register_size
# simd_integer_register_size() = ifelse(
#     has_feature(Val(:x86_64_avx2)),
#     register_size(),
#     ifelse(
#         has_feature(Val(:x86_64_sse2)),
#         StaticInt{16}(),
#         StaticInt{8}()
#     )
# )
if Sys.ARCH === :i686
    register_count() = StaticInt{8}()
elseif Sys.ARCH === :x86_64
    register_count() = ifelse(has_feature(Val(:x86_64_avx512f)), StaticInt{32}(), StaticInt{16}())
end
has_opmask_registers() = has_feature(Val(:x86_64_avx512f))

reset_extra_features!() = nothing

fast_int64_to_double() = has_feature(Val(:x86_64_avx512dq))

fast_half() = False()

@inline function setfeaturefalse(s)
  if has_feature(Val(s)) === True()
    if allow_eval
      @eval has_feature(::Val{$(QuoteNode(s))}) = False()
    else
      @warn "Runtime invalidation was disabled, but the CPU info is out-of-date.\nWill continue with incorrect CPU feature flag: $s."
    end
  end
end
@inline function setfeaturetrue(s)
  if has_feature(Val(s)) === False()
    if allow_eval
      @eval has_feature(::Val{$(QuoteNode(s))}) = True()
    else
      @warn "Runtime invalidation was disabled, but the CPU info is out-of-date.\nWill continue with incorrect CPU feature flag: $s."
    end
  end
end

# Feature sets use LLVM feature names. The sets are conservative: listing a
# feature a CPU lacks can produce code that fails instruction selection, while
# omitting one only loses performance.
_fset(xs...) = Set{Symbol}(Symbol(archstr() * x) for x ∈ xs)

const X86_BASE = _fset("sse", "sse2", "mmx", "fxsr", "cx8", "cx16", "sahf", "cmov")
const X86_SSE3 = X86_BASE ∪ _fset("sse3")
const X86_SSSE3 = X86_SSE3 ∪ _fset("ssse3")
const X86_SSE42 = X86_SSSE3 ∪ _fset("sse4.1", "sse4.2", "popcnt", "crc32")
const X86_WESTMERE = X86_SSE42 ∪ _fset("aes", "pclmul")
const X86_SILVERMONT = X86_SSE42 ∪ _fset("movbe", "rdrnd", "xsave", "xsaveopt", "prfchw")
const X86_GOLDMONT = X86_SILVERMONT ∪ _fset("rdseed", "sha", "fsgsbase", "xsavec", "xsaves", "clflushopt")
const X86_TREMONT = X86_GOLDMONT ∪ _fset("gfni", "vaes", "vpclmulqdq", "cldemote", "movdiri", "movdir64b", "waitpkg", "clwb")

const X86_AVX_SNB = X86_WESTMERE ∪ _fset("avx", "xsave", "xsaveopt")
const X86_AVX_IVB = X86_AVX_SNB ∪ _fset("f16c", "rdrnd", "fsgsbase")
const X86_AVX2 = X86_AVX_IVB ∪ _fset("avx2", "fma", "bmi", "bmi2", "lzcnt", "movbe", "invpcid")
const X86_AVX2_BDW = X86_AVX2 ∪ _fset("rdseed", "adx", "prfchw")
const X86_AVX2_SKL = X86_AVX2_BDW ∪ _fset("clflushopt", "xsavec", "xsaves")
const X86_AVX2_ADL = X86_AVX2_SKL ∪ _fset("gfni", "vaes", "vpclmulqdq", "serialize", "tsxldtrk", "waitpkg", "cldemote", "movdiri", "movdir64b", "hreset", "ptwrite", "avxvnni", "rdpid")
const X86_AVX2_MTL = setdiff(X86_AVX2_ADL, _fset("avxvnni"))
const X86_AVX2_SRF = X86_AVX2_SKL ∪ _fset("gfni", "vaes", "vpclmulqdq", "sha", "cldemote", "movdiri", "movdir64b", "waitpkg", "serialize", "tsxldtrk", "hreset", "avxifma", "avxvnniint8", "avxneconvert", "cmpccxadd")

const X86_SKX = X86_AVX2_SKL ∪ _fset("pku", "clwb", "avx512f", "avx512cd", "avx512bw", "avx512dq", "avx512vl")
const X86_CNL = X86_SKX ∪ _fset("avx512ifma", "avx512vbmi", "sha")
const X86_ICL = X86_SKX ∪ _fset("avx512ifma", "avx512vbmi", "avx512vbmi2", "avx512vnni", "avx512bitalg", "avx512vpopcntdq", "gfni", "vaes", "vpclmulqdq", "rdpid")
const X86_ICL_SERVER = X86_ICL ∪ _fset("pconfig", "wbnoinvd")
const X86_CAS = X86_SKX ∪ _fset("avx512vnni")
const X86_CPL = X86_SKX ∪ _fset("avx512vnni", "avx512bf16")
const X86_TGL = X86_ICL ∪ _fset("avx512vp2intersect", "movdiri", "movdir64b")
const X86_SPR = X86_ICL ∪ _fset("avx512bf16", "avx512fp16", "amx-bf16", "amx-int8", "amx-tile", "serialize", "tsxldtrk", "waitpkg", "cldemote", "ptwrite", "hreset", "uintr", "avxvnni", "movdiri", "movdir64b")
const X86_KNL = X86_AVX2 ∪ _fset("avx512f", "avx512cd", "avx512er", "avx512pf", "prefetchwt1")

# x86-64 microarchitecture levels (psABI)
const X86_V3 = X86_SSE42 ∪ _fset("avx", "avx2", "fma", "f16c", "bmi", "bmi2", "lzcnt", "movbe", "xsave")
const X86_V4 = X86_V3 ∪ _fset("avx512f", "avx512bw", "avx512dq", "avx512vl")

# AMD
const X86_K10 = X86_SSE42 ∪ _fset("sse4a", "lzcnt")
const X86_BTVER1 = X86_SSSE3 ∪ _fset("sse4a", "lzcnt")
const X86_BTVER2 = X86_SSE42 ∪ _fset("avx", "aes", "pclmul", "f16c", "bmi", "movbe", "sse4a", "xsave", "xsaveopt", "lzcnt", "prfchw")
const X86_BDVER1 = X86_SSE42 ∪ _fset("avx", "aes", "pclmul", "xsave", "xsaveopt", "sse4a", "lzcnt", "xop", "fma4", "lwp")
const X86_BDVER2 = X86_BDVER1 ∪ _fset("fma", "f16c", "bmi", "tbm", "fsgsbase")
const X86_BDVER4 = X86_AVX2 ∪ _fset("sse4a", "fma4", "prfchw", "mwaitx")
const X86_ZNVER = X86_AVX2 ∪ _fset("sse4a", "prfchw", "sha", "adx", "rdseed", "mwaitx", "clflushopt")
const X86_ZNVER2 = X86_ZNVER ∪ _fset("clzero", "rdpru", "wbnoinvd", "xsavec", "xsaves")
const X86_ZNVER3 = X86_ZNVER2 ∪ _fset("vaes", "vpclmulqdq", "pku")
const X86_ZNVER4 = X86_ZNVER3 ∪ _fset("avx512f", "avx512cd", "avx512bw", "avx512dq", "avx512vl", "avx512ifma", "avx512vbmi", "avx512vbmi2", "avx512vnni", "avx512bitalg", "avx512vpopcntdq", "avx512bf16", "gfni", "serialize")
const X86_ZNVER5 = X86_ZNVER4 ∪ _fset("avxvnni", "prefetchi")

const X86_CPU_FEATURES = Dict{String,Set{Symbol}}(
  "generic" => X86_BASE, "x86-64" => X86_BASE, "x86-64-v1" => X86_BASE,
  "x86-64-v2" => X86_SSE42, "x86-64-v3" => X86_V3, "x86-64-v4" => X86_V4,
  "pentium4" => X86_SSE3, "nocona" => X86_SSE3, "prescott" => X86_SSE3,
  "core2" => X86_SSSE3, "penryn" => X86_SSSE3, "bonnell" => X86_SSSE3, "atom" => X86_SSSE3,
  "nehalem" => X86_SSE42, "corei7" => X86_SSE42, "westmere" => X86_WESTMERE,
  "silvermont" => X86_SILVERMONT, "slm" => X86_SILVERMONT, "airmont" => X86_SILVERMONT,
  "goldmont" => X86_GOLDMONT, "goldmont-plus" => X86_GOLDMONT, "tremont" => X86_TREMONT,
  "sandybridge" => X86_AVX_SNB, "corei7-avx" => X86_AVX_SNB,
  "ivybridge" => X86_AVX_IVB, "core-avx-i" => X86_AVX_IVB,
  "haswell" => X86_AVX2, "core-avx2" => X86_AVX2, "broadwell" => X86_AVX2_BDW,
  "skylake" => X86_AVX2_SKL, "kabylake" => X86_AVX2_SKL, "coffeelake" => X86_AVX2_SKL,
  "cometlake" => X86_AVX2_SKL, "whiskeylake" => X86_AVX2_SKL, "amberlake" => X86_AVX2_SKL,
  "alderlake" => X86_AVX2_ADL, "raptorlake" => X86_AVX2_ADL,
  "meteorlake" => X86_AVX2_MTL, "arrowlake" => X86_AVX2_MTL, "arrowlake-s" => X86_AVX2_MTL,
  "lunarlake" => X86_AVX2_MTL, "pantherlake" => X86_AVX2_MTL, "wildcatlake" => X86_AVX2_MTL,
  "sierraforest" => X86_AVX2_SRF, "grandridge" => X86_AVX2_SRF, "clearwaterforest" => X86_AVX2_SRF,
  "skylake-avx512" => X86_SKX, "skx" => X86_SKX,
  "cannonlake" => X86_CNL, "icelake" => X86_ICL, "icelake-client" => X86_ICL,
  "icelake-server" => X86_ICL_SERVER, "cascadelake" => X86_CAS, "cooperlake" => X86_CPL,
  "rocketlake" => X86_ICL, "tigerlake" => X86_TGL,
  "sapphirerapids" => X86_SPR, "emeraldrapids" => X86_SPR, "graniterapids" => X86_SPR,
  "graniterapids-d" => X86_SPR, "diamondrapids" => X86_SPR,
  "knl" => X86_KNL, "knm" => X86_KNL,
  "amdfam10" => X86_K10, "barcelona" => X86_K10, "shanghai" => X86_K10,
  "istanbul" => X86_K10, "magny-cours" => X86_K10,
  "k8" => X86_BASE, "opteron" => X86_BASE, "athlon64" => X86_BASE, "athlon-fx" => X86_BASE,
  "athlon64-sse3" => X86_SSE3, "k8-sse3" => X86_SSE3,
  "btver1" => X86_BTVER1, "btver2" => X86_BTVER2,
  "bdver1" => X86_BDVER1, "bdver2" => X86_BDVER2, "bdver3" => X86_BDVER2, "bdver4" => X86_BDVER4,
  "znver" => X86_ZNVER, "znver2" => X86_ZNVER2, "znver3" => X86_ZNVER3,
  "znver4" => X86_ZNVER4, "znver5" => X86_ZNVER5,
)

function cpu_features(name::AbstractString)
  features = get(X86_CPU_FEATURES, name, nothing)
  if features === nothing
    # Unknown CPU: pick a safe tier. Newer AVX-512 parts tend to carry "-avx512"
    # or "rapids" in their names; otherwise assume at most the AVX2 level.
    features = if occursin("avx512", name)
      X86_SKX
    elseif occursin("znver", name) || occursin("rapids", name) ||
           occursin("lake", name) || occursin("well", name) ||
           occursin("forest", name)
      X86_AVX2
    elseif occursin("bridge", name)
      X86_AVX_SNB
    else
      X86_BASE
    end
  end
  return copy(features)
end

# Feature set of one `;`-separated spec ("cpu,+feat,-feat,clone_all,base(n)").
# Returns `nothing` for specs that contain no CPU name.
function spec_features(spec::AbstractString)
  parts = split(spec, ','; keepempty = false)
  isempty(parts) && return nothing
  cpu = strip(String(first(parts)))
  (cpu == "clone_all" || startswith(cpu, "base(")) && return nothing
  feats = cpu == "native" ? host_features() : cpu_features(cpu)
  for m in Iterators.drop(parts, 1)
    m = strip(String(m))
    if startswith(m, "+")
      push!(feats, Symbol(archstr() * m[2:end]))
    elseif startswith(m, "-")
      delete!(feats, Symbol(archstr() * m[2:end]))
    end
  end
  return feats
end

# Features usable by generated code: present on the host (any code this session
# JIT-compiles still runs on the host) and in every spec of the target, so that
# the same generated IR can be instruction-selected for every clone.
function target_features(target::AbstractString)
  feats = host_features()
  for spec in split(target, ';'; keepempty = false)
    f = spec_features(spec)
    f === nothing && continue
    intersect!(feats, f)
  end
  return feats
end

const X86_ALL_FEATURES = union(
  X86_SKX, X86_CNL, X86_ICL, X86_ICL_SERVER, X86_CAS, X86_CPL, X86_TGL, X86_SPR,
  X86_KNL, X86_V3, X86_ZNVER4, X86_ZNVER5, X86_BDVER4, X86_AVX2_ADL, X86_AVX2_SRF,
  X86_TREMONT, X86_BDVER2, X86_BTVER2, X86_WESTMERE, X86_AVX_IVB, X86_AVX_SNB,
  X86_GOLDMONT, X86_SILVERMONT, X86_SSE42, X86_SSSE3, X86_SSE3, X86_BASE,
)

function apply_features!(S::Set{Symbol}; runtime::Bool = false)
  for f ∈ X86_ALL_FEATURES ∪ S ∪ Set(Symbol.(collect(FEATURE_SET)))
    enable = f ∈ S
    if runtime
      enable ? setfeaturetrue(f) : setfeaturefalse(f)
      if allow_eval
        enable ? push!(FEATURE_SET, string(f)) : delete!(FEATURE_SET, string(f))
      end
    else
      set_feature(string(f), enable)
      enable ? push!(FEATURE_SET, string(f)) : delete!(FEATURE_SET, string(f))
    end
  end
  return nothing
end

function make_generic_x86(target; runtime::Bool = false)
  apply_features!(target_features(target); runtime)
  return nothing
end

