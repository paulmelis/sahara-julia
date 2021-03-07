import Base.Threads.@spawn
using BenchmarkTools

function work(t)
    t0 = time()
    count = 0
    while time()-t0 < t
        count += 1
    end
    return count
end

function parallel_work(N, t)
    @sync for i = 1:N
      @spawn work(t)
    end
end

@btime parallel_work(20, 1)

"""
N = 20
t = 1

-t1
  20.000 s (135 allocations: 9.73 KiB)

-t2 
  10.000 s (155 allocations: 10.36 KiB)

-t4
  5.000 s (155 allocations: 10.36 KiB)

"""