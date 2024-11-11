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

@noinline function setfeaturefalse(s)
    if has_feature(Val(s)) === True()
        @eval has_feature(::Val{$(QuoteNode(s))}) = False()
    end
end
@noinline function setfeaturetrue(s)
    if has_feature(Val(s)) === False()
        @eval has_feature(::Val{$(QuoteNode(s))}) = True()
    end
end

# function make_generic(target)
#     if occursin("tigerlake", target) || occursin("znver4", target) || occursin("sapphirerapids", target)
#         # most feature-complete architectures we use
#         setfeaturetrue(:x86_64_avx512ifma)
#         setfeaturetrue(:x86_64_avx512vl)
#         setfeaturetrue(:x86_64_avx512bw)
#         setfeaturetrue(:x86_64_avx512dq)
#         setfeaturetrue(:x86_64_avx512f)
#         setfeaturetrue(:x86_64_avx2)
#         setfeaturetrue(:x86_64_bmi2)
#         setfeaturetrue(:x86_64_fma)
#         setfeaturetrue(:x86_64_avx)
#     elseif occursin("icelake", target) || occursin("skylake-avx512", target) || occursin("rocketlake", target) || occursin("cascadelake", target)
#         # no ifma, but avx512f and avx512dq
#         setfeaturefalse(:x86_64_avx512ifma)
#         setfeaturetrue(:x86_64_avx512vl)
#         setfeaturetrue(:x86_64_avx512bw)
#         setfeaturetrue(:x86_64_avx512dq)
#         setfeaturetrue(:x86_64_avx512f)
#         setfeaturetrue(:x86_64_avx2)
#         setfeaturetrue(:x86_64_bmi2)
#         setfeaturetrue(:x86_64_fma)
#         setfeaturetrue(:x86_64_avx)
#     elseif occursin("znver", target) || occursin("lake", target) || occursin("well", target)
#         # no avx512, but avx2, fma, and bmi2
#         # znver tries to capture all zen < 4
#         # lake tries to capture lakes we didn't single out above as having avx512
#         #
#         setfeaturefalse(:x86_64_avx512ifma)
#         setfeaturefalse(:x86_64_avx512vl)
#         setfeaturefalse(:x86_64_avx512bw)
#         setfeaturefalse(:x86_64_avx512dq)
#         setfeaturefalse(:x86_64_avx512f)
#         setfeaturetrue(:x86_64_avx2)
#         setfeaturetrue(:x86_64_bmi2)
#         setfeaturetrue(:x86_64_fma)
#         setfeaturetrue(:x86_64_avx)
#     elseif occursin("ivybridge", target) || occursin("sandybridge", target)
#         # has avx, and that is about it we care about
#         setfeaturefalse(:x86_64_avx512ifma)
#         setfeaturefalse(:x86_64_avx512vl)
#         setfeaturefalse(:x86_64_avx512bw)
#         setfeaturefalse(:x86_64_avx512dq)
#         setfeaturefalse(:x86_64_avx512f)
#         setfeaturefalse(:x86_64_avx2)
#         setfeaturefalse(:x86_64_bmi2)
#         setfeaturefalse(:x86_64_fma)
#         setfeaturetrue(:x86_64_avx)
#     else
#         # hopefully we didn't miss something
#         # TODO: sapphire rapids
#         setfeaturefalse(:x86_64_avx512ifma)
#         setfeaturefalse(:x86_64_avx512vl)
#         setfeaturefalse(:x86_64_avx512bw)
#         setfeaturefalse(:x86_64_avx512dq)
#         setfeaturefalse(:x86_64_avx512f)
#         setfeaturefalse(:x86_64_avx2)
#         setfeaturefalse(:x86_64_bmi2)
#         setfeaturefalse(:x86_64_fma)
#         setfeaturefalse(:x86_64_avx)
#     end
#     return nothing
# end
#
