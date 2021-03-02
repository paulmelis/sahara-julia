include("constants.jl")
include("vecmat.jl")
include("ray.jl")
include("primitives.jl")

s = Sphere(1, mat4_identity())
r = Ray(vec3(1,1,1), vec3(-1,-1,-1))
println(r)

ip = IntersectionPoint()
@assert intersection(s, r, ip)
println(ip)

r = Ray(vec3(1,1,1), vec3(0,0,1))
println(r)
@assert !intersection(s, r)

p = Plane(vec3(1,1,2), vec3(0,0,1), mat4_identity())
@assert intersection(p, r, ip)
println(ip)
