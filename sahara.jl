#Base.GC.enable(false)

#using InteractiveUtils
using ProgressMeter
#using BenchmarkTools
using Random
using Distributions
using FileIO, PNGFiles
using Images
using Base.Threads
using ThreadPools
using LinearAlgebra
using StaticArrays
import Base.length
import Base.+, Base.-, Base.*
import Base.^

include("constants.jl")
include("vecmat.jl")
include("util.jl")
include("buckets.jl")
include("ray.jl")
include("primitives.jl")
include("camera.jl")
include("lights.jl")
include("worker.jl")

Random.seed!(123456)

# https://discourse.julialang.org/t/print-functions-in-a-threaded-loop/12112/8?u=paulmelis
const print_lock = SpinLock()
const image_lock = SpinLock()

function safe_print(s)
    lock(print_lock) do
        Core.println(s)
    end
end

function main()

    #IMAGE_WIDTH = IMAGE_HEIGHT = 32
    #IMAGE_WIDTH = IMAGE_HEIGHT = 128
    #IMAGE_WIDTH = IMAGE_HEIGHT = 256
    #IMAGE_WIDTH = IMAGE_HEIGHT = 512
    IMAGE_WIDTH = IMAGE_HEIGHT = 1024

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
    
    # crop_window = (left, top, right, bottom), all inclusive
    crop_window = nothing
    #crop_window = (333, 396, 333, 396)

    scene_data = (
        integrator = integrator,
        camera = camera,
        primitives = primitives,
        lights = lights,
        pixel_sample_locations = pixel_sample_locations,
        crop_window = crop_window,
    )

    output_image = zeros(RGB{Float32}, IMAGE_HEIGHT, IMAGE_WIDTH)
    
    println("Starting rendering $(IMAGE_WIDTH)x$(IMAGE_HEIGHT), $(SQRT_NUM_SAMPLES*SQRT_NUM_SAMPLES) spp, $(Threads.nthreads()) threads")
    
    # @qthreads doesn't handle generator?    
    bucket_order = collect(buckets_reading_order(IMAGE_WIDTH, IMAGE_HEIGHT, crop_window))
    
    progress = Progress(length(bucket_order))
    
    #for bucket::Tuple{Int,Int,Int,Int} in ProgressBar(bucket_order)
    @qthreads for bucket::Tuple{Int,Int,Int,Int} in bucket_order
        #println("Processing bucket $(bucket)")
        pixels = process_bucket(scene_data, bucket)
        #println(pixels)
        
        left = bucket[1]+1
        top = bucket[2]+1
        
        lock(image_lock) do
            output_image[top:top+BUCKET_SIZE-1, left:left+BUCKET_SIZE-1] .= pixels            
        end
        
        next!(progress)
        
    end
    
    #@qthreads for bucket in bucket_order
    #
    #    safe_print("Starting bucket $(bucket)")
    #
    #    # Render bucket
    #    pixels = process_bucket(scene_data, bucket)
    #    
    #    safe_print("Got pixels $(pixels)")
    #    
    #    # Paste into image
    #    # XXX lock image
    #    
    #end
    
    println("Saving output file")

    #save(File(format"PNG", "out.png"), output_image)
    save(File(format"TIFF", "out.tif"), output_image)
end

@time main()

#using Profile
#Profile.clear_malloc_data()
#main()
