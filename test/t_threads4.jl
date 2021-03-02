using Base.Threads
import Base.Threads.@spawn
using Random

println("$(Threads.nthreads()) threads")

# https://discourse.julialang.org/t/print-functions-in-a-threaded-loop/12112/8?u=paulmelis
const print_lock = SpinLock()

function f(index, work_channel, result_channel)
    v = Threads.threadid()
    
    lock(print_lock) do
        Core.println("[$(index)] $(v) | started")
    end
    
    if index > 0
        worker(index, work_channel, result_channel)
    else 
        main(work_channel, result_channel)
    end
    
end

# Process results as they come in    
function main(work_channel, result_channel)
    v = Threads.threadid()
    
    for i in 1:D
        tid, index = take!(result_channel)
        lock(print_lock) do
            Core.println("main | got result $(tid), $(index)")
        end
        r[index] = tid
    end
    
end
    
function worker(index, work_channel, result_channel)

    v = Threads.threadid()
    
    while true
            
        work = take!(work_channel)
        
        lock(print_lock) do
            Core.println("[$(index)] $(v) | got work to do: $(work)")
        end
        
        if work === nothing
            # Sentinel, all work done
            return
        end
        
        # Spin
        t0 = time()
        while time() - t0 < v end
        
        # Produce result
        result = (v, work)
        
        lock(print_lock) do
            Core.println("[$(index)] $(v) | producing result $(result)")
        end
        
        put!(result_channel, result)
    end
end

D = 10                  # Data items
W = Threads.nthreads()  # Worker threads

r = zeros(Int, D)
work_channel = Channel{Union{Int,Nothing}}(D+W)
result_channel = Channel{Tuple{Int,Int}}(D)

# Place work in the queue
for i in 1:D
    put!(work_channel, i)
end

# Push sentinels, one per worker thread
for i in 1:W
    put!(work_channel, nothing)
end

# Start worker threads
println("Starting $(W) worker threads")
@threads for i = 0:W
    f(i, work_channel, result_channel)    
end

println("worker threads done")
println(r)
