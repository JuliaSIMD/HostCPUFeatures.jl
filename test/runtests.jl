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

end
