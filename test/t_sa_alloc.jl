import Base.+, Base.-, Base.*
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

+(v::vec3, w::vec3) = vec3(v.x+w.x, v.y+w.y, v.z+w.z)
-(v::vec3, w::vec3) = vec3(v.x-w.x, v.y-w.y, v.z-w.z)
*(v::vec3, f::AbstractFloat) = vec3(v.x*f, v.y*f, v.z*f)
*(f::AbstractFloat, v::vec3) = vec3(v.x*f, v.y*f, v.z*f)

function f()
    Random.seed!(123456)
    v = vec3()
    for i = 1:N
        v += rand() * vec3(rand(), rand(), rand())
    end
    return v
end

@time f()
@time f()