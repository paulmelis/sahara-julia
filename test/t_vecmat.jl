include("constants.jl")
include("vecmat.jl")

M = mat4_translate(1, 2, 3)
println(M)

v = vec3(4.0f0, 5.0f0, 6.0f0)
println(v)

println("p ", ptransform(M,v))
println("v ", vtransform(M,v))
println("n ", ntransform(M,v))

R = mat4_rot_x(90)
println(ntransform(R,v))

println(v)
println(dot(v, v))
println(length(v))

n = normalized(v)
println(n)
println(dot(n,n))
println(length(n))

T = mat4_rot_x(90)*mat4_rot_z(-30)*mat4_translate(0.05,0,0.5)
println(T)

U = mat4_rotate(45, 1, 2, 3)

u = vec3(1, 2, 3)
v = vec3(4, 5, 6)
w = vec3(7, 8, 9)
d = u*0.3 + v*0.5 + w*0.2
println(d)