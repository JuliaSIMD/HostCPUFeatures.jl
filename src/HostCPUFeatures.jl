module HostCPUFeatures
if isdefined(Base, :Experimental) &&
   isdefined(Base.Experimental, Symbol("@max_methods"))
    @eval Base.Experimental.@max_methods 1
end

using Libdl, Static
using Static: Zero, One, lt, gt
using IfElse: ifelse
using Preferences

using BitTwiddlingConvenienceFunctions: prevpow2, nextpow2, intlog2

export has_feature, fma_fast, pick_vector_width, pick_vector_width_shift, register_count,
  register_size, simd_integer_register_size

_cpu_target = if @has_preference("cpu_target")
  @load_preference("cpu_target")
else
  Base.unsafe_string(Base.JLOptions().cpu_target)
end

const build_cpu_target = if occursin("native", _cpu_target)
  "native" # 'native' takes priority if provided
else
  split(_cpu_target, ";")[1]
end

# If true, this will opt-in to "freeze" an under-approximation of the CPU features at precompile-
# time based on the CPU target.
#
# This is only done by default if "native" was excluded from the CPU target (or via a preference).
const freeze_cpu_target =
  @load_preference("freeze_cpu_target", false) || build_cpu_target != "native"

function get_cpu_name()::String
  if isdefined(Sys, :CPU_NAME)
    Sys.CPU_NAME
  else
    ccall(:jl_get_cpu_name, Ref{String}, ())
  end
end
include("cpu_info.jl")
if (Sys.ARCH === :x86_64) || (Sys.ARCH === :i686)
    include("cpu_info_x86.jl")
elseif Sys.ARCH === :aarch64
    include("cpu_info_aarch64.jl")
else
    include("cpu_info_generic.jl")
end
include("pick_vector_width.jl")

unwrap(::Val{S}) where {S} = S
unwrap(::StaticInt{S}) where {S} = S
unwrap(::StaticFloat64{S}) where {S} = S
unwrap(::StaticSymbol{S}) where {S} = S

@noinline function redefine()
  @debug "Defining CPU name."
  redefine_cpu_name()

  reset_features!()
  reset_extra_features!()
end
const BASELINE_CPU_NAME = get_cpu_name()
const allow_eval = @load_preference("allow_runtime_invalidation", false)

function make_generic(target)
  target == "native" && return false
  if Sys.ARCH === :x86_64 || Sys.ARCH === :i686
    make_generic_x86(target)
    return true
  else
    return false
  end
end

make_generic(build_cpu_target)

function __init__()
  ccall(:jl_generating_output, Cint, ()) == 1 && return
  freeze_cpu_target && return # CPU info fixed at precompile-time

  runtime_target = Base.unsafe_string(Base.JLOptions().cpu_target)
  if !occursin("native", runtime_target)
    # The CPU target included "native" at pre-compile time, but at runtime it did not!
    #
    # Fixing this discepancy will invalidate the whole world (so it should probably
    # throw an error), but we do it anyway for backwards-compatibility.
    if make_generic(runtime_target)
      return nothing
    end
  end
  if BASELINE_CPU_NAME != Sys.CPU_NAME::String
    redefine()
  end
  return nothing
end

end
