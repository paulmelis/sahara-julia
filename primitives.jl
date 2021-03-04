abstract type Primitive end


# Infinite plane
struct Plane <: Primitive
    point::vec3
    normal::vec3
    object2world::mat4
    world2object::mat4
    
    Plane(p, n, o2w) = new(p, normalized(n), o2w, inv(o2w))
end

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

"""
Sphere centered at the origin, possibly clipped in Z
"""
struct Sphere <: Primitive
    radius::Float32
    zmin::Float32
    zmax::Float32
    object2world::mat4
    world2object::mat4
    
    function Sphere(r, o2w; zmin=nothing, zmax=nothing)
        # XXX assert zmin < zmax
        return new(
            r, 
            zmin === nothing ? -r : zmin,
            zmax === nothing ? r : zmax,
            o2w,
            inv(o2w))
    end
end

function Base.show(io::IO, s::Sphere)
    print(io, "<Sphere r=$(s.radius) z=$(s.zmin),$(s.zmax) o2w=$(s.object2world)>")
end


"""
Check if the given sphere is intersected by the given ray.
See Shirley et.al., section 10.3.1
Returns true if there is an intersection (and set the appropriate
values of ip), or false otherwise.
"""
function 
intersection(sphere::Sphere, ray::Ray) ::Union{IntersectionPoint,Nothing}

    ray_local = transform(ray, sphere.world2object)
    ray_local_origin = ray_local.origin
    ray_local_direction = ray_local.direction

    A = dot(ray_local_direction, ray_local_direction)
    B = 2.0f0 * dot(ray_local_origin, ray_local_direction)
    C = dot(ray_local_origin, ray_local_origin) - sphere.radius^2
    
    D = B*B - 4.0f0*A*C
    if D < 0 
        return nothing 
    end
    
    D = sqrt(D)
    t_hit = (-B - D) / (2*A)

    if t_hit < 0 || t_hit > ray.t_max
        return nothing
    end

    # Check if near intersection point is outside z range, in which case
    # we should check the far intersection point (e.g. open sphere with
    # top cut off, with the ray entering through the top hitting the inside
    # wall).
    
    p_local = ray_local_origin + t_hit * ray_local_direction
    
    inside_hit = false
    if p_local.z < sphere.zmin || p_local.z > sphere.zmax
        t_hit = (-B + D)/(2*A)
        if t_hit < 0 || t_hit > ray.t_max
            return nothing
        end
        # Again, check against z-range
        p_local = ray_local_origin + t_hit * ray_local_direction
        if p_local.z < sphere.zmin || p_local.z > sphere.zmax
            return nothing
        end        
        inside_hit = true
    end

    return IntersectionPoint(
        t_hit,
        ray.origin + t_hit * ray.direction,
        inside_hit ? normalized(ntransform(sphere.object2world, -p_local)) : normalized(ntransform(sphere.object2world, p_local)),
        normalized(-ray.direction))

end
