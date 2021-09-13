module HostCPUFeatures

using Libdl, Static
using Static: Zero, One, lt, gt
using IfElse: ifelse

using BitTwiddlingConvenienceFunctions: prevpow2, nextpow2, intlog2

export has_feature, fma_fast, pick_vector_width, pick_vector_width_shift, register_count,
  register_size, simd_integer_register_size


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
  define_cpu_name()

  reset_features!()
  reset_extra_features!()
end
const BASELINE_CPU_NAME = (Sys.CPU_NAME)::String
function __init__()
  ccall(:jl_generating_output, Cint, ()) == 1 && return
  BASELINE_CPU_NAME == Sys.CPU_NAME::String || redefine()
  return nothing
end

end
