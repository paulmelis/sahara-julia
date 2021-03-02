# https://discourse.julialang.org/t/staticarrays-field-values-printed-as-undef/56318/4
using StaticArrays
using LinearAlgebra

struct vec3 <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
    
    vec3() = zeros(Float32, 3)
    vec3(x, y, z) = new(x, y, z)
end

#import Base.length
length(v::vec3) = sqrt(dot(v,v))

v = vec3(0.5f0, 0.0f0, 0.5f0)

println(v)
println(v[1], v.x)
println(length(v))
