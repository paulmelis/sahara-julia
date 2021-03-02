include("constants.jl")
include("buckets.jl")

for b in buckets_reading_order(256, 256)
    println(b)
end