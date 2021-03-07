using ImageView, Images
using Gtk.ShortNames    # for signal_connect
using Random

T = Threads.nthreads()

W = 640
H = 480
B = 80
@assert W % B == 0
@assert H % B == 0

const print_lock = ReentrantLock()

function safe_println(s)
    lock(print_lock) do
        Core.println(s)
    end
end

# https://discourse.julialang.org/t/worker-thread-setup-in-julia-compared-to-c-pthreads/56630/2?u=paulmelis
function foreach_on_non_primary(f, work_channel::Channel)
    workers = Threads.Atomic{Int}(0)
    @sync for _ in 1:Threads.nthreads()
        Threads.@spawn if Threads.threadid() > 1
            Threads.atomic_add!(workers, 1)
            for work in work_channel
                f(work)
            end
        end
    end
    if workers[] == 0
        @assert false
        # Failed to start workers. Fallback to more robust (less controlled)
        # solution:
        @sync for _ in 1:Threads.nthreads()
            Threads.@spawn for work in work_channel            
                f(work)
            end
        end
    end
end

img = rand(RGB{N0f8}, H, W)

# Show empty image
guidict = imshow(img)

work_channel = Channel{Tuple{Int,Int,Int}}(Inf)
result_channel = Channel{Array{RGB{N0f8},2}}(Inf)

for top in 1:B:H
    for left in 1:B:W
        push!(work_channel, (top, left, B))
    end
end

close(work_channel)  # instead of sentinel, you can just close it (otherwise deadlock)

function compute(work)
    safe_println("[$(Threads.threadid())] computing $(work)")
    w = rand(Float32) * 3
    count = 0
    t0 = time()    
    while time() - t0 < w
        count += 1
    end    
    pixels = rand(RGB{N0f8}, 32, 32)
    safe_println("[$(Threads.threadid())] done computing $(work)")
    return pixels    
end

safe_println("Starting work")
foreach_on_non_primary(work_channel) do work
    pixels = compute(work)
    push!(result_channel, pixels)
end


safe_println("Waiting for window closure")
c = Condition()
win = guidict["gui"]["window"]
signal_connect(win, :destroy) do widget
    notify(c)
end

wait(c)
