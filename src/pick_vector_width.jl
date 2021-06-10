intlog2(N::I) where {I <: Integer} = (8sizeof(I) - one(I) - leading_zeros(N)) % I
intlog2(::Type{T}) where {T} = intlog2(sizeof(T))
nextpow2(W::T) where {T<:Base.BitInteger} = (one(T) << (T(8sizeof(W)) - leading_zeros((W - one(T)))))
prevpow2(W::T) where {T<:Base.BitInteger} = (one(T) << (((T(8sizeof(W))) - one(T)) - leading_zeros(W)))
@generated nextpow2(::StaticInt{N}) where {N} = Expr(:call, Expr(:curly, :StaticInt, nextpow2(N)))
@generated prevpow2(::StaticInt{N}) where {N} = Expr(:call, Expr(:curly, :StaticInt, prevpow2(N)))
@generated intlog2(::StaticInt{N}) where {N} = Expr(:call, Expr(:curly, :StaticInt, intlog2(N)))

@static if VERSION ≥ v"1.7.0-DEV.421"
  using Base: @aggressive_constprop
else
  macro aggressive_constprop(ex); esc(ex); end
end

@generated function static_sizeof(::Type{T}) where {T}
    st = Base.allocatedinline(T) ? sizeof(T) : sizeof(Int)
    Expr(:block, Expr(:meta, :inline), StaticInt(st))
end

smax(a::StaticInt, b::StaticInt) = ifelse(gt(a, b), a, b)
smin(a::StaticInt, b::StaticInt) = ifelse(lt(a, b), a, b)

pick_vector_width(::Type{T}) where {T} = register_size(T) ÷ static_sizeof(T)
@inline @aggressive_constprop function _pick_vector_width(min_W, max_W, ::Type{T}, ::Type{S}, args::Vararg{Any,K}) where {K,S,T}
    _max_W = smin(max_W, pick_vector_width(T))
    _pick_vector_width(min_W, _max_W, S, args...)
end
@inline @aggressive_constprop function _pick_vector_width(min_W, max_W, ::Type{T}) where {T}
    _max_W = smin(max_W, pick_vector_width(T))
    smax(min_W, _max_W)
end
@inline @aggressive_constprop function pick_vector_width(::Type{T}, ::Type{S}, args::Vararg{Any,K}) where {T,S,K}
    _pick_vector_width(One(), register_size(), T, S, args...)
end
@inline @aggressive_constprop function pick_vector_width(::Union{Val{P},StaticInt{P}}, ::Type{T}, ::Type{S}, args::Vararg{Any,K}) where {P,T,S,K}
    _pick_vector_width(One(), smin(register_size(), nextpow2(StaticInt{P}())), T, S, args...)
end
@inline @aggressive_constprop function pick_vector_width(::Union{Val{P},StaticInt{P}}, ::Type{T}) where {P,T}
    _pick_vector_width(One(), smin(register_size(), nextpow2(StaticInt{P}())), T)
end
@inline function pick_vector_width_shift(args::Vararg{Any,K}) where {K}
    W = pick_vector_width(args...)
    W, intlog2(W)
end

