using Random
using StaticArrays

const N = 1000000

struct vec3 <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
    
    vec3() = new(0f0, 0f0, 0f0)
    vec3(x, y, z) = new(x, y, z)
end

mutable struct IntersectionPoint
    t::Float32
    p::vec3
    n::vec3
    i::vec3
    
    IntersectionPoint() = new(1.0f0, vec3(), vec3(), vec3())
end

println(isbits(IntersectionPoint))

function isec(ip::IntersectionPoint) ::Bool
    return ip.t < 0.5f0
end

function g()
    ip = IntersectionPoint()
    ip.t = rand()
    return isec(ip)
end

function f()
    Random.seed!(123456)
    v = 0
    for i = 1:N
        v += g()
    end
    return v
end

@time println(f())
@time println(f())