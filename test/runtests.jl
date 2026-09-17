using HostCPUFeatures
using Test

@testset "HostCPUFeatures.jl" begin

  println("vector_width.jl")
  @time @testset "vector_width.jl" begin
    for T ∈ (Float32,Float64)
      @test @inferred(HostCPUFeatures.pick_vector_width(T)) * @inferred(HostCPUFeatures.static_sizeof(T)) === @inferred(HostCPUFeatures.register_size(T)) === @inferred(HostCPUFeatures.register_size())
    end
    for T ∈ (Int8,Int16,Int32,Int64,UInt8,UInt16,UInt32,UInt64)
      @test @inferred(HostCPUFeatures.pick_vector_width(T)) * @inferred(HostCPUFeatures.static_sizeof(T)) === @inferred(HostCPUFeatures.register_size(T)) === @inferred(HostCPUFeatures.simd_integer_register_size())
    end
    @test HostCPUFeatures.static_sizeof(BigFloat) === HostCPUFeatures.static_sizeof(Int)
    @test HostCPUFeatures.static_sizeof(Float32) === HostCPUFeatures.static_sizeof(Int32) === HostCPUFeatures.StaticInt(4)

    @test @inferred(HostCPUFeatures.pick_vector_width(Float64, Int32, Float64, Float32, Float64)) * HostCPUFeatures.static_sizeof(Float64) === @inferred(HostCPUFeatures.register_size())
    @test @inferred(HostCPUFeatures.pick_vector_width(Float64, Int32)) * HostCPUFeatures.static_sizeof(Float64) === @inferred(HostCPUFeatures.register_size())

    @test @inferred(HostCPUFeatures.pick_vector_width(Float32, Float32)) * HostCPUFeatures.static_sizeof(Float32) === @inferred(HostCPUFeatures.register_size())
    @test @inferred(HostCPUFeatures.pick_vector_width(Float32, Int32)) * HostCPUFeatures.static_sizeof(Float32) === @inferred(HostCPUFeatures.simd_integer_register_size())

    FTypes = (Float32, Float64)
    Wv = ntuple(i -> @inferred(HostCPUFeatures.register_size()) >> (i+1), Val(2))
    for (T, N) in zip(FTypes, Wv)
      W = @inferred(HostCPUFeatures.pick_vector_width(T))
      # @test Vec{Int(W),T} == HostCPUFeatures.pick_vector(W, T) == HostCPUFeatures.pick_vector(T)
      @test W == @inferred(HostCPUFeatures.pick_vector_width(W, T))
      @test W === @inferred(HostCPUFeatures.pick_vector_width(W, T)) == @inferred(HostCPUFeatures.pick_vector_width(T))
      while true
        W >>= HostCPUFeatures.One()
        W == 0 && break
        W2, Wshift2 = @inferred(HostCPUFeatures.pick_vector_width_shift(W, T))
        @test W2 == HostCPUFeatures.One() << Wshift2 == @inferred(HostCPUFeatures.pick_vector_width(W, T)) == HostCPUFeatures.pick_vector_width(Val(Int(W)),T)  == W
        @test HostCPUFeatures.StaticInt(W) === HostCPUFeatures.pick_vector_width(Val(Int(W)), T) === HostCPUFeatures.pick_vector_width(W, T)
        for n in W+1:2W
          W3, Wshift3 = HostCPUFeatures.pick_vector_width_shift(HostCPUFeatures.StaticInt(n), T)
          @test W2 << 1 == W3 == 1 << (Wshift2+1) == 1 << Wshift3 == HostCPUFeatures.pick_vector_width(HostCPUFeatures.StaticInt(n), T) == HostCPUFeatures.pick_vector_width(Val(n),T) == W << 1
          # @test HostCPUFeatures.pick_vector(W, T) == HostCPUFeatures.pick_vector(W, T) == Vec{Int(W),T}
        end
      end
    end
    @test HostCPUFeatures.pick_vector_width(Float16) === HostCPUFeatures.pick_vector_width(Float32)
    # @test HostCPUFeatures.nextpow2(0) == 1

    @test HostCPUFeatures.unwrap(HostCPUFeatures.static(2)) === 2
    @test HostCPUFeatures.unwrap(HostCPUFeatures.static(1.2)) === 1.2
    @test HostCPUFeatures.unwrap(HostCPUFeatures.static(:a)) === :a
  end

  if Sys.ARCH === :x86_64
    @time @testset "cpu_target feature sets" begin
      @test HostCPUFeatures.spec_features("clone_all") === nothing
      @test :x86_64_avx512f ∈ HostCPUFeatures.spec_features("skylake-avx512")
      @test :x86_64_avx512vl ∈ HostCPUFeatures.spec_features("skylake-avx512")
      @test :x86_64_avx512ifma ∉ HostCPUFeatures.spec_features("skylake-avx512")
      @test :x86_64_avx512ifma ∈ HostCPUFeatures.spec_features("sapphirerapids")
      @test :x86_64_avx512bw ∉ HostCPUFeatures.spec_features("knl")
      @test :x86_64_avx512f ∈ HostCPUFeatures.spec_features("znver4")
      @test :x86_64_avx512f ∉ HostCPUFeatures.spec_features("znver2")
      @test :x86_64_avx512f ∈ HostCPUFeatures.spec_features("x86-64-v4")
      @test :x86_64_avx512f ∉ HostCPUFeatures.spec_features("x86-64-v3")
      @test :x86_64_avx ∉ HostCPUFeatures.spec_features("generic")
      @test :x86_64_avx ∈ HostCPUFeatures.spec_features("sandybridge")
      @test :x86_64_avx2 ∉ HostCPUFeatures.spec_features("sandybridge")
      # per-spec feature modifiers
      @test :x86_64_rdrnd ∉ HostCPUFeatures.spec_features("haswell,-rdrnd")
      @test :x86_64_rdrnd ∈ HostCPUFeatures.spec_features("haswell")
      @test :x86_64_avx512f ∈ HostCPUFeatures.spec_features("haswell,+avx512f")
    end

    @time @testset "cpu_target intersection" begin
      tf = HostCPUFeatures.target_features
      # a feature missing from any clone spec can never be reported
      @test :x86_64_avx512f ∉ tf("skylake-avx512;generic")
      @test :x86_64_avx512f ∉ tf("generic;skylake-avx512")
      @test :x86_64_avx ∉ tf("generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)")
      # `native` in a spec means the host
      @test tf("native") == HostCPUFeatures.host_features()
      @test tf("native;generic") == tf("generic")
      # generated code must also run in the current session
      @test tf("sapphirerapids") ⊆ HostCPUFeatures.host_features()
    end

    @time @testset "non-native cpu_target image build" begin
      # "skylake-avx512;generic" puts an AVX-512 spec first: reporting host or
      # first-spec features would emit AVX-512 IR that the `generic` clone
      # cannot instruction-select (`LLVM ERROR: Cannot select: X86ISD::RCP14`,
      # JuliaSIMD/VectorizationBase.jl#131).
      prefsfile = joinpath(dirname(Base.active_project()), "LocalPreferences.toml")
      backup = isfile(prefsfile) ? read(prefsfile) : nothing
      write(prefsfile, "[HostCPUFeatures]\nallow_runtime_invalidation = true\n")
      try
        mktempdir() do dir
          script = joinpath(dir, "build.jl")
          obj = joinpath(dir, "img.o")
          write(script, """
          Base.reinit_stdio()
          @eval Sys BINDIR = ccall(:jl_get_julia_bindir, Any, ())::String
          @eval Sys STDLIB = $(repr(Sys.STDLIB))
          copy!(LOAD_PATH, [$(repr(Base.active_project())), "@stdlib"])
          Base.init_depot_path()
          using HostCPUFeatures, Static
          const VT = NTuple{8,Core.VecElement{Float64}}
          # The pattern VectorizationBase uses: emit the AVX-512 intrinsic iff
          # has_feature reports it. If it leaked into this build, instruction
          # selection aborts the image build / the call below.
          if has_feature(Val(:x86_64_avx512f)) === True()
            const RCP14 = ("declare <8 x double> @llvm.x86.avx512.rcp14.pd.512(<8 x double>, <8 x double>, i8) nounwind readnone\\ndefine <8 x double> @entry(<8 x double> %0) alwaysinline {\\n  %res = call <8 x double> @llvm.x86.avx512.rcp14.pd.512(<8 x double> %0, <8 x double> zeroinitializer, i8 -1)\\n  ret <8 x double> %res\\n}\\n", "entry")
            @eval rcp(v::VT) = \$(Expr(:call, GlobalRef(Base, :llvmcall), RCP14, VT, Tuple{VT}, :v))
          else
            @eval rcp(v::VT) = v
          end
          rcp(ntuple(_ -> Core.VecElement(1.5), Val(8)))
          @assert has_feature(Val(:x86_64_avx512f)) === False()
          println("image build OK")
          """)
          exe = Base.julia_cmd().exec[1]
          img = unsafe_string(Base.JLOptions().image_file)
          cmd = `$exe --startup-file=no --sysimage=$img --output-o=$obj -C skylake-avx512\;generic $script`
          @test success(pipeline(cmd; stdout = devnull))
          @test isfile(obj)
        end
      finally
        backup === nothing ? rm(prefsfile; force = true) : write(prefsfile, backup)
      end
    end
  end

end
