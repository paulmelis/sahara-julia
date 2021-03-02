using Random

function f()
   v = Threads.threadid()
   println(v)
   sleep(v)
   return v
end

N = 20

a = zeros(N)

# Iteration range gets divided equally over available threads
# in advanced :-/ (i.e. no dynamic scheduling)
Threads.@threads for i = 1:N
   a[i] = f()
end

println(a)
