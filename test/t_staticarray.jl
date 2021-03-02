using LinearAlgebra
using StaticArrays

struct Framebuffer
    width::Int
    height::Int
    aspect::Float32
    
    Framebuffer(w, h) = new(w, h, w/h)    
end


struct vec3 <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
    
    vec3() = zeros(Float32, 3)
    vec3(x, y, z) = new(x, y, z)
end

mutable struct C
    framebuffer::Framebuffer
    
    position::vec3
    lookat::vec3
    forward::vec3
    right::vec3
    up::vec3
    
    vfov::Float32

    function C(framebuffer, position, lookat, up, vfov)
        obj = new(framebuffer)
        obj.position = position
        obj.lookat = lookat
        obj.up = up
        obj.vfov = vfov
        return obj
    end
end

println(vec3(0.5, -3, 0.5))

framebuffer = Framebuffer(512, 512)

c = C(framebuffer,
    vec3(0.5, -3, 0.5),
    vec3(0.5, 0, 0.5),
    vec3(0, 0, 1),
    35.0)

println(c)