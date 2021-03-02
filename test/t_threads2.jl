using Base.Threads
import Base.Threads.@spawn
using Random

println("$(Threads.nthreads()) threads")

# https://discourse.julialang.org/t/print-functions-in-a-threaded-loop/12112/8?u=paulmelis
const print_lock = SpinLock()

function f(work_channel, result_channel)
    v = Threads.threadid()
    
    lock(print_lock) do
        Core.println("$(v) | started")
    end
    
    while true
            
        work = take!(work_channel)
        
        lock(print_lock) do
            Core.println("$(v) | got work to do: $(work)")
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
            Core.println("$(v) | producing result $(result)")
        end
        
        put!(result_channel, result)
    end
end

D = 10                  # Data items
W = Threads.nthreads()  # Worker threads

work_channel = Channel{Union{Int,Nothing}}(D)
result_channel = Channel{Tuple{Int,Int}}(D)

# Start worker threads
println("Starting $(W) worker threads")
threads = []
for i = 1:W
    t = @spawn f(work_channel, result_channel)
    push!(threads, t)
end

# Place work in the queue
for i in 1:D
    put!(work_channel, i)
end

# Push sentinels, one per worker thread
for i in 1:W
    put!(work_channel, nothing)
end

# Process results as they come in

r = zeros(Int, D)
for i in 1:D
    tid, index = take!(result_channel)
    lock(print_lock) do
        Core.println("main | got result $(tid), $(index)")
    end
    r[index] = tid
end

# Wait for threads to finish
for t in threads
    println("Waiting on $(t) to finish")
    wait(t)
end

println(r)
