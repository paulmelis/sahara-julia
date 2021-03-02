include("vecmat.jl")
include("camera.jl")

framebuffer = Framebuffer(1024, 1024)

camera = PerspectiveCamera(framebuffer,
    vec3(0.5, -3, 0.5),
    vec3(0.5, 0, 0.5),
    vec3(0, 0, 1),
    35.0)

println(camera)