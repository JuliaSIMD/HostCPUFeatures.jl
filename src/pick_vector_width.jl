@static if isdefined(Base, Symbol("@constprop"))
  using Base: @constprop
else
  macro constprop(_, ex); esc(ex); end
end

@generated function static_sizeof(::Type{T}) where {T}
  st = Base.allocatedinline(T) ? sizeof(T) : sizeof(Int)
  Expr(:block, Expr(:meta, :inline), StaticInt(st))
end

smax(a::StaticInt, b::StaticInt) = ifelse(gt(a, b), a, b)
smin(a::StaticInt, b::StaticInt) = ifelse(lt(a, b), a, b)

_pick_vector_width_float16(::StaticInt{RS}, ::True) where {RS} = StaticInt{RS}() ÷ StaticInt{2}()
_pick_vector_width_float16(::StaticInt{RS}, ::False) where {RS} = StaticInt{RS}() ÷ StaticInt{4}()
pick_vector_width(::Type{Float16}) = _pick_vector_width_float16(register_size(Float32), fast_half())
pick_vector_width(::Type{T}) where {T} = register_size(T) ÷ static_sizeof(T)
@inline @constprop :aggressive function _pick_vector_width(min_W, max_W, ::Type{T}, ::Type{S}, args::Vararg{Any,K}) where {K,S,T}
  _max_W = smin(max_W, pick_vector_width(T))
  _pick_vector_width(min_W, _max_W, S, args...)
end
@inline @constprop :aggressive function _pick_vector_width(min_W, max_W, ::Type{T}) where {T}
  _max_W = smin(max_W, pick_vector_width(T))
  smax(min_W, _max_W)
end
@inline @constprop :aggressive function pick_vector_width(::Type{T}, ::Type{S}, args::Vararg{Any,K}) where {T,S,K}
  _pick_vector_width(One(), register_size(), T, S, args...)
end
@inline @constprop :aggressive function pick_vector_width(::Union{Val{P},StaticInt{P}}, ::Type{T}, ::Type{S}, args::Vararg{Any,K}) where {P,T,S,K}
  _pick_vector_width(One(), smin(register_size(), nextpow2(StaticInt{P}())), T, S, args...)
end
@inline @constprop :aggressive function pick_vector_width(::Union{Val{P},StaticInt{P}}, ::Type{T}) where {P,T}
  _pick_vector_width(One(), smin(register_size(), nextpow2(StaticInt{P}())), T)
end
@inline function pick_vector_width_shift(args::Vararg{Any,K}) where {K}
  W = pick_vector_width(args...)
  W, intlog2(W)
end

