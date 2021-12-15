using Random
using InteractiveUtils
using BenchmarkTools

function max_over_indices(a, indices)
    maxval = 0.0
    for idx in indices
        maxval = max(maxval, a[idx])
    end
    return maxval
end

function max_over_indices_noboundscheck(a, indices)
    maxval = 0.0
    for idx in indices
        @inbounds maxval = max(maxval, a[idx])
    end
    return maxval
end

function new_sum(myvec::Vector{Int})
    s = 0
    for i = 1:length(myvec)
        s += myvec[i]
    end
    return s
end

function new_sum_inbounds(myvec::Vector{Int})
    s = 0
    @inbounds for i = 1:length(myvec)
        s += myvec[i]
    end
    return s
end

vec = collect(1:1_000_000)

@btime new_sum(vec)
@btime new_sum_inbounds(vec)


N = 1_000_000
values = rand(Float64, N)
indices = rand(1:(2*N), N)

#@code_warntype max_over_indices(values, indices)
#@code_warntype max_over_indices_noboundscheck(values, indices)

#code_warntype(max_over_indices, (Vector{Float64}, Vector{Int64}))
#code_warntype(max_over_indices_noboundscheck, (Vector{Float64}, Vector{Int64}))

#@btime max_over_indices_noboundscheck(values, indices)
#@btime max_over_indices(values, indices)




