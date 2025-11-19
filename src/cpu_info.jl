function feature_string()
    llvmlib_path = VERSION ≥ v"1.6.0-DEV.1429" ? Base.libllvm_path() : only(filter(lib->occursin(r"LLVM\b", basename(lib)), Libdl.dllist()))
    libllvm = Libdl.dlopen(llvmlib_path)
    gethostcpufeatures = Libdl.dlsym(libllvm, :LLVMGetHostCPUFeatures)
    features_cstring = ccall(gethostcpufeatures, Cstring, ())
    features = filter(ext -> (ext ≠ "" && (m = match(r"\d", ext); isnothing(m) ? true : m.offset != 2)), split(unsafe_string(features_cstring), ','))
    features, features_cstring
end

const FEATURE_SET = Set{String}()
_has_feature(str::String) = str ∈ FEATURE_SET

archstr() = Sys.ARCH === :i686 ? "x86_64_" : string(Sys.ARCH) * '_'

# feature_name(ext) = archstr() * replace(ext[2:end], r"\." => "_")
feature_name(ext) = archstr() * ext[2:end]
process_feature(ext) = (feature_name(ext), first(ext) == '+')

has_feature(_) = False()
@noinline function set_feature(feature::String, has::Bool)
    featqn = QuoteNode(Symbol(feature))
    if has
        @eval has_feature(::Val{$featqn}) = True()
    else
        @eval has_feature(::Val{$featqn}) = False()
    end
end

function set_features!()
  features, features_cstring = feature_string()
  znver3 = get_cpu_name() === "znver3"
  for ext ∈ features
    feature, has = process_feature(ext)
    if znver3 && occursin("512", feature)
      has = false
    end
    has && push!(FEATURE_SET, feature)
    set_feature(feature, has)
  end
  Libc.free(features_cstring)
end
set_features!()



function reset_features!()
    features, features_cstring = feature_string()
    for ext ∈ features
        feature, has = process_feature(ext)
        if _has_feature(feature) ≠ has
            if allow_eval
                @debug "Defining $(has ? "presence" : "absense") of feature $feature."
                set_feature(feature, has)
            else
                @warn "Runtime invalidation was disabled, but the CPU info is out-of-date.\nWill continue with incorrect CPU feature flag: $ext."
            end
        end
    end
    Libc.free(features_cstring)
end

register_size(::Type{T}) where {T} = register_size()
register_size(::Type{T}) where {T<:Union{Signed,Unsigned}} = simd_integer_register_size()

function redefine_cpu_name()
    cpu = QuoteNode(Symbol(get_cpu_name()))
    if allow_eval
      @eval cpu_name() = Val{$cpu}()
    else
      @warn "Runtime invalidation was disabled, but the CPU info is out-of-date.\nWill continue with incorrect CPU name (from build time)."
    end
end
cpu = QuoteNode(Symbol(get_cpu_name()))
@eval cpu_name() = Val{$cpu}()
