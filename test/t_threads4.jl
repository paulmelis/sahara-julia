using Base.Threads
import Base.Threads.@spawn

println("nthreads() = $(Threads.nthreads())")

# https://discourse.julialang.org/t/print-functions-in-a-threaded-loop/12112/8
const print_lock = ReentrantLock()

function safe_println(s)
    lock(print_lock) do
        Core.println(s)
    end
end

function worker(index, work_channel, result_channel)

    tid = Threads.threadid()
    safe_println("[$(tid)] worker $(index) | started")
    
    while true

        work = take!(work_channel)       
        safe_println("[$(tid)] worker $(index) | got work to do: $(work)")
        
        if work === nothing
            # Sentinel, all work done
            safe_println("[$(tid)] worker $(index) | done")
            return
        end
        
        # Spin, simulate work of at least index seconds
        t0 = time()
        dummy = 0
        while (time() - t0) < index 
            dummy += 1
        end
        
        # Produce result
        result = (index, tid, work)
        safe_println("[$(tid)] worker $(index) | producing result $(result)")
        put!(result_channel, result)
    end
end

D = 10                  # Data items
W = Threads.nthreads()  # Worker threads

work_channel = Channel{Union{Int,Nothing}}(D+W)
result_channel = Channel{Tuple{Int,Int,Int}}(D)

# Place work in the queue
safe_println("Scheduling $(D) work items")
for i = 1:D
    put!(work_channel, i)
end

# Push sentinels, one per worker thread
for i = 1:W
    put!(work_channel, nothing)
end

# Start worker threads
tasks = []
safe_println("[main] Starting $(W) tasks")
for i = 1:W
    t = @spawn worker(i, work_channel, result_channel)    
    safe_println("[main] worker $(i): $(t)")
    push!(tasks, t)
end

# Wait for all work to complete
safe_println("[main] Waiting for work completion")    

r = zeros(Int, D)
for i = 1:D
    wid, tid, work = take!(result_channel)
    r[work] = tid
    safe_println("[main] Got $(work) from worker $(wid) (thread $(tid))")
end

safe_println("[main] Received all work items")    
safe_println("[main] $(r)")

safe_println("[main] Waiting for task completion")
for t in tasks 
    wait(t)
end
