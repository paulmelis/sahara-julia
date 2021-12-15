using InteractiveUtils
using ProgressMeter
using BenchmarkTools
using Random
using Distributions
using FileIO, PNGFiles
using Images
using LinearAlgebra
using StaticArrays
#using Sobol
import Base.length
import Base.+, Base.-, Base.*
import Base.^
import Base.Threads.@spawn

include("constants.jl")
include("vecmat.jl")
include("util.jl")
include("buckets.jl")
include("ray.jl")
include("primitives.jl")
include("camera.jl")
include("lights.jl")
include("worker.jl")

const image_lock = ReentrantLock()

# https://discourse.julialang.org/t/print-functions-in-a-threaded-loop/12112/8
#const print_lock = ReentrantLock()
#
#function safe_println(s)
#    lock(print_lock) do
#        Core.println(s)
#    end
#end

function render(seed)

    Random.seed!(seed)

    #IMAGE_WIDTH = IMAGE_HEIGHT = 32
    #IMAGE_WIDTH = IMAGE_HEIGHT = 128
    #IMAGE_WIDTH = IMAGE_HEIGHT = 256
    IMAGE_WIDTH = IMAGE_HEIGHT = 512
    #IMAGE_WIDTH = IMAGE_HEIGHT = 1024
    #IMAGE_WIDTH = 1920
    #IMAGE_HEIGHT = 1056

    #SQRT_NUM_SAMPLES = 1
    #SQRT_NUM_SAMPLES = 2
    #SQRT_NUM_SAMPLES = 4
    #SQRT_NUM_SAMPLES = 8
    SQRT_NUM_SAMPLES = 16
    #SQRT_NUM_SAMPLES = 32

    #integrator = "direct"
    integrator = "path"

    framebuffer = Framebuffer(IMAGE_WIDTH, IMAGE_HEIGHT)
    
    camera = PerspectiveCamera(framebuffer,
        vec3(0.5, -3, 0.5),
        vec3(0.5, 0, 0.5),
        vec3(0, 0, 1),
        35.0)
        
    println(camera)

    primitives = [
        Sphere(0.1,
            mat4_translate(0.05,0,0.5)*mat4_rot_z(30)*mat4_rot_x(-90),
            zmin=-0.05, zmax=0.05),
        Sphere(0.1,
            mat4_translate(0.2,0,0.2)),
        Sphere(0.3,
            mat4_translate(0.5,0,0.5)*mat4_rot_z(40)*mat4_rot_y(-30),
            zmin=-0.2, zmax=0.2),
        Sphere(0.1, # Move back
            mat4_translate(0.6,0,0.7)*mat4_rot_x(50),
            zmin=-0.035, zmax=0.035),
        Sphere(0.1,
            mat4_translate(0.7,-1,0.1)*mat4_rot_z(-15)*mat4_rot_x(-60),
            zmin=-0.08, zmax=0.08),

        Plane(vec3(0,0,0), vec3(0,0,1), mat4_identity())
    ]
    
    lights = [
        PointLight(vec3(1, -1, 5), 0.3),
        HemisphericalLight(100.0, 0.7)
    ]
    
    # XXX use sobol sequence instead, for (most likely) lower variance with same number of samples
    pixel_sample_locations = generate_stratified_samples(SQRT_NUM_SAMPLES)
    #s = SobolSeq(2)
    #pixel_sample_locations = [Tuple{Float32,Float32}(Sobol.next!(s)) for i = 1:(SQRT_NUM_SAMPLES*SQRT_NUM_SAMPLES)]
    
    # crop_window = (left, top, right, bottom), all inclusive
    crop_window = nothing
    #crop_window = (333, 396, 333, 396)
    
    bucket_order = collect(buckets_reading_order(IMAGE_WIDTH, IMAGE_HEIGHT, crop_window))    

    scene_data = (
        integrator = integrator,
        camera = camera,
        primitives = primitives,
        lights = lights,
        pixel_sample_locations = pixel_sample_locations,
        crop_window = crop_window
    )

    output_image = zeros(RGB{Float32}, IMAGE_HEIGHT, IMAGE_WIDTH)
    overall_ray_stats = RayStats()
    
    println("Starting rendering $(IMAGE_WIDTH)x$(IMAGE_HEIGHT), $(SQRT_NUM_SAMPLES*SQRT_NUM_SAMPLES) spp, $(Threads.nthreads()) threads")
    
    progress = Progress(length(bucket_order))
    tasks = Task[]
    
    #for bucket::Tuple{Int,Int,Int,Int} in ProgressBar(bucket_order)
    for bucket in bucket_order
    
        t = @spawn begin
            #println("Processing bucket $(bucket)")
            pixels, ray_stats = process_bucket(scene_data, bucket)
            #println(pixels)
                        
            lock(image_lock) do
                #safe_println("Bucket $(bucket) done")
                left = bucket[1]+1
                top = bucket[2]+1                
                output_image[top:top+BUCKET_SIZE-1, left:left+BUCKET_SIZE-1] .= pixels            
                add!(overall_ray_stats, ray_stats)                
            end
            
            ProgressMeter.next!(progress)
            yield()
        end
        push!(tasks, t)
        
    end
    
    wait.(tasks)
    
    println(overall_ray_stats)
    
    return output_image
end

#ray = Ray(vec3(), vec3(1,1,1))
#sphere = Sphere(0.1,
#            mat4_translate(0.05,0,0.5)*mat4_rot_z(30)*mat4_rot_x(-90),
#            zmin=-0.05, zmax=0.05)
#@code_warntype intersection(sphere, ray)
#doh!()

using Profile

#output_image = render(123456)
#output_image = @time render(123456)
output_image = @btime render(123456)

println("Saving output file")

#save(File(format"PNG", "out.png"), output_image)
save(File(format"TIFF", "out.tif"), output_image)

#Profile.clear_malloc_data()

#@profile render(123456)
#save("main.jlprof",  Profile.retrieve()...)


