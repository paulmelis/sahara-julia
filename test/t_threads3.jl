using Base.Threads
using ThreadPools
using Random

println("$(Threads.nthreads()) threads")

# https://discourse.julialang.org/t/print-functions-in-a-threaded-loop/12112/8?u=paulmelis
const print_lock = SpinLock()

function f(i)
    tid = Threads.threadid()
    
    lock(print_lock) do
        Core.println("$(tid) | started")
    end
    
    # Spin
    t0 = time()
    while time() - t0 < tid end
    
    # Produce result
    return tid
end

D = 10                  # Data items

a = zeros(Int, D)

@qbthreads for i in 1:D
    tid = f(i)
    a[i] = tid
end

println(a)
