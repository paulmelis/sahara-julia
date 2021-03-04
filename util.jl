
function random_sphere_position()
    
    # http://stackoverflow.com/a/7280536
    
    # XXX store d somewhere
    d = Normal(0, 1)
    x = rand(d)
    y = rand(d)
    z = rand(d)
    
    return normalized(vec3(x, y, z))
    
end

"""Returns n*n stratified sample 2D positions
covering the unit square"""
function generate_stratified_samples(n) ::Vector{Tuple{Float32,Float32}}

    res = Tuple{Float32,Float32}[]

    # Size of a cell containing a single sample
    cell_size = 1.0 / n

    for j in 0:n-1
        top = j * cell_size
        for i in 0:n-1
            left = i * cell_size
            x = rand()*cell_size
            y = rand()*cell_size
            @assert x >= 0 && x <= 1
            @assert y >= 0 && y <= 1
            push!(res, (left+x, top+y))
        end
    end

    return res

end

"""Given a normalized vector w, return vectors u and v
such that u, v and w form an orthonormal basis.
See Shirley et.al., 2.4.6"""

# Pick alternative from http://psgraphics.blogspot.com/2014/11/making-orthonormal-basis-from-unit.html?

function create_orthonormal_basis(w) ::Tuple{vec3,vec3}

    @assert (abs(norm(w) - 1.0) < 1.0e-6)
    
    t = MVector(w)

    # Set smallest magnitude component of t to 1
    ci = 1
    cv = abs(t[1])

    if abs(t[2]) < cv
        ci = 2
        cv = abs(t[2])
    end

    if abs(t[3]) < cv
        ci = 3
    end

    t[ci] = 1.0
    
    t2 = vec3(t[1], t[2], t[3])

    # Compute u and v

    u = normalized(t2 ^ w)
    v = u ^ w

    return u, v

end