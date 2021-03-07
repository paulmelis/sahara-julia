# https://github.com/timholy/ProgressMeter.jl/issues/189
using ProgressMeter
n = 20
p = Progress(n)
tasks = Vector{Task}(undef, n)
for i in 1:n
    tasks[i] = Threads.@spawn begin
        #sleep(3*rand())
        w = 10*rand()
        count = 0
        t0 = time()        
        while time() - t0 < w
            count += 1
        end
        
        ProgressMeter.next!(p)
        yield()
    end
end
wait.(tasks)