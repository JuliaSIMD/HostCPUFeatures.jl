has_feature(::Val{S}) where {S} = has_feature(S)

@inline @generated function has_feature(my_feature::Symbol)

    features, features_cstring = feature_string()

    matches = map(features) do feature
        fname, has = process_feature(feature)
        val = has ? True() : False()
        sname = Symbol(fname)

        :(
            if my_feature == $(Meta.quot(sname))
                return $val
            end
        )
    end

    push!(matches, :(return False()))

    Libc.free(features_cstring)

    return quote
        begin
            $(matches...)
        end
    end
end
