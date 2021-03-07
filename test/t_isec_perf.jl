import Base.+, Base.-, Base.*
import Base.^

using InteractiveUtils
using StaticArrays
using BenchmarkTools
using LinearAlgebra

include("constants.jl")
include("vecmat.jl")
include("ray.jl")
include("primitives.jl")

function 
intersection(plane::Plane, ray::Ray) ::Union{IntersectionPoint,Nothing}

    ray_local = transform(ray, plane.world2object)
    ray_local_origin = ray_local.origin
    ray_local_direction = ray_local.direction

    denom = dot(ray_local_direction, plane.normal)
    
    if abs(denom) < 1f-6
        # Plane and ray perpendicular
        return nothing
    end

    t_hit = dot(plane.point-ray_local_origin, plane.normal) / denom

    if t_hit < 0 || t_hit > ray_local.t_max
        return nothing
    end

    return IntersectionPoint(
        t_hit,
        ray.origin + t_hit * ray.direction,
        normalized(ntransform(plane.object2world, plane.normal)),
        normalized(-ray.direction))
end

mutable struct IntersectionPoint2
    t::Float32
    p::vec3
    n::vec3
    i::vec3
end


function 
intersection2(ip::IntersectionPoint2, plane::Plane, ray::Ray)

    ray_local = transform(ray, plane.world2object)
    ray_local_origin = ray_local.origin
    ray_local_direction = ray_local.direction

    denom = dot(ray_local_direction, plane.normal)
    
    if abs(denom) < 1f-6
        # Plane and ray perpendicular
        ip.t = 0.0f0
        return
    end

    t_hit = dot(plane.point-ray_local_origin, plane.normal) / denom

    if t_hit < 0 || t_hit > ray_local.t_max
        ip.t = 0.0f0
        return
    end
    
    ip.t = t_hit
    ip.p = ray.origin + t_hit * ray.direction
    ip.n = normalized(ntransform(plane.object2world, plane.normal))
    ip.i = normalized(-ray.direction)
    
    return
end

function 
intersection3(plane::Plane, ray::Ray, ip::Union{IntersectionPoint2,Nothing}) ::Bool

    ray_local = transform(ray, plane.world2object)
    ray_local_origin = ray_local.origin
    ray_local_direction = ray_local.direction

    denom = dot(ray_local_direction, plane.normal)
    
    if abs(denom) < 1f-6
        # Plane and ray perpendicular
        return false
    end

    t_hit = dot(plane.point-ray_local_origin, plane.normal) / denom

    if t_hit < 0 || t_hit > ray_local.t_max
        return false    
    end
    
    if ip !== nothing
        ip.t = t_hit
        ip.p = ray.origin + t_hit * ray.direction
        ip.n = normalized(ntransform(plane.object2world, plane.normal))
        ip.i = normalized(-ray.direction)
    end
    
    return true
end


# 52.828 ns (0 allocations: 0 bytes)
function f(plane, ray)
    count = 0
    ip = intersection(plane, ray) 
    if ip !== nothing
        if ip.t > 0.5f0 
            count += 1
        end
    end
    return count
end

# 111.614 ns (1 allocation: 16 bytes)
#@allocated intersection2(ip, plane, ray)

function g(ip, plane, ray)
    count = 0
    intersection2(ip, plane, ray)
    if ip.t > 0.5f0
        count += 1
    end
    return count
end

function h(ip, plane, ray)
    count = 0
    if intersection3(plane, ray, ip) 
        if ip.t > 0.5f0
            count += 1
        end
    end
    return count
end

plane = Plane(vec3(0,0,0), vec3(1,1,1), mat4_identity())
ray = Ray(vec3(), vec3(2,2,2))
ip = IntersectionPoint2(0.0f0, vec3(), vec3(), vec3())

@btime f($plane, $ray)
@btime g($ip, $plane, $ray)
@btime h($ip, $plane, $ray)

@code_warntype f(plane, ray)
#@btime f()