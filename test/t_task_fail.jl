using Base.Threads
import Base.Threads.@spawn

f() = sqrt(-1)

tasks = []
for i = 1:nthreads()
    t = @spawn f()
    push!(tasks, t)
    println(t)
end

for t in tasks
    wait(t)
end