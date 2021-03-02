struct Ray
    origin::vec3
    direction::vec3
    t_max::Float32    
end

Ray(o) = Ray(o, vec3(0,0,0), INFINITY)
Ray(o, d) = Ray(o, d, INFINITY)
Ray(r::Ray, t_max::Float32) = Ray(r.origin, r.direction, t_max)

function Base.show(io::IO, r::Ray)
    print(io, "<Ray o=$(r.origin) d=$(r.direction) t_max=$(r.t_max)>")
end

function transform(r::Ray, xform::mat4)
    p2 = ptransform(xform, r.origin)
    d2 = vtransform(xform, r.direction)
    return Ray(p2, d2, r.t_max)
end


struct IntersectionPoint
    t::Float32
    p::vec3
    n::vec3
    i::vec3
end

function Base.show(io::IO, i::IntersectionPoint)
    print(io, "<IntersectionPoint t=$(i.t) p=$(i.p) n=$(i.n) i=$(i.i)>")
end
